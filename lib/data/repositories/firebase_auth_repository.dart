import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<UserModel?> get userStream {
    // Standard stream that listens to Auth changes first
    return _auth.authStateChanges().asyncExpand((fbUser) {
      if (fbUser == null) {
        debugPrint("Auth: No user signed in");
        return Stream.value(null);
      }
      
      debugPrint("Auth: User signed in with UID: ${fbUser.uid}");
      
      // Return a stream that listens to the specific user document
      return _db
          .collection('users')
          .doc(fbUser.uid)
          .snapshots()
          .map((doc) {
            if (!doc.exists) {
              debugPrint("Firestore: Document does not exist for UID: ${fbUser.uid}");
              return null;
            }
            debugPrint("Firestore: Document loaded for ${fbUser.uid}");
            return UserModel.fromFirestore(doc);
          });
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    final doc = await _db.collection('users').doc(fbUser.uid).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }
}
