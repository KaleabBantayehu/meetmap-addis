import '../../../shared/data/mock_places.dart';
import '../../../shared/models/place_model.dart';
import '../place_repository.dart';
import '../page_result.dart';
import '../../search/place_search_index.dart';
import '../../location/geo_bounds.dart';

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
  Future<PageResult<PlaceModel>> fetchPlacesPage({
    String? cursor,
    int limit = 20,
  }) async {
    final start = cursor == null
        ? 0
        : _places.indexWhere((p) => p.id == cursor) + 1;
    final safeStart = start < 0 ? 0 : start;
    final items = _places.skip(safeStart).take(limit).toList();
    return PageResult(
      items: items,
      nextCursor: items.isEmpty ? null : items.last.id,
      hasMore: safeStart + items.length < _places.length,
    );
  }

  @override
  Future<PageResult<PlaceModel>> fetchPlacesInBounds(
    GeoBounds bounds, {
    String? cursor,
    int limit = 50,
  }) async {
    final matches =
        _places
            .where(
              (place) =>
                  hasValidCoordinates(place.latitude, place.longitude) &&
                  bounds.contains(place.latitude, place.longitude),
            )
            .toList()
          ..sort(_compareGeographicOrder);
    final decodedCursor = decodeGeoCursor(cursor);
    final start = decodedCursor == null
        ? 0
        : matches.indexWhere((place) => place.id == decodedCursor.documentId) +
              1;
    final safeStart = start < 0 ? 0 : start;
    final items = matches.skip(safeStart).take(limit).toList();
    final last = items.isEmpty ? null : items.last;
    return PageResult(
      items: items,
      nextCursor: last == null
          ? null
          : encodeGeoCursor(last.latitude, last.longitude, last.id),
      hasMore: safeStart + items.length < matches.length,
    );
  }

  @override
  Future<PageResult<PlaceModel>> fetchNearbyPlaces({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? cursor,
    int candidateLimit = 50,
  }) async {
    final page = await fetchPlacesInBounds(
      GeoBounds.around(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      ),
      cursor: cursor,
      limit: candidateLimit,
    );
    final places =
        page.items.where((place) {
          return distanceKm(
                fromLatitude: latitude,
                fromLongitude: longitude,
                toLatitude: place.latitude,
                toLongitude: place.longitude,
              ) <=
              radiusKm;
        }).toList()..sort((a, b) {
          final aDistance = distanceKm(
            fromLatitude: latitude,
            fromLongitude: longitude,
            toLatitude: a.latitude,
            toLongitude: a.longitude,
          );
          final bDistance = distanceKm(
            fromLatitude: latitude,
            fromLongitude: longitude,
            toLatitude: b.latitude,
            toLongitude: b.longitude,
          );
          return aDistance.compareTo(bDistance);
        });
    return PageResult(
      items: places,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  int _compareGeographicOrder(PlaceModel a, PlaceModel b) {
    final latitude = a.latitude.compareTo(b.latitude);
    if (latitude != 0) return latitude;
    final longitude = a.longitude.compareTo(b.longitude);
    if (longitude != 0) return longitude;
    return a.id.compareTo(b.id);
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
    return (await searchPlacesPage(query)).items;
  }

  @override
  Future<PageResult<PlaceModel>> searchPlacesPage(
    String normalizedQuery, {
    String? cursor,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final query = normalizePlaceSearchQuery(normalizedQuery);
    if (query.length < placeSearchMinimumLength) {
      return const PageResult(items: [], nextCursor: null, hasMore: false);
    }
    final matches = _places.where((place) {
      final prefixes = buildPlaceSearchPrefixes([
        place.name,
        place.category,
        place.location,
        ...place.tags,
      ]);
      return prefixes.contains(query);
    }).toList()..sort((a, b) => a.id.compareTo(b.id));
    final start = cursor == null
        ? 0
        : matches.indexWhere((place) => place.id == cursor) + 1;
    final safeStart = start < 0 ? 0 : start;
    final items = matches.skip(safeStart).take(limit).toList();
    return PageResult(
      items: items,
      nextCursor: items.isEmpty ? null : items.last.id,
      hasMore: safeStart + items.length < matches.length,
    );
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
