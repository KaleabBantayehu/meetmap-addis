import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/place_model.dart';
import '../saved_repository.dart';
import '../repository_error_mapper.dart';

class FirebaseSavedRepository implements SavedRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  @Deprecated('Use fetchSavedPlaces instead')
  Future<List<String>> getSavedPlaceIds() async {
    // Legacy support, throw or return empty if not fully supported.
    return [];
  }

  @override
  @Deprecated('Use toggleSaved instead')
  Future<void> savePlace(String placeId) async {}

  @override
  @Deprecated('Use toggleSaved instead')
  Future<void> removePlace(String placeId) async {}

  @override
  Future<List<PlaceModel>> fetchSavedPlaces(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_places')
          .get()
          .timeout(const Duration(seconds: 4));

      final List<PlaceModel> savedPlaces = [];

      // Fetch details for each saved place
      for (final doc in snapshot.docs) {
        final placeId = doc.id;
        final placeDoc = await _firestore
            .collection('places')
            .doc(placeId)
            .get()
            .timeout(const Duration(seconds: 4));

        if (placeDoc.exists && placeDoc.data() != null) {
          final data = placeDoc.data()!;
          data['id'] = placeDoc.id;
          savedPlaces.add(PlaceModel.fromMap(data));
        }
      }
      return savedPlaces;
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load saved places'));
    }
  }

  @override
  Future<void> toggleSaved(String userId, String placeId, bool isSaving) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_places')
          .doc(placeId);

      if (isSaving) {
        await docRef
            .set({'savedAt': FieldValue.serverTimestamp()})
            .timeout(const Duration(seconds: 4));
      } else {
        await docRef.delete().timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to update saved places'));
    }
  }

  @override
  Future<bool> isSaved(String userId, String placeId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_places')
          .doc(placeId)
          .get()
          .timeout(const Duration(seconds: 4));
      return doc.exists;
    } catch (e) {
      // Graceful fallback on failure
      return false;
    }
  }
}
