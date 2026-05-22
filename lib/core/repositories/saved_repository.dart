import '../../shared/models/place_model.dart';

abstract class SavedRepository {
  @Deprecated('Use fetchSavedPlaces instead')
  Future<List<String>> getSavedPlaceIds();

  @Deprecated('Use toggleSaved instead')
  Future<void> savePlace(String placeId);

  @Deprecated('Use toggleSaved instead')
  Future<void> removePlace(String placeId);

  Future<List<PlaceModel>> fetchSavedPlaces(String userId);
  Future<void> toggleSaved(String userId, String placeId, bool isSaving);
  Future<bool> isSaved(String userId, String placeId);
}
