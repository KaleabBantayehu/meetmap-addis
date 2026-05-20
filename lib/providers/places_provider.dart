import 'package:flutter/material.dart';
import '../core/repositories/place_repository.dart';
import '../shared/models/place_model.dart';

class PlacesProvider with ChangeNotifier {
  final PlaceRepository _placeRepository;

  PlacesProvider({required PlaceRepository placeRepository})
      : _placeRepository = placeRepository;

  List<PlaceModel> _places = [];
  List<PlaceModel> get places => _places;

  List<PlaceModel> _searchResults = [];
  List<PlaceModel> get searchResults => _searchResults;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPlaces() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _places = await _placeRepository.getPlaces();
    } catch (e) {
      _errorMessage = e.toString();
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
      _searchResults = await _placeRepository.searchPlaces(query);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
