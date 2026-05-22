import 'package:flutter/material.dart';
import '../core/repositories/place_repository.dart';
import '../shared/models/place_model.dart';
import '../core/storage/local_storage_service.dart';
import '../core/storage/cache_keys.dart';
import '../core/storage/connectivity_service.dart';

class SavedProvider with ChangeNotifier {
  final PlaceRepository _placeRepository;

  SavedProvider({required PlaceRepository placeRepository})
      : _placeRepository = placeRepository {
    _loadFromCache();
  }

  List<PlaceModel> _savedPlaces = [];
  List<PlaceModel> get savedPlaces => _savedPlaces;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _loadFromCache() {
    try {
      _savedPlaces = LocalStorageService.instance.getSavedPlaces();
      debugPrint('Preloaded ${_savedPlaces.length} saved places from cache on startup.');
    } catch (e) {
      debugPrint('Error preloading saved places: $e');
    }
  }

  void _saveToCache() {
    try {
      LocalStorageService.instance.saveSavedPlaces(_savedPlaces);
      LocalStorageService.instance.saveSavedPlaceIds(_savedPlaces.map((p) => p.id).toList());
      LocalStorageService.instance.setString(
        CacheKeys.savedPlacesLastSync,
        DateTime.now().toIso8601String(),
      );
      debugPrint('Saved ${_savedPlaces.length} places to cache.');
    } catch (e) {
      debugPrint('Error saving places to cache: $e');
    }
  }

  Future<void> fetchSavedPlaces() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (ConnectivityService.instance.isConnected) {
        final places = await _placeRepository.fetchSavedPlaces();
        _savedPlaces = places;
        _saveToCache();
      } else {
        debugPrint('Device is offline. Loading saved places from cache.');
        _loadFromCache();
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching saved places from repository: $e');
      // If error occurs, keep cached data
      if (_savedPlaces.isEmpty) {
        _loadFromCache();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isSaved(String placeId) {
    return _savedPlaces.any((p) => p.id == placeId);
  }

  void toggleSaved(PlaceModel place) {
    final index = _savedPlaces.indexWhere((p) => p.id == place.id);
    if (index >= 0) {
      _savedPlaces.removeAt(index);
    } else {
      _savedPlaces.add(place);
    }
    _saveToCache();
    notifyListeners();
  }

  void removeSaved(String placeId) {
    _savedPlaces.removeWhere((p) => p.id == placeId);
    _saveToCache();
    notifyListeners();
  }
}
