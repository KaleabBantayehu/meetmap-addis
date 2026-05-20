import '../../shared/models/user_model.dart';

abstract class UserRepository {
  Future<UserModel?> getUserById(String id);
}
