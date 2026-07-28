import 'dart:async';
import '../models/user_model.dart';
import '../mock_data/mock_data_store.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserModel _user = MockDataStore.currentUser;
  final _controller = StreamController<UserModel?>.broadcast();

  @override
  Stream<UserModel?> get userStream => _controller.stream;

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _user;
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _user = user;
    _controller.add(_user);
  }

  @override
  Future<void> logout() async {
    _controller.add(null);
  }
}
