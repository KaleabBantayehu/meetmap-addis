import '../saved_repository.dart';
import '../../../shared/models/place_model.dart';
import '../../../shared/data/mock_places.dart';

class MockSavedRepository implements SavedRepository {
  final Set<String> _savedPlaceIds = {'1', '2'};
  final List<PlaceModel> _places = List.from(mockPlaces);

  @override
  @Deprecated('Use fetchSavedPlaces instead')
  Future<List<String>> getSavedPlaceIds() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _savedPlaceIds.toList();
  }

  @override
  @Deprecated('Use toggleSaved instead')
  Future<void> savePlace(String placeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _savedPlaceIds.add(placeId);
  }

  @override
  @Deprecated('Use toggleSaved instead')
  Future<void> removePlace(String placeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _savedPlaceIds.remove(placeId);
  }

  @override
  Future<List<PlaceModel>> fetchSavedPlaces(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _places.where((p) => _savedPlaceIds.contains(p.id)).toList();
  }

  @override
  Future<void> toggleSaved(String userId, String placeId, bool isSaving) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (isSaving) {
      _savedPlaceIds.add(placeId);
    } else {
      _savedPlaceIds.remove(placeId);
    }
  }

  @override
  Future<bool> isSaved(String userId, String placeId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _savedPlaceIds.contains(placeId);
  }
}
