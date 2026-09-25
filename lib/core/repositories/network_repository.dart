import '../../shared/models/user_model.dart';

abstract class NetworkRepository {
  Future<List<UserModel>> getSuggestedUsers();
  Future<List<UserModel>> getTrendingReviewers();
  Future<void> followUser(String currentUserId, String targetUserId);
  Future<void> unfollowUser(String currentUserId, String targetUserId);
  Future<bool> isFollowing(String currentUserId, String targetUserId);
  Future<int> getFollowerCount(String userId);
  Future<int> getFollowingCount(String userId);
}
