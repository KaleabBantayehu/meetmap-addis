import '../../shared/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> login(String email, String password);
  Future<UserModel> signup(String email, String password, String name);
  Future<void> logout();
}
