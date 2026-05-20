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
}
