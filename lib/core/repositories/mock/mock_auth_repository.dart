import 'dart:async';
import '../../../shared/models/user_model.dart';
import '../auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();

  MockAuthRepository() {
    // Emit initial null state
    _authStateController.add(null);
  }

  @override
  String? get currentUserId => _currentUser?.id;

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

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
      tags: const ['Flutter', 'Addis', 'Tech'],
      savedPlaceIds: const ['1', '2'],
    );
    _authStateController.add(_currentUser);
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
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = UserModel(
      id: 'mock_google_user',
      name: 'Google User',
      email: 'google@meetmap.com',
      username: 'google_user',
      profileImageUrl: 'https://i.pravatar.cc/150?img=15',
      bio: 'Signed in with Google!',
      tags: const ['Google', 'Addis'],
      savedPlaceIds: const [],
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  // ————————————————————————————————————————————————————————————————
  // IMPLEMENTED MOCK METHOD FOR FORGOT PASSWORD
  // ————————————————————————————————————————————————————————————————
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Simulate error if string is missing basic validation
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Invalid email format.');
    }

    // Simulate user-not-found for an explicit fake testing scenario
    if (email == 'notfound@meetmap.com') {
      throw Exception('No account found with this email.');
    }

    // Success scenario does nothing, representing standard email dispatch
    return;
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = user;
    _authStateController.add(_currentUser);
    return user;
  }
}
