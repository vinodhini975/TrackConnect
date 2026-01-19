import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '655828864389-ccoc2ndhsg0ggmevmob0bh0al1tgmg3l.apps.googleusercontent.com',
  );

  final StreamController<User?> _userController = StreamController<User?>.broadcast();
  bool _isVerifying = false;

  AuthService._internal() {
    _auth.authStateChanges().listen((user) {
      if (!_isVerifying) {
        _userController.add(user);
      }
    });
  }

  // Stable stream for the app to listen to
  Stream<User?> get userStream => _userController.stream;
  
  // Current user helper
  User? get currentUser => _auth.currentUser;

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<UserCredential?> signInWithGoogle({required bool isSignUp}) async {
    try {
      _isVerifying = true;
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isVerifying = false;
        _userController.add(null);
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (!isSignUp && isNewUser) {
        await userCredential.user?.delete();
        await _googleSignIn.signOut();
        await _auth.signOut();
        _isVerifying = false;
        _userController.add(null);
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No account found. Please sign up first.',
        );
      }

      _isVerifying = false;
      _userController.add(userCredential.user);
      return userCredential;
      
    } catch (e) {
      _isVerifying = false;
      _userController.add(null);
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      _userController.add(cred.user);
      return cred;
    } catch (e) {
      _userController.add(null);
      rethrow;
    }
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      _userController.add(cred.user);
      return cred;
    } catch (e) {
      _userController.add(null);
      rethrow;
    }
  }
}
