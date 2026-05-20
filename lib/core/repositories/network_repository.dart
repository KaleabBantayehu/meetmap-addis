import '../../shared/models/user_model.dart';

abstract class NetworkRepository {
  Future<List<UserModel>> getSuggestedUsers();
  Future<List<UserModel>> getTrendingReviewers();
}
