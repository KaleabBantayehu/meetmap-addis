import 'package:flutter/material.dart';
import '../core/repositories/place_repository.dart';
import '../core/repositories/repository_error_mapper.dart';
import '../shared/models/place_model.dart';
import '../core/storage/local_storage_service.dart';
import '../core/storage/connectivity_service.dart';

class PlacesProvider with ChangeNotifier {
  final PlaceRepository _placeRepository;

  PlacesProvider({required PlaceRepository placeRepository})
    : _placeRepository = placeRepository {
    _loadSearchHistory();
    _loadCachedPlaces();
  }

  List<PlaceModel> _places = [];
  List<PlaceModel> get places => _places;

  List<PlaceModel> _searchResults = [];
  List<PlaceModel> get searchResults => _searchResults;

  List<String> _recentSearches = [];
  List<String> get recentSearches => _recentSearches;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAdding = false;
  bool get isAdding => _isAdding;

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

    try {
      if (ConnectivityService.instance.isConnected) {
        _searchResults = await _placeRepository.searchPlaces(query);
      } else {
        // Fallback to local fuzzy search
        final normalized = query.trim().toLowerCase();
        _searchResults = _places.where((place) {
          return place.name.toLowerCase().contains(normalized) ||
              place.category.toLowerCase().contains(normalized) ||
              place.location.toLowerCase().contains(normalized) ||
              place.tags.any((t) => t.toLowerCase().contains(normalized));
        }).toList();
      }
    } catch (e) {
      _errorMessage = cleanExceptionMessage(e, 'Failed to search places');
      debugPrint('Error searching places: $e');
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
    if (place.priceRange.trim().isEmpty) {
      return 'Please select a price range.';
    }
    if (place.imageUrl.trim().isEmpty && place.imageUrls.isEmpty) {
      return 'Please upload at least one image.';
    }
    return null;
  }
}
