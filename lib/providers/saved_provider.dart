import 'package:flutter/material.dart';
import '../core/repositories/place_repository.dart';
import '../shared/models/place_model.dart';

class SavedProvider with ChangeNotifier {
  final PlaceRepository _placeRepository;

  SavedProvider({required PlaceRepository placeRepository})
      : _placeRepository = placeRepository;

  List<PlaceModel> _savedPlaces = [];
  List<PlaceModel> get savedPlaces => _savedPlaces;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSavedPlaces() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _savedPlaces = await _placeRepository.getSavedPlaces();
    } catch (e) {
      _errorMessage = e.toString();
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
    notifyListeners();
  }

  void removeSaved(String placeId) {
    _savedPlaces.removeWhere((p) => p.id == placeId);
    notifyListeners();
  }
}
