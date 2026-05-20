import '../../shared/models/place_model.dart';

abstract class PlaceRepository {
  Future<List<PlaceModel>> getPlaces();
  Future<PlaceModel?> getPlaceById(String id);
  Future<List<PlaceModel>> searchPlaces(String query);
  Future<List<PlaceModel>> getSavedPlaces();
}
