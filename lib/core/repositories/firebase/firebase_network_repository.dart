import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  Future<void> followUser(String currentUserId, String targetUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != currentUserId) {
      throw Exception('User not authenticated or unauthorized');
    }

    try {
      final followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);
      final followerRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);

      await _firestore
          .runTransaction((transaction) async {
            transaction.set(followingRef, {
              'userId': targetUserId,
              'createdAt': FieldValue.serverTimestamp(),
            });
            transaction.set(followerRef, {
              'userId': currentUserId,
              'createdAt': FieldValue.serverTimestamp(),
            });
          })
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to follow user'));
    }
  }

  @override
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != currentUserId) {
      throw Exception('User not authenticated or unauthorized');
    }

    try {
      final followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);
      final followerRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);

      await _firestore
          .runTransaction((transaction) async {
            transaction.delete(followingRef);
            transaction.delete(followerRef);
          })
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to unfollow user'));
    }
  }

  @override
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .get()
          .timeout(const Duration(seconds: 5));
      return doc.exists;
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load follow state'));
    }
  }

  @override
  Future<NetworkRelationshipSummary> getRelationshipSummary(
    String currentUserId,
    List<String> targetUserIds,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != currentUserId) {
      throw Exception('User not authenticated or unauthorized');
    }

    final targetIds = targetUserIds
        .where((id) => id.isNotEmpty && id != currentUserId)
        .toSet()
        .toList();
    if (targetIds.isEmpty) {
      return const NetworkRelationshipSummary(
        followingUserIds: {},
        followerCounts: {},
      );
    }

    try {
      final followingIds = <String>{};
      for (var start = 0; start < targetIds.length; start += 30) {
        final end = start + 30 < targetIds.length
            ? start + 30
            : targetIds.length;
        final chunk = targetIds.sublist(start, end);
        final snapshot = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('following')
            .where(FieldPath.documentId, whereIn: chunk)
            .get()
            .timeout(const Duration(seconds: 5));
        followingIds.addAll(snapshot.docs.map((doc) => doc.id));
      }

      final countEntries = await Future.wait(
        targetIds.map((id) async => MapEntry(id, await getFollowerCount(id))),
      );
      return NetworkRelationshipSummary(
        followingUserIds: followingIds,
        followerCounts: Map.fromEntries(countEntries),
      );
    } catch (e) {
      throw Exception(
        mapRepositoryError(e, 'Failed to load relationship state'),
      );
    }
  }

  @override
  Future<int> getFollowerCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('followers')
          .count()
          .get()
          .timeout(const Duration(seconds: 5));
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load follower count'));
    }
  }

  @override
  Future<int> getFollowingCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .count()
          .get()
          .timeout(const Duration(seconds: 5));
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load following count'));
    }
  }
}
