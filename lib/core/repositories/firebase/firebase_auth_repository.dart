import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/models/user_model.dart';
import '../auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel _mapFirebaseUser(fb.User user, {String? name}) {
    return UserModel(
      id: user.uid,
      name: name ?? user.displayName ?? 'New User',
      email: user.email,
      phoneNumber: user.phoneNumber,
      profileImageUrl: user.photoURL ?? 'https://i.pravatar.cc/150?img=12',
      username:
          user.email?.split('@').first ?? 'user_${user.uid.substring(0, 5)}',
      bio: 'New user to MeetMap Addis!',
      tags: const [],
      savedPlaceIds: const [],
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error getting current user from Firestore: $e');
    }

    return _mapFirebaseUser(user);
  }

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('User was null after sign in.');
      }

      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!);
        }
      } catch (e) {
        debugPrint('Error fetching user profile from Firestore: $e');
      }

      return _mapFirebaseUser(user);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in.');
    }
  }

  @override
  Future<UserModel> signup(String email, String password, String name) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('User was null after sign up.');
      }

      await user.updateDisplayName(name);

      final userModel = _mapFirebaseUser(user, name: name);

      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
      } catch (firestoreError) {
        debugPrint('Error saving user profile to Firestore: $firestoreError');
      }

      return userModel;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('An unexpected error occurred during sign up.');
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
      case 'invalid-credential':
        return 'The email address is badly formatted or credentials are invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for this email address.';
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      default:
        return 'Authentication failed. Please check your credentials.';
    }
  }
}
