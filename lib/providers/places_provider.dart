import 'package:flutter/material.dart';
import '../core/repositories/place_repository.dart';
import '../core/repositories/repository_error_mapper.dart';
import '../shared/models/place_model.dart';
import '../core/storage/local_storage_service.dart';
import '../core/storage/connectivity_service.dart';
import '../core/services/gebeta_directions_service.dart'
    show GebetaDirectionsService, DirectionsResult;
import '../core/search/place_search_index.dart';
import '../core/location/geo_bounds.dart';

class PlacesProvider with ChangeNotifier {
  final PlaceRepository _placeRepository;
  final bool Function() _isConnected;

  PlacesProvider({
    required PlaceRepository placeRepository,
    bool Function()? isConnected,
  }) : _placeRepository = placeRepository,
       _isConnected =
           isConnected ?? (() => ConnectivityService.instance.isConnected) {
    _loadSearchHistory(null);
    _loadCachedPlaces();
  }

  final _directionsService = GebetaDirectionsService();
  final _directionsCache = <String, DirectionsResult>{};

  List<PlaceModel> _places = [];
  List<PlaceModel> get places => _places;

  List<PlaceModel> _searchResults = [];
  List<PlaceModel> get searchResults => _searchResults;
  bool _isSearching = false;
  bool get isSearching => _isSearching;
  bool _isLoadingMoreSearchResults = false;
  bool get isLoadingMoreSearchResults => _isLoadingMoreSearchResults;
  bool _hasMoreSearchResults = false;
  bool get hasMoreSearchResults => _hasMoreSearchResults;
  String? _searchCursor;
  String _normalizedSearchQuery = '';
  int _searchRequestGeneration = 0;

  List<PlaceModel> _nearbyPlaces = [];
  List<PlaceModel> get nearbyPlaces => _nearbyPlaces;
  List<PlaceModel> _mapPlaces = [];
  List<PlaceModel> get mapPlaces => _mapPlaces;
  bool _hasLoadedMapBounds = false;
  bool get hasLoadedMapBounds => _hasLoadedMapBounds;
  int _nearbyRequestGeneration = 0;
  int _mapRequestGeneration = 0;

  List<String> _recentSearches = [];
  List<String> get recentSearches => _recentSearches;
  String? _sessionUserId;
  int _sessionGeneration = 0;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  String? _nextCursor;
  int _placesRequestGeneration = 0;

  bool _isAdding = false;
  bool get isAdding => _isAdding;

  bool _isLoadingNearby = false;
  bool get isLoadingNearby => _isLoadingNearby;
  bool _hasLoadedNearby = false;
  bool get hasLoadedNearby => _hasLoadedNearby;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void syncSession(String? userId) {
    if (_sessionUserId == userId) return;
    _sessionGeneration++;
    _sessionUserId = userId;
    _nearbyRequestGeneration++;
    _mapRequestGeneration++;
    _nearbyPlaces = [];
    _mapPlaces = [];
    _hasLoadedMapBounds = false;
    _hasLoadedNearby = false;
    _searchRequestGeneration++;
    _searchResults = [];
    _normalizedSearchQuery = '';
    _searchCursor = null;
    _hasMoreSearchResults = false;
    _isSearching = false;
    _isLoadingMoreSearchResults = false;
    _recentSearches = [];
    _loadSearchHistory(userId);
    notifyListeners();
  }

  void _loadSearchHistory(String? userId) {
    try {
      _recentSearches = LocalStorageService.instance.getSearchHistory(userId);
      debugPrint(
        'Loaded ${_recentSearches.length} recent searches from cache.',
      );
    } catch (e) {
      debugPrint('Error loading search history from cache: $e');
    }
  }

  void _loadCachedPlaces() {
    try {
      _places = LocalStorageService.instance.getCachedPlaces();
      debugPrint('Loaded ${_places.length} places from cache on startup.');
      if (_places.isNotEmpty) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error preloading places from cache: $e');
    }
  }

  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final userId = _sessionUserId;
    final generation = _sessionGeneration;

    _recentSearches.removeWhere(
      (item) => item.toLowerCase() == trimmed.toLowerCase(),
    );
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    final history = List<String>.from(_recentSearches);

    try {
      await LocalStorageService.instance.saveSearchHistory(userId, history);
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
    if (_isCurrentSession(userId, generation)) notifyListeners();
  }

  Future<void> removeRecentSearch(String query) async {
    final userId = _sessionUserId;
    final generation = _sessionGeneration;
    _recentSearches.removeWhere(
      (item) => item.toLowerCase() == query.toLowerCase().trim(),
    );
    final history = List<String>.from(_recentSearches);
    try {
      await LocalStorageService.instance.saveSearchHistory(userId, history);
    } catch (e) {
      debugPrint('Error removing search history item: $e');
    }
    if (_isCurrentSession(userId, generation)) notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    final userId = _sessionUserId;
    final generation = _sessionGeneration;
    _recentSearches.clear();
    try {
      await LocalStorageService.instance.saveSearchHistory(userId, const []);
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
    if (_isCurrentSession(userId, generation)) notifyListeners();
  }

  bool _isCurrentSession(String? userId, int generation) =>
      _sessionUserId == userId && _sessionGeneration == generation;

  Future<void> fetchPlaces() async {
    final requestGeneration = ++_placesRequestGeneration;
    if (_places.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = null;

    try {
      if (_isConnected()) {
        final page = await _placeRepository.fetchPlacesPage();
        if (requestGeneration != _placesRequestGeneration) return;
        _places = page.items;
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        await LocalStorageService.instance.saveCachedPlaces(_places);
        debugPrint(
          'Successfully synced ${_places.length} places from Firestore.',
        );
      } else {
        if (_places.isEmpty) {
          _loadCachedPlaces();
        }
      }
    } catch (e) {
      _errorMessage = cleanExceptionMessage(e, 'Failed to load places');
      debugPrint('Error fetching places: $e');
      if (_places.isEmpty) {
        _loadCachedPlaces();
      }
    } finally {
      if (requestGeneration == _placesRequestGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMorePlaces() async {
    if (_isLoadingMore || !_hasMore || !_isConnected()) {
      return;
    }
    final requestGeneration = _placesRequestGeneration;
    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final page = await _placeRepository.fetchPlacesPage(cursor: _nextCursor);
      if (requestGeneration != _placesRequestGeneration) {
        return;
      }
      final knownIds = _places.map((place) => place.id).toSet();
      _places.addAll(page.items.where((place) => knownIds.add(place.id)));
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;
      await LocalStorageService.instance.saveCachedPlaces(_places);
    } catch (e) {
      if (requestGeneration == _placesRequestGeneration) {
        _errorMessage = cleanExceptionMessage(e, 'Failed to load more places');
      }
    } finally {
      if (requestGeneration == _placesRequestGeneration) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> searchPlaces(String query) async {
    final normalized = normalizePlaceSearchQuery(query);
    final requestGeneration = ++_searchRequestGeneration;
    final sessionGeneration = _sessionGeneration;
    final sessionUserId = _sessionUserId;

    _normalizedSearchQuery = normalized;
    _searchCursor = null;
    _hasMoreSearchResults = false;
    _isLoadingMoreSearchResults = false;
    _errorMessage = null;

    if (normalized.length < placeSearchMinimumLength) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      if (_isConnected()) {
        final page = await _placeRepository.searchPlacesPage(normalized);
        if (!_isCurrentSearch(
          normalized,
          requestGeneration,
          sessionUserId,
          sessionGeneration,
        )) {
          return;
        }
        _searchResults = page.items;
        _searchCursor = page.nextCursor;
        _hasMoreSearchResults = page.hasMore;
      } else {
        _searchResults = _localSearch(normalized);
      }
    } catch (e) {
      if (_isCurrentSearch(
        normalized,
        requestGeneration,
        sessionUserId,
        sessionGeneration,
      )) {
        _errorMessage = cleanExceptionMessage(e, 'Failed to search places');
        debugPrint('Error searching places: $e');
        _searchResults = _localSearch(normalized);
      }
    } finally {
      if (_isCurrentSearch(
        normalized,
        requestGeneration,
        sessionUserId,
        sessionGeneration,
      )) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreSearchResults() async {
    if (_isLoadingMoreSearchResults ||
        !_hasMoreSearchResults ||
        !_isConnected()) {
      return;
    }
    final normalized = _normalizedSearchQuery;
    final requestGeneration = _searchRequestGeneration;
    final sessionGeneration = _sessionGeneration;
    final sessionUserId = _sessionUserId;
    _isLoadingMoreSearchResults = true;
    notifyListeners();

    try {
      final page = await _placeRepository.searchPlacesPage(
        normalized,
        cursor: _searchCursor,
      );
      if (!_isCurrentSearch(
        normalized,
        requestGeneration,
        sessionUserId,
        sessionGeneration,
      )) {
        return;
      }
      final knownIds = _searchResults.map((place) => place.id).toSet();
      _searchResults.addAll(
        page.items.where((place) => knownIds.add(place.id)),
      );
      _searchCursor = page.nextCursor;
      _hasMoreSearchResults = page.hasMore;
    } catch (e) {
      if (_isCurrentSearch(
        normalized,
        requestGeneration,
        sessionUserId,
        sessionGeneration,
      )) {
        _errorMessage = cleanExceptionMessage(
          e,
          'Failed to load more search results',
        );
      }
    } finally {
      if (_isCurrentSearch(
        normalized,
        requestGeneration,
        sessionUserId,
        sessionGeneration,
      )) {
        _isLoadingMoreSearchResults = false;
        notifyListeners();
      }
    }
  }

  List<PlaceModel> _localSearch(String normalized) {
    return _places.where((place) {
      return buildPlaceSearchPrefixes([
        place.name,
        place.category,
        place.location,
        ...place.tags,
      ]).contains(normalized);
    }).toList();
  }

  bool _isCurrentSearch(
    String normalized,
    int requestGeneration,
    String? sessionUserId,
    int sessionGeneration,
  ) =>
      normalized == _normalizedSearchQuery &&
      requestGeneration == _searchRequestGeneration &&
      _isCurrentSession(sessionUserId, sessionGeneration);

  Future<bool> addPlace(PlaceModel place) async {
    if (_isAdding) {
      _errorMessage = 'Place submission is already in progress.';
      notifyListeners();
      return false;
    }

    if (!_isConnected()) {
      _errorMessage = 'Internet connection required to publish a place.';
      notifyListeners();
      return false;
    }

    final validationMessage = _validatePlace(place);
    if (validationMessage != null) {
      _errorMessage = validationMessage;
      notifyListeners();
      return false;
    }

    _isAdding = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdPlace = await _placeRepository.createPlace(place);
      _places = [
        createdPlace,
        ..._places.where((existing) => existing.id != createdPlace.id),
      ];
      await LocalStorageService.instance.saveCachedPlaces(_places);

      try {
        final page = await _placeRepository.fetchPlacesPage();
        _places = page.items;
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        await LocalStorageService.instance.saveCachedPlaces(_places);
      } catch (refreshError) {
        debugPrint('Place created, but refresh failed: $refreshError');
      }

      return true;
    } catch (e) {
      _errorMessage = cleanExceptionMessage(e, 'Failed to create place');
      debugPrint('Error adding place: $e');
      return false;
    } finally {
      _isAdding = false;
      notifyListeners();
    }
  }

  String? _validatePlace(PlaceModel place) {
    if (place.name.trim().length < 3) {
      return 'Place name must be at least 3 characters.';
    }
    if (place.description.trim().length < 20) {
      return 'Description must be at least 20 characters.';
    }
    if (place.category.trim().isEmpty) {
      return 'Please select a category.';
    }
    if (place.normalizedPriceLevel < 1 || place.normalizedPriceLevel > 4) {
      return 'Please select a price range.';
    }
    if (place.imageUrl.trim().isEmpty && place.imageUrls.isEmpty) {
      return 'Please upload at least one image.';
    }
    return null;
  }

  Future<void> fetchNearbyPlaces({
    required double userLat,
    required double userLng,
    double radiusKm = 5.0,
  }) async {
    final requestGeneration = ++_nearbyRequestGeneration;
    final sessionGeneration = _sessionGeneration;
    final sessionUserId = _sessionUserId;
    _isLoadingNearby = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _placeRepository.fetchNearbyPlaces(
        latitude: userLat,
        longitude: userLng,
        radiusKm: radiusKm,
      );
      if (!_isCurrentGeographicRequest(
        requestGeneration,
        _nearbyRequestGeneration,
        sessionUserId,
        sessionGeneration,
      )) {
        return;
      }
      _nearbyPlaces = page.items;
      _hasLoadedNearby = true;

      debugPrint('Found ${_nearbyPlaces.length} places within ${radiusKm}km');
      notifyListeners();
    } catch (e) {
      if (_isCurrentGeographicRequest(
        requestGeneration,
        _nearbyRequestGeneration,
        sessionUserId,
        sessionGeneration,
      )) {
        _errorMessage = cleanExceptionMessage(
          e,
          'Failed to load nearby places',
        );
        debugPrint('Error fetching nearby places: $e');
      }
    } finally {
      if (_isCurrentGeographicRequest(
        requestGeneration,
        _nearbyRequestGeneration,
        sessionUserId,
        sessionGeneration,
      )) {
        _isLoadingNearby = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchPlacesInBounds(GeoBounds bounds) async {
    if (!bounds.isValid || !_isConnected()) return;
    final requestGeneration = ++_mapRequestGeneration;
    final sessionGeneration = _sessionGeneration;
    final sessionUserId = _sessionUserId;
    try {
      final page = await _placeRepository.fetchPlacesInBounds(bounds);
      if (!_isCurrentGeographicRequest(
        requestGeneration,
        _mapRequestGeneration,
        sessionUserId,
        sessionGeneration,
      )) {
        return;
      }
      _mapPlaces = page.items;
      _hasLoadedMapBounds = true;
      notifyListeners();
    } catch (e) {
      if (_isCurrentGeographicRequest(
        requestGeneration,
        _mapRequestGeneration,
        sessionUserId,
        sessionGeneration,
      )) {
        debugPrint('Error loading places for map bounds: $e');
      }
    }
  }

  bool _isCurrentGeographicRequest(
    int requestGeneration,
    int currentRequestGeneration,
    String? sessionUserId,
    int sessionGeneration,
  ) =>
      requestGeneration == currentRequestGeneration &&
      _isCurrentSession(sessionUserId, sessionGeneration);

  List<PlaceModel> getNearbyPlacesByCategory({
    required double userLat,
    required double userLng,
    required String category,
    double radiusKm = 5.0,
  }) {
    return _nearbyPlaces.where((place) {
      final distance = distanceKm(
        fromLatitude: userLat,
        fromLongitude: userLng,
        toLatitude: place.latitude,
        toLongitude: place.longitude,
      );
      return distance <= radiusKm &&
          place.category.toLowerCase() == category.toLowerCase();
    }).toList()..sort((a, b) {
      final distA = distanceKm(
        fromLatitude: userLat,
        fromLongitude: userLng,
        toLatitude: a.latitude,
        toLongitude: a.longitude,
      );
      final distB = distanceKm(
        fromLatitude: userLat,
        fromLongitude: userLng,
        toLatitude: b.latitude,
        toLongitude: b.longitude,
      );
      return distA.compareTo(distB);
    });
  }

  double getDistanceToPlace({
    required double userLat,
    required double userLng,
    required PlaceModel place,
  }) {
    return distanceKm(
      fromLatitude: userLat,
      fromLongitude: userLng,
      toLatitude: place.latitude,
      toLongitude: place.longitude,
    );
  }

  Future<DirectionsResult?> getDirectionsToCoords({
    required double userLat,
    required double userLng,
    required double destLat,
    required double destLng,
    required String id,
  }) async {
    final cacheKey = '${id}_${userLat}_$userLng';
    if (_directionsCache.containsKey(cacheKey)) {
      return _directionsCache[cacheKey];
    }

    final result = await _directionsService.getDirections(
      originLat: userLat,
      originLng: userLng,
      destLat: destLat,
      destLng: destLng,
    );

    _directionsCache[cacheKey] = result;

    return result;
  }

  Future<DirectionsResult?> getDirectionsToPlace({
    required double userLat,
    required double userLng,
    required PlaceModel place,
  }) async {
    return getDirectionsToCoords(
      userLat: userLat,
      userLng: userLng,
      destLat: place.latitude,
      destLng: place.longitude,
      id: place.id,
    );
  }

  void clearDirectionsCache() {
    _directionsCache.clear();
  }

  List<PlaceModel> sortPlaces(
    List<PlaceModel> placesToSort,
    SortOption sortBy, {
    double? userLat,
    double? userLng,
  }) {
    final sorted = List<PlaceModel>.from(placesToSort);

    switch (sortBy) {
      case SortOption.nearest:
        if (userLat != null && userLng != null) {
          sorted.sort((a, b) {
            final distA = distanceKm(
              fromLatitude: userLat,
              fromLongitude: userLng,
              toLatitude: a.latitude,
              toLongitude: a.longitude,
            );
            final distB = distanceKm(
              fromLatitude: userLat,
              fromLongitude: userLng,
              toLatitude: b.latitude,
              toLongitude: b.longitude,
            );
            return distA.compareTo(distB);
          });
        }
      case SortOption.highestRated:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case SortOption.mostReviewed:
        sorted.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      case SortOption.newest:
        sorted.sort((a, b) {
          final timeA = a.createdAt?.millisecondsSinceEpoch ?? 0;
          final timeB = b.createdAt?.millisecondsSinceEpoch ?? 0;
          return timeB.compareTo(timeA);
        });
    }

    return sorted;
  }
}

enum SortOption { nearest, highestRated, mostReviewed, newest }
