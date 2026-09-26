import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/models/event_model.dart';
import '../event_repository.dart';
import '../page_result.dart';
import '../repository_error_mapper.dart';

class FirebaseEventRepository implements EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  EventModel _mapDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['id'] = doc.id;
    return EventModel.fromMap(data);
  }

  @override
  Future<List<EventModel>> getEvents() async {
    return (await getEventsPage()).items;
  }

  @override
  Future<PageResult<EventModel>> getEventsPage({
    String? cursor,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('events')
          .where('lifecycleStatus', isEqualTo: 'active')
          .orderBy(FieldPath.documentId)
          .limit(limit + 1);
      if (cursor != null) query = query.startAfter([cursor]);
      final snapshot = await query.get().timeout(const Duration(seconds: 5));
      final hasMore = snapshot.docs.length > limit;
      final docs = snapshot.docs.take(limit).toList();
      return PageResult(
        items: docs.map(_mapDoc).where((event) => event.isActive).toList(),
        nextCursor: docs.isEmpty ? null : docs.last.id,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load events'));
    }
  }

  @override
  Future<EventModel?> getFeaturedEvent() async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('lifecycleStatus', isEqualTo: 'active')
          .where('isFeatured', isEqualTo: true)
          .limit(10)
          .get()
          .timeout(const Duration(seconds: 5));
      for (final event in snapshot.docs.map(_mapDoc)) {
        if (event.isActive && event.isFeatured) return event;
      }
      return null;
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load featured event'));
    }
  }

  @override
  Future<EventModel> createEvent(EventModel event) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final docRef = _firestore.collection('events').doc();
      final eventWithUser = event.copyWith(
        createdBy: currentUser.uid,
        attendeeCount: 0,
        isFeatured: false,
      );

      final data = {
        ...eventWithUser.toMap(),
        'id': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      data.remove('attendeeCount');
      data.remove('isFeatured');

      await docRef.set(data).timeout(const Duration(seconds: 4));

      return eventWithUser.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to create event'));
    }
  }
}
