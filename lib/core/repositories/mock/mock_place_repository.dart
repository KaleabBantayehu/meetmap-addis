import '../../../shared/data/mock_places.dart';
import '../../../shared/models/place_model.dart';
import '../place_repository.dart';

class MockPlaceRepository implements PlaceRepository {
  final List<PlaceModel> _places = List.from(mockPlaces);
  final List<PlaceModel> _savedPlaces = List.from(savedMockPlaces);

  @override
  @Deprecated('Use fetchPlaces instead')
  Future<List<PlaceModel>> getPlaces() => fetchPlaces();

  @override
  @Deprecated('Use fetchPlaceById instead')
  Future<PlaceModel?> getPlaceById(String id) => fetchPlaceById(id);

  @override
  @Deprecated('Use fetchSavedPlaces instead')
  Future<List<PlaceModel>> getSavedPlaces() => fetchSavedPlaces();

  @override
  Future<List<PlaceModel>> fetchPlaces() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_places);
  }

  @override
  Future<List<PlaceModel>> fetchFeaturedPlaces() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _places.where((p) => p.rating >= 4.7).toList();
  }

  @override
  Future<PlaceModel?> fetchPlaceById(String id) async {
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
  Future<List<PlaceModel>> filterPlaces({
    String? category,
    String? priceRange,
    double? minRating,
    List<String>? amenities,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _places.where((place) {
      bool matches = true;
      if (category != null && category.isNotEmpty) {
        matches =
            matches && place.category.toLowerCase() == category.toLowerCase();
      }
      if (priceRange != null && priceRange.isNotEmpty) {
        matches = matches && place.priceRange == priceRange;
      }
      if (minRating != null) {
        matches = matches && place.rating >= minRating;
      }
      if (amenities != null && amenities.isNotEmpty) {
        matches =
            matches && amenities.every((a) => place.amenities.contains(a));
      }
      return matches;
    }).toList();
  }

  @override
  Future<List<PlaceModel>> fetchSavedPlaces() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_savedPlaces);
  }

  @override
  Future<PlaceModel> createPlace(PlaceModel place) async {
    await Future.delayed(const Duration(seconds: 1));
    final validationMessage = _validatePlace(place);
    if (validationMessage != null) {
      throw Exception(validationMessage);
    }

    final newPlace = place.copyWith(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
    );
    _places.add(newPlace);
    return newPlace;
  }

  String? _validatePlace(PlaceModel place) {
    if (place.name.trim().length < 3) {
      return 'Place name must be at least 3 characters.';
    }
    if (place.description.trim().length < 20) {
      return 'Description must be at least 20 characters.';
    }
    if (place.category.trim().isEmpty) {
      return 'Please select a category.';
    }
    if (place.normalizedPriceLevel < 1 || place.normalizedPriceLevel > 4) {
      return 'Please select a price range.';
    }
    if (place.imageUrl.trim().isEmpty && place.imageUrls.isEmpty) {
      return 'Please upload at least one image.';
    }
    return null;
  }
}
