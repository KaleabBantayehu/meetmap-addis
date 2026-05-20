import '../../../shared/models/user_model.dart';
import '../../../shared/data/mock_network_data.dart';
import '../user_repository.dart';

class MockUserRepository implements UserRepository {
  final List<UserModel> _users = [
    ...MockNetworkData.suggestedUsers,
    ...MockNetworkData.trendingReviewers,
    const UserModel(
      id: 'current_user',
      name: 'Kaleab B.',
      username: 'kaleab_bantayehu',
      email: 'kaleab@meetmap.com',
      profileImageUrl: 'https://i.pravatar.cc/150?u=current',
      title: 'Flutter Developer',
      bio: 'Building MeetMap Addis!',
    ),
  ];

  @override
  Future<UserModel?> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return _users.last;
    }
  }
}
