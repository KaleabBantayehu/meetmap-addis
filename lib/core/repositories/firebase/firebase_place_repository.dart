import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/place_model.dart';
import '../place_repository.dart';

class FirebasePlaceRepository implements PlaceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<PlaceModel>> getPlaces() async {
    try {
      final snapshot = await _firestore.collection('places').get();
      return snapshot.docs
          .map((doc) => PlaceModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to load places: $e');
    }
  }

  @override
  Future<PlaceModel?> getPlaceById(String id) async {
    try {
      final doc = await _firestore.collection('places').doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return PlaceModel.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to load place details: $e');
    }
  }

  @override
  Future<List<PlaceModel>> searchPlaces(String query) async {
    try {
      final snapshot = await _firestore
          .collection('places')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      return snapshot.docs
          .map((doc) => PlaceModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  @override
  Future<List<PlaceModel>> getSavedPlaces() async {
    try {
      final snapshot = await _firestore.collection('places').limit(5).get();
      return snapshot.docs
          .map((doc) => PlaceModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to load saved places: $e');
    }
  }
}
