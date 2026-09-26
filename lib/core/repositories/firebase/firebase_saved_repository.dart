import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/place_model.dart';
import '../saved_repository.dart';
import '../saved_place_hydrator.dart';
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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      throw Exception('User not authenticated or unauthorized');
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_places')
          .get()
          .timeout(const Duration(seconds: 4));

      final savedDocuments = snapshot.docs.toList()
        ..sort((a, b) {
          final aTime = a.data()['savedAt'] as Timestamp?;
          final bTime = b.data()['savedAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

      return hydrateSavedPlaces(
        savedPlaceIds: savedDocuments.map((doc) => doc.id).toList(),
        fetchBatch: (ids) async {
          final placesSnapshot = await _firestore
              .collection('places')
              .where(FieldPath.documentId, whereIn: ids)
              .get()
              .timeout(const Duration(seconds: 4));
          return placesSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return PlaceModel.fromMap(data);
          }).toList();
        },
      );
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load saved places'));
    }
  }

  @override
  Future<void> toggleSaved(String userId, String placeId, bool isSaving) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      throw Exception('User not authenticated or unauthorized');
    }

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
