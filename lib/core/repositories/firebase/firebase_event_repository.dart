import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/models/event_model.dart';
import '../event_repository.dart';
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
    try {
      final snapshot = await _firestore
          .collection('events')
          .orderBy('date')
          .get()
          .timeout(const Duration(seconds: 5));
      return snapshot.docs
          .map(_mapDoc)
          .where((event) => event.isActive)
          .toList();
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load events'));
    }
  }

  @override
  Future<EventModel?> getFeaturedEvent() async {
    try {
      final events = await getEvents();
      for (final event in events) {
        if (event.isFeatured) return event;
      }
      return null;
    } catch (e) {
      if (e.toString().contains('failed: precond')) {
        final events = await getEvents();
        for (final event in events) {
          if (event.isFeatured) return event;
        }
        return null;
      }
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
      data.remove('lifecycleStatus');

      await docRef.set(data).timeout(const Duration(seconds: 4));

      return eventWithUser.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to create event'));
    }
  }
}
