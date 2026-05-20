import '../../../shared/models/user_model.dart';
import '../auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentUser;
  }

  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = UserModel(
      id: 'mock_user_1',
      name: 'Kaleab Bantayehu',
      email: email,
      username: 'kaleab_b',
      profileImageUrl: 'https://i.pravatar.cc/150?img=12',
      bio: 'Flutter Developer exploring social discovery in Addis.',
      tags: ['Flutter', 'Addis', 'Tech'],
      savedPlaceIds: const ['1', '2'],
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> signup(String email, String password, String name) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = UserModel(
      id: 'mock_user_1',
      name: name,
      email: email,
      username: name.toLowerCase().replaceAll(' ', '_'),
      profileImageUrl: 'https://i.pravatar.cc/150?img=12',
      bio: 'New user to MeetMap Addis!',
      tags: const [],
      savedPlaceIds: const [],
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }
}
