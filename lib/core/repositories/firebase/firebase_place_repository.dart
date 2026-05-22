import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/place_model.dart';
import '../place_repository.dart';

class FirebasePlaceRepository implements PlaceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    try {
      final snapshot = await _firestore
          .collection('places')
          .get()
          .timeout(const Duration(seconds: 4));
      return snapshot.docs.map(_mapDocToPlace).toList();
    } catch (e) {
      throw Exception('Failed to load places from Firestore: $e');
    }
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
      throw Exception('Failed to load featured places: $e');
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
      throw Exception('Failed to load place details: $e');
    }
  }

  @override
  Future<List<PlaceModel>> searchPlaces(String query) async {
    try {
      if (query.isEmpty) return fetchPlaces();
      
      // Prefix search using Firestore rules
      final snapshot = await _firestore
          .collection('places')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get()
          .timeout(const Duration(seconds: 4));
      return snapshot.docs.map(_mapDocToPlace).toList();
    } catch (e) {
      throw Exception('Search failed: $e');
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
          matches = matches && place.category.toLowerCase() == category.toLowerCase();
        }
        if (priceRange != null && priceRange.isNotEmpty) {
          matches = matches && place.priceRange == priceRange;
        }
        if (minRating != null) {
          matches = matches && place.rating >= minRating;
        }
        if (amenities != null && amenities.isNotEmpty) {
          matches = matches && amenities.every((a) => place.amenities.contains(a));
        }
        return matches;
      }).toList();
    } catch (e) {
      throw Exception('Filter failed: $e');
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
      throw Exception('Failed to load saved places: $e');
    }
  }
}
