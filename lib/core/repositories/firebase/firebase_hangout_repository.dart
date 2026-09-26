import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/hangout_model.dart';
import '../hangout_repository.dart';
import '../page_result.dart';
import '../repository_error_mapper.dart';

class FirebaseHangoutRepository implements HangoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  T _mapDoc<T>(
    DocumentSnapshot<Map<String, dynamic>> doc,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    final data = doc.data() ?? {};
    data['id'] = doc.id;
    return fromMap(data);
  }

  @override
  Future<List<HangoutModel>> getHangouts() async {
    return (await getHangoutsPage()).items;
  }

  @override
  Future<PageResult<HangoutModel>> getHangoutsPage({
    String? cursor,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('hangouts')
          .where('lifecycleStatus', isEqualTo: 'active')
          .orderBy(FieldPath.documentId)
          .limit(limit + 1);
      if (cursor != null) query = query.startAfter([cursor]);
      final snapshot = await query.get().timeout(const Duration(seconds: 5));
      final hasMore = snapshot.docs.length > limit;
      final docs = snapshot.docs.take(limit).toList();
      return PageResult(
        items: docs
            .map((doc) => _mapDoc(doc, HangoutModel.fromMap))
            .where((hangout) => hangout.isActive)
            .toList(),
        nextCursor: docs.isEmpty ? null : docs.last.id,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load hangouts'));
    }
  }

  @override
  Future<List<VenueModel>> getTopPickVenues() async {
    try {
      final snapshot = await _firestore
          .collection('venues')
          .get()
          .timeout(const Duration(seconds: 5));
      return snapshot.docs
          .map((doc) => _mapDoc(doc, VenueModel.fromMap))
          .toList();
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load top pick venues'));
    }
  }

  @override
  Future<List<ActivityModel>> getRecentActivities() async {
    try {
      final snapshot = await _firestore
          .collection('activities')
          .get()
          .timeout(const Duration(seconds: 5));
      return snapshot.docs
          .map((doc) => _mapDoc(doc, ActivityModel.fromMap))
          .toList();
    } catch (e) {
      throw Exception(
        mapRepositoryError(e, 'Failed to load recent activities'),
      );
    }
  }

  @override
  Future<HangoutModel> createHangout(HangoutModel hangout) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final docRef = _firestore.collection('hangouts').doc();
      final hangoutWithUser = hangout.copyWith(
        createdBy: currentUser.uid,
        attendeeCount: 0,
        isLive: false,
      );

      final data = {
        ...hangoutWithUser.toMap(),
        'id': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      data.remove('attendeeCount');
      data.remove('isLive');

      await docRef.set(data).timeout(const Duration(seconds: 4));

      return hangoutWithUser.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to create hangout'));
    }
  }
}
