import '../../shared/models/place_model.dart';

abstract class PlaceRepository {
  @Deprecated('Use fetchPlaces instead')
  Future<List<PlaceModel>> getPlaces();

  @Deprecated('Use fetchPlaceById instead')
  Future<PlaceModel?> getPlaceById(String id);

  Future<List<PlaceModel>> searchPlaces(String query);
  
  @Deprecated('Use fetchSavedPlaces instead')
  Future<List<PlaceModel>> getSavedPlaces();

  Future<List<PlaceModel>> fetchPlaces();
  Future<List<PlaceModel>> fetchFeaturedPlaces();
  Future<PlaceModel?> fetchPlaceById(String id);
  Future<List<PlaceModel>> filterPlaces({
    String? category,
    String? priceRange,
    double? minRating,
    List<String>? amenities,
  });
  Future<List<PlaceModel>> fetchSavedPlaces();
  Future<PlaceModel> createPlace(PlaceModel place);
}
