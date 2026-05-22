import 'package:flutter/material.dart';
import '../core/repositories/saved_repository.dart';
import '../shared/models/place_model.dart';
import '../core/storage/local_storage_service.dart';
import '../core/storage/cache_keys.dart';
import '../core/storage/connectivity_service.dart';
import 'auth_provider.dart';

class SavedProvider with ChangeNotifier {
  final SavedRepository _savedRepository;
  final AuthProvider _authProvider;

  SavedProvider({
    required SavedRepository savedRepository,
    required AuthProvider authProvider,
  })  : _savedRepository = savedRepository,
        _authProvider = authProvider {
    _loadFromCache();
    // Auto-fetch if user is already authenticated
    if (_authProvider.isAuthenticated) {
      fetchSavedPlaces();
    }
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
      debugPrint('Preloaded ${_savedPlaces.length} saved places from cache.');
      if (_savedPlaces.isNotEmpty) notifyListeners();
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
    } catch (e) {
      debugPrint('Error saving places to cache: $e');
    }
  }

  Future<void> fetchSavedPlaces() async {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (ConnectivityService.instance.isConnected) {
        final places = await _savedRepository.fetchSavedPlaces(userId);
        _savedPlaces = places;
        _saveToCache();
      } else {
        _loadFromCache();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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

  Future<void> toggleSaved(PlaceModel place) async {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) {
      _errorMessage = 'Must be logged in to save places.';
      notifyListeners();
      return;
    }

    final currentlySaved = isSaved(place.id);
    final isSaving = !currentlySaved;

    // Optimistic UI Update
    if (isSaving) {
      _savedPlaces.add(place);
    } else {
      _savedPlaces.removeWhere((p) => p.id == place.id);
    }
    _saveToCache();
    notifyListeners();

    // Background Backend Sync
    try {
      await _savedRepository.toggleSaved(userId, place.id, isSaving);
    } catch (e) {
      // Rollback on failure
      debugPrint('Failed to toggle saved place in backend. Rolling back. $e');
      if (isSaving) {
        _savedPlaces.removeWhere((p) => p.id == place.id);
      } else {
        _savedPlaces.add(place);
      }
      _saveToCache();
      _errorMessage = 'Failed to sync save status. Please check your connection.';
      notifyListeners();
    }
  }

  void removeSaved(String placeId) {
    // Convenience wrapper for UI consistency
    final place = _savedPlaces.firstWhere((p) => p.id == placeId, orElse: () => throw Exception('Place not found'));
    toggleSaved(place);
  }
}
