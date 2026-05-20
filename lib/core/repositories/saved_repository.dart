abstract class SavedRepository {
  Future<List<String>> getSavedPlaceIds();
  Future<void> savePlace(String placeId);
  Future<void> removePlace(String placeId);
}
