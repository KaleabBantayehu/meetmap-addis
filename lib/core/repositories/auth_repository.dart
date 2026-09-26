import '../../shared/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> login(String email, String password);
  Future<UserModel> signup(String email, String password, String name);
  Future<void> logout();
  Stream<UserModel?> get authStateChanges;
  Future<UserModel> signInWithGoogle();
  Future<void> sendPasswordResetEmail(String email);
  Future<UserModel> updateProfile(UserModel user);
  Future<void> deleteAccount();
}
