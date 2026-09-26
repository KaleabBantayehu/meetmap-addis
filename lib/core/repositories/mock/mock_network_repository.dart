import '../../../shared/data/mock_network_data.dart';
import '../../../shared/models/user_model.dart';
import '../network_repository.dart';

class MockNetworkRepository implements NetworkRepository {
  @override
  Future<List<UserModel>> getSuggestedUsers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(MockNetworkData.suggestedUsers);
  }

  @override
  Future<List<UserModel>> getTrendingReviewers() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(MockNetworkData.trendingReviewers);
  }

  @override
  Future<void> followUser(String currentUserId, String targetUserId) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return false;
  }

  @override
  Future<NetworkRelationshipSummary> getRelationshipSummary(
    String currentUserId,
    List<String> targetUserIds,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return NetworkRelationshipSummary(
      followingUserIds: const {},
      followerCounts: {for (final id in targetUserIds) id: 0},
    );
  }

  @override
  Future<int> getFollowerCount(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return 0;
  }

  @override
  Future<int> getFollowingCount(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return 0;
  }
}
