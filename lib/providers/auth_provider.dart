import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _userSubscription;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider(this._repo) {
    _listenToUser();
  }

  void _listenToUser() {
    _userSubscription?.cancel();
    _userSubscription = _repo.userStream.listen((user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateProfile({required String fullName, required String wardNumber}) async {
    if (_user == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = _user!.copyWith(fullName: fullName, wardNumber: wardNumber);
      await _repo.updateProfile(updated);
      // The stream listener in _listenToUser will catch the Firestore update 
      // and notify listeners automatically.
    } catch (e) {
      _errorMessage = 'Failed to update profile';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    // Stream listener will set _user to null
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
