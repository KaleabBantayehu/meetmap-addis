import '../../../shared/data/mock_places.dart';
import '../../../shared/models/place_model.dart';
import '../place_repository.dart';

class MockPlaceRepository implements PlaceRepository {
  final List<PlaceModel> _places = List.from(mockPlaces);
  final List<PlaceModel> _savedPlaces = List.from(savedMockPlaces);

  @override
  Future<List<PlaceModel>> getPlaces() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_places);
  }

  @override
  Future<PlaceModel?> getPlaceById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _places.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PlaceModel>> searchPlaces(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (query.isEmpty) return List.from(_places);
    final normalized = query.toLowerCase();
    return _places.where((place) {
      return place.name.toLowerCase().contains(normalized) ||
          place.category.toLowerCase().contains(normalized) ||
          place.location.toLowerCase().contains(normalized) ||
          place.tags.any((t) => t.toLowerCase().contains(normalized));
    }).toList();
  }

  @override
  Future<List<PlaceModel>> getSavedPlaces() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_savedPlaces);
  }
}
