import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/hangout_model.dart';
import '../hangout_repository.dart';

class FirebaseHangoutRepository implements HangoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<HangoutModel>> getHangouts() async {
    try {
      final snapshot = await _firestore.collection('hangouts').get();
      return snapshot.docs
          .map((doc) => HangoutModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to load hangouts: $e');
    }
  }

  @override
  Future<List<VenueModel>> getTopPickVenues() async {
    try {
      final snapshot = await _firestore.collection('venues').get();
      return snapshot.docs
          .map((doc) => VenueModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to load top pick venues: $e');
    }
  }

  @override
  Future<List<ActivityModel>> getRecentActivities() async {
    try {
      final snapshot = await _firestore.collection('activities').get();
      return snapshot.docs
          .map((doc) => ActivityModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to load recent activities: $e');
    }
  }
}
