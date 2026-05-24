import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/user_model.dart';
import '../network_repository.dart';
import '../repository_error_mapper.dart';

class FirebaseNetworkRepository implements NetworkRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel _mapDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['id'] = doc.id;
    return UserModel.fromMap(data);
  }

  @override
  Future<List<UserModel>> getSuggestedUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .limit(20)
          .get()
          .timeout(const Duration(seconds: 5));
      final users = snapshot.docs.map(_mapDoc).toList();
      users.sort((a, b) => a.name.compareTo(b.name));
      return users;
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load suggested users'));
    }
  }

  @override
  Future<List<UserModel>> getTrendingReviewers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .limit(20)
          .get()
          .timeout(const Duration(seconds: 5));
      final users = snapshot.docs.map(_mapDoc).toList();
      users.sort((a, b) => b.followerCount.compareTo(a.followerCount));
      return users;
    } catch (e) {
      throw Exception(
        mapRepositoryError(e, 'Failed to load trending reviewers'),
      );
    }
  }
}
