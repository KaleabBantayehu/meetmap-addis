import '../../shared/models/user_model.dart';

class NetworkRelationshipSummary {
  final Set<String> followingUserIds;
  final Map<String, int> followerCounts;

  const NetworkRelationshipSummary({
    required this.followingUserIds,
    required this.followerCounts,
  });
}

abstract class NetworkRepository {
  Future<List<UserModel>> getSuggestedUsers();
  Future<List<UserModel>> getTrendingReviewers();
  Future<void> followUser(String currentUserId, String targetUserId);
  Future<void> unfollowUser(String currentUserId, String targetUserId);
  Future<bool> isFollowing(String currentUserId, String targetUserId);
  Future<NetworkRelationshipSummary> getRelationshipSummary(
    String currentUserId,
    List<String> targetUserIds,
  );
  Future<int> getFollowerCount(String userId);
  Future<int> getFollowingCount(String userId);
}
