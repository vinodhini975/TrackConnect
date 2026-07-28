import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> getCurrentUser();
  Future<void> updateProfile(UserModel user);
  Future<void> logout();
  Stream<UserModel?> get userStream;
}
