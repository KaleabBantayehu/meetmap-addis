import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/place_model.dart';
import '../place_repository.dart';
import '../page_result.dart';
import '../repository_error_mapper.dart';
import '../../search/place_search_index.dart';
import '../../location/geo_bounds.dart';

class FirebasePlaceRepository implements PlaceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PlaceModel _mapDocToPlace(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['id'] = doc.id; // ensure ID is correctly populated from doc.id
    return PlaceModel.fromMap(data);
  }

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
    return (await fetchPlacesPage()).items;
  }

  @override
  Future<PageResult<PlaceModel>> fetchPlacesPage({
    String? cursor,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('places')
          .orderBy(FieldPath.documentId)
          .limit(limit + 1);
      if (cursor != null) query = query.startAfter([cursor]);
      final snapshot = await query.get().timeout(const Duration(seconds: 4));
      final hasMore = snapshot.docs.length > limit;
      final docs = snapshot.docs.take(limit).toList();
      return PageResult(
        items: docs.map(_mapDocToPlace).toList(),
        nextCursor: docs.isEmpty ? null : docs.last.id,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load places'));
    }
  }

  @override
  Future<PageResult<PlaceModel>> fetchPlacesInBounds(
    GeoBounds bounds, {
    String? cursor,
    int limit = 50,
  }) async {
    if (!bounds.isValid) {
      throw ArgumentError('Valid non-antimeridian map bounds are required.');
    }
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('places')
          .where('latitude', isGreaterThanOrEqualTo: bounds.south)
          .where('latitude', isLessThanOrEqualTo: bounds.north)
          .where('longitude', isGreaterThanOrEqualTo: bounds.west)
          .where('longitude', isLessThanOrEqualTo: bounds.east)
          .orderBy('latitude')
          .orderBy('longitude')
          .orderBy(FieldPath.documentId)
          .limit(limit + 1);
      final decodedCursor = decodeGeoCursor(cursor);
      if (decodedCursor != null) {
        query = query.startAfter([
          decodedCursor.latitude,
          decodedCursor.longitude,
          decodedCursor.documentId,
        ]);
      }
      final snapshot = await query.get().timeout(const Duration(seconds: 4));
      final hasMore = snapshot.docs.length > limit;
      final docs = snapshot.docs.take(limit).toList();
      final last = docs.isEmpty ? null : docs.last;
      return PageResult(
        items: docs.map(_mapDocToPlace).toList(),
        nextCursor: last == null
            ? null
            : encodeGeoCursor(
                (last.data()['latitude'] as num).toDouble(),
                (last.data()['longitude'] as num).toDouble(),
                last.id,
              ),
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load map places'));
    }
  }

  @override
  Future<PageResult<PlaceModel>> fetchNearbyPlaces({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? cursor,
    int candidateLimit = 50,
  }) async {
    final bounds = GeoBounds.around(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
    final page = await fetchPlacesInBounds(
      bounds,
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

  @override
  Future<List<PlaceModel>> fetchFeaturedPlaces() async {
    try {
      final snapshot = await _firestore
          .collection('places')
          .where('rating', isGreaterThanOrEqualTo: 4.5)
          .orderBy('rating', descending: true)
          .limit(10)
          .get()
          .timeout(const Duration(seconds: 4));
      return snapshot.docs.map(_mapDocToPlace).toList();
    } catch (e) {
      // Graceful fallback to client-side filtering if index is missing
      if (e.toString().contains('failed: precond')) {
        return filterPlaces(minRating: 4.5);
      }
      throw Exception(mapRepositoryError(e, 'Failed to load featured places'));
    }
  }

  @override
  Future<PlaceModel?> fetchPlaceById(String id) async {
    try {
      final doc = await _firestore
          .collection('places')
          .doc(id)
          .get()
          .timeout(const Duration(seconds: 4));
      if (!doc.exists) return null;
      return _mapDocToPlace(doc);
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load place details'));
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
    try {
      final query = normalizePlaceSearchQuery(normalizedQuery);
      if (query.length < placeSearchMinimumLength) {
        return const PageResult(items: [], nextCursor: null, hasMore: false);
      }

      Query<Map<String, dynamic>> firestoreQuery = _firestore
          .collection('places')
          .where('searchPrefixes', arrayContains: query)
          .orderBy(FieldPath.documentId)
          .limit(limit + 1);
      if (cursor != null) {
        firestoreQuery = firestoreQuery.startAfter([cursor]);
      }
      final snapshot = await firestoreQuery.get().timeout(
        const Duration(seconds: 4),
      );
      final hasMore = snapshot.docs.length > limit;
      final docs = snapshot.docs.take(limit).toList();
      return PageResult(
        items: docs.map(_mapDocToPlace).toList(),
        nextCursor: docs.isEmpty ? null : docs.last.id,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Search failed'));
    }
  }

  @override
  Future<List<PlaceModel>> filterPlaces({
    String? category,
    String? priceRange,
    double? minRating,
    List<String>? amenities,
  }) async {
    try {
      // Dynamic filtering client-side to prevent complex missing index errors
      final allPlaces = await fetchPlaces();
      return allPlaces.where((place) {
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
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Filter failed'));
    }
  }

  @override
  Future<List<PlaceModel>> fetchSavedPlaces() async {
    try {
      // Dummy query for saved places logic, ideally fetch by ID list
      final snapshot = await _firestore
          .collection('places')
          .limit(5)
          .get()
          .timeout(const Duration(seconds: 4));
      return snapshot.docs.map(_mapDocToPlace).toList();
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load saved places'));
    }
  }

  @override
  Future<PlaceModel> createPlace(PlaceModel place) async {
    final validationMessage = _validatePlace(place);
    if (validationMessage != null) {
      throw Exception(validationMessage);
    }

    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null || currentUserId.isEmpty) {
        throw Exception('Please sign in to create a place.');
      }

      final docRef = _firestore.collection('places').doc();

      final placeWithOwnership = place.copyWith(createdBy: currentUserId);
      final data = placeWithOwnership.toMap();
      // Trusted aggregate fields are initialized and maintained by the backend.
      data.remove('rating');
      data.remove('reviewCount');
      data.remove('ratingSum');
      data.remove('aggregateUpdatedAt');
      data['id'] = docRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['searchPrefixes'] = buildPlaceSearchPrefixes([
        placeWithOwnership.name,
        placeWithOwnership.category,
        placeWithOwnership.location,
        ...placeWithOwnership.tags,
      ]);

      await docRef.set(data).timeout(const Duration(seconds: 4));

      return placeWithOwnership.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception(cleanExceptionMessage(e, 'Failed to create place'));
    }
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
