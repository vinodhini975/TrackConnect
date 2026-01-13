import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Singleton pattern to ensure we use the same stream controller everywhere
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // Pipe FirebaseAuth stream into our custom controller with filtering
    _auth.authStateChanges().listen((user) {
      // If we are in the middle of a delicate verification, don't let the stream leak
      if (!_isVerifying) {
        _userController.add(user);
      }
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '655828864389-ccoc2ndhsg0ggmevmob0bh0al1tgmg3l.apps.googleusercontent.com',
  );

  final StreamController<User?> _userController = StreamController<User?>.broadcast();
  bool _isVerifying = false;

  // This stream is what the app listens to. 
  // It only emits users once they have passed our business logic checks.
  Stream<User?> get userStream => _userController.stream;

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Google Sign-In with strict atomic enforcement
  Future<UserCredential?> signInWithGoogle({required bool isSignUp}) async {
    try {
      _isVerifying = true; // Lock the stream to prevent "flicker" to Dashboard
      
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isVerifying = false;
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // This call usually triggers authStateChanges, but we locked it with _isVerifying
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (!isSignUp && isNewUser) {
        // FAIL CASE: User tried to Sign In with an account that doesn't exist
        await userCredential.user?.delete();
        await _googleSignIn.signOut();
        await _auth.signOut();
        _isVerifying = false;
        
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No account found. Please sign up first.',
        );
      }

      // SUCCESS CASE: User is valid, or it was a sign-up
      _isVerifying = false;
      _userController.add(userCredential.user); // Manually release the user to the UI
      return userCredential;
      
    } catch (e) {
      _isVerifying = false;
      // Ensure UI stays on Login screen by reinforcing null state if something broke
      _userController.add(null); 
      rethrow;
    }
  }

  // Email flows (Firebase handles these natively for existence checks)
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }
}
