import '../saved_repository.dart';

class MockSavedRepository implements SavedRepository {
  final Set<String> _savedPlaceIds = {'1', '2'};

  @override
  Future<List<String>> getSavedPlaceIds() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _savedPlaceIds.toList();
  }

  @override
  Future<void> savePlace(String placeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _savedPlaceIds.add(placeId);
  }

  @override
  Future<void> removePlace(String placeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _savedPlaceIds.remove(placeId);
  }
}
