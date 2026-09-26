import 'package:flutter/material.dart';
import '../core/repositories/repository_error_mapper.dart';
import '../core/repositories/saved_repository.dart';
import '../shared/models/place_model.dart';
import '../core/storage/local_storage_service.dart';
import '../core/storage/cache_keys.dart';
import '../core/storage/connectivity_service.dart';
import 'auth_provider.dart';

class SavedProvider with ChangeNotifier {
  final SavedRepository _savedRepository;
  final AuthProvider _authProvider;
  final bool Function() _isConnected;

  SavedProvider({
    required SavedRepository savedRepository,
    required AuthProvider authProvider,
    bool Function()? isConnected,
  }) : _savedRepository = savedRepository,
       _authProvider = authProvider,
       _isConnected =
           isConnected ?? (() => ConnectivityService.instance.isConnected) {
    _sessionUserId = _authProvider.currentUser?.id;
    if (_sessionUserId != null) _loadFromCache(_sessionUserId!);
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
  String? _sessionUserId;
  int _sessionGeneration = 0;

  void syncSession(String? userId) {
    if (_sessionUserId == userId) return;
    _sessionGeneration++;
    final previousUserId = _sessionUserId;
    _sessionUserId = userId;
    _savedPlaces = [];
    _errorMessage = null;
    _isLoading = false;
    if (previousUserId != null) {
      LocalStorageService.instance.remove(
        CacheKeys.savedPlacesForUser(previousUserId),
      );
      LocalStorageService.instance.remove(
        CacheKeys.savedPlaceIdsForUser(previousUserId),
      );
      LocalStorageService.instance.remove(
        CacheKeys.savedPlacesLastSyncForUser(previousUserId),
      );
    }
    if (userId != null) _loadFromCache(userId);
    notifyListeners();
    if (userId != null) fetchSavedPlaces();
  }

  void _loadFromCache(String userId) {
    try {
      _savedPlaces = LocalStorageService.instance.getSavedPlaces(userId);
      debugPrint('Preloaded ${_savedPlaces.length} saved places from cache.');
      if (_savedPlaces.isNotEmpty) notifyListeners();
    } catch (e) {
      debugPrint('Error preloading saved places: $e');
    }
  }

  void _saveToCache(String userId) {
    try {
      LocalStorageService.instance.saveSavedPlaces(userId, _savedPlaces);
      LocalStorageService.instance.saveSavedPlaceIds(
        userId,
        _savedPlaces.map((p) => p.id).toList(),
      );
      LocalStorageService.instance.setString(
        CacheKeys.savedPlacesLastSyncForUser(userId),
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('Error saving places to cache: $e');
    }
  }

  Future<void> fetchSavedPlaces() async {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) return;
    final generation = _sessionGeneration;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isConnected()) {
        final places = await _savedRepository.fetchSavedPlaces(userId);
        if (!_isCurrentSession(userId, generation)) return;
        _savedPlaces = places;
        _saveToCache(userId);
      } else {
        _loadFromCache(userId);
      }
    } catch (e) {
      if (!_isCurrentSession(userId, generation)) return;
      _errorMessage = cleanExceptionMessage(e, 'Failed to load saved places');
      if (_savedPlaces.isEmpty) {
        _loadFromCache(userId);
      }
    } finally {
      if (_isCurrentSession(userId, generation)) {
        _isLoading = false;
        notifyListeners();
      }
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
    final generation = _sessionGeneration;

    final currentlySaved = isSaved(place.id);
    final isSaving = !currentlySaved;

    // Optimistic UI Update
    if (isSaving) {
      _savedPlaces.add(place);
    } else {
      _savedPlaces.removeWhere((p) => p.id == place.id);
    }
    _saveToCache(userId);
    notifyListeners();

    // Background Backend Sync
    try {
      await _savedRepository.toggleSaved(userId, place.id, isSaving);
      if (!_isCurrentSession(userId, generation)) return;
    } catch (e) {
      if (!_isCurrentSession(userId, generation)) return;
      // Rollback on failure
      debugPrint('Failed to toggle saved place in backend. Rolling back. $e');
      if (isSaving) {
        _savedPlaces.removeWhere((p) => p.id == place.id);
      } else {
        _savedPlaces.add(place);
      }
      _saveToCache(userId);
      _errorMessage =
          'Failed to sync save status. Please check your connection.';
      notifyListeners();
    }
  }

  bool _isCurrentSession(String userId, int generation) =>
      _sessionUserId == userId && _sessionGeneration == generation;

  void removeSaved(String placeId) {
    // Convenience wrapper for UI consistency
    final place = _savedPlaces.firstWhere(
      (p) => p.id == placeId,
      orElse: () => throw Exception('Place not found'),
    );
    toggleSaved(place);
  }
}
