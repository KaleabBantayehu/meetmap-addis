import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/repositories/place_repository.dart';
import '../core/repositories/repository_error_mapper.dart';
import '../shared/models/place_model.dart';
import '../core/storage/local_storage_service.dart';
import '../core/storage/connectivity_service.dart';
import '../core/services/gebeta_directions_service.dart'
    show GebetaDirectionsService, DirectionsResult;

class PlacesProvider with ChangeNotifier {
  final PlaceRepository _placeRepository;

  PlacesProvider({required PlaceRepository placeRepository})
    : _placeRepository = placeRepository {
    _loadSearchHistory();
    _loadCachedPlaces();
  }

  final _directionsService = GebetaDirectionsService();
  final _directionsCache = <String, DirectionsResult>{};

  List<PlaceModel> _places = [];
  List<PlaceModel> get places => _places;

  List<PlaceModel> _searchResults = [];
  List<PlaceModel> get searchResults => _searchResults;

  List<PlaceModel> _nearbyPlaces = [];
  List<PlaceModel> get nearbyPlaces => _nearbyPlaces;

  List<String> _recentSearches = [];
  List<String> get recentSearches => _recentSearches;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAdding = false;
  bool get isAdding => _isAdding;

  bool _isLoadingNearby = false;
  bool get isLoadingNearby => _isLoadingNearby;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _loadSearchHistory() {
    try {
      _recentSearches = LocalStorageService.instance.getSearchHistory();
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

    _recentSearches.removeWhere(
      (item) => item.toLowerCase() == trimmed.toLowerCase(),
    );
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }

    try {
      await LocalStorageService.instance.saveSearchHistory(_recentSearches);
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
    notifyListeners();
  }

  Future<void> removeRecentSearch(String query) async {
    _recentSearches.removeWhere(
      (item) => item.toLowerCase() == query.toLowerCase().trim(),
    );
    try {
      await LocalStorageService.instance.saveSearchHistory(_recentSearches);
    } catch (e) {
      debugPrint('Error removing search history item: $e');
    }
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    _recentSearches.clear();
    try {
      await LocalStorageService.instance.saveSearchHistory(_recentSearches);
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
    notifyListeners();
  }

  Future<void> fetchPlaces() async {
    if (_places.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = null;

    try {
      if (ConnectivityService.instance.isConnected) {
        final newPlaces = await _placeRepository.fetchPlaces();
        _places = newPlaces;
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
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchPlaces(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Always normalise so 'CAFE' and 'cafe' produce identical results.
    final normalized = query.trim().toLowerCase();

    // Client-side predicate used both as primary (offline) and merge (online).
    bool matchesLocal(PlaceModel place) {
      return place.name.toLowerCase().contains(normalized) ||
          place.category.toLowerCase().contains(normalized) ||
          place.location.toLowerCase().contains(normalized) ||
          place.tags.any((t) => t.toLowerCase().contains(normalized));
    }

    try {
      if (ConnectivityService.instance.isConnected) {
        // Pass the normalised query to the repository.
        final remoteResults =
            await _placeRepository.searchPlaces(normalized);
        // Merge: remote results first, then any locally-matching places
        // that Firestore might have missed due to case differences.
        final remoteIds = remoteResults.map((p) => p.id).toSet();
        final localExtras = _places
            .where((p) => matchesLocal(p) && !remoteIds.contains(p.id))
            .toList();
        _searchResults = [...remoteResults, ...localExtras];
      } else {
        _searchResults = _places.where(matchesLocal).toList();
      }
    } catch (e) {
      _errorMessage = cleanExceptionMessage(e, 'Failed to search places');
      debugPrint('Error searching places: $e');
      // Always fall back to a local, case-insensitive pass.
      _searchResults = _places.where(matchesLocal).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPlace(PlaceModel place) async {
    if (_isAdding) {
      _errorMessage = 'Place submission is already in progress.';
      notifyListeners();
      return false;
    }

    if (!ConnectivityService.instance.isConnected) {
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
        final refreshedPlaces = await _placeRepository.fetchPlaces();
        _places = refreshedPlaces;
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
    _isLoadingNearby = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_places.isEmpty) {
        await fetchPlaces();
      }

      _nearbyPlaces = _places.where((place) {
        final distance = _calculateDistance(
          userLat,
          userLng,
          place.latitude,
          place.longitude,
        );
        return distance <= radiusKm;
      }).toList();

      _nearbyPlaces.sort((a, b) {
        final distA = _calculateDistance(
          userLat,
          userLng,
          a.latitude,
          a.longitude,
        );
        final distB = _calculateDistance(
          userLat,
          userLng,
          b.latitude,
          b.longitude,
        );
        return distA.compareTo(distB);
      });

      debugPrint(
        'Found ${_nearbyPlaces.length} places within ${radiusKm}km',
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = cleanExceptionMessage(e, 'Failed to load nearby places');
      debugPrint('Error fetching nearby places: $e');
    } finally {
      _isLoadingNearby = false;
      notifyListeners();
    }
  }

  List<PlaceModel> getNearbyPlacesByCategory({
    required double userLat,
    required double userLng,
    required String category,
    double radiusKm = 5.0,
  }) {
    return _places.where((place) {
      final distance = _calculateDistance(
        userLat,
        userLng,
        place.latitude,
        place.longitude,
      );
      return distance <= radiusKm &&
          place.category.toLowerCase() == category.toLowerCase();
    }).toList()
      ..sort((a, b) {
        final distA = _calculateDistance(userLat, userLng, a.latitude, a.longitude);
        final distB = _calculateDistance(userLat, userLng, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });
  }

  double getDistanceToPlace({
    required double userLat,
    required double userLng,
    required PlaceModel place,
  }) {
    return _calculateDistance(userLat, userLng, place.latitude, place.longitude);
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRad(double degree) {
    return degree * math.pi / 180;
  }

  Future<DirectionsResult?> getDirectionsToPlace({
    required double userLat,
    required double userLng,
    required PlaceModel place,
  }) async {
    final cacheKey = '${place.id}_$userLat' '_$userLng';
    if (_directionsCache.containsKey(cacheKey)) {
      return _directionsCache[cacheKey];
    }

    final result = await _directionsService.getDirections(
      originLat: userLat,
      originLng: userLng,
      destLat: place.latitude,
      destLng: place.longitude,
    );

    if (result != null) {
      _directionsCache[cacheKey] = result;
    }

    return result;
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
            final distA =
                _calculateDistance(userLat, userLng, a.latitude, a.longitude);
            final distB =
                _calculateDistance(userLat, userLng, b.latitude, b.longitude);
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
