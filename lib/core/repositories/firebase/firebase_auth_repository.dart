import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/models/user_model.dart';
import '../auth_repository.dart';
import '../../storage/cache_keys.dart';
import '../../storage/secure_storage_service.dart';
import '../../storage/local_storage_service.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  UserModel _mapFirebaseUser(fb.User user, {String? name}) {
    final defaultPhoto = 'https://i.pravatar.cc/150?img=12';
    return UserModel(
      id: user.uid,
      name: name ?? user.displayName ?? 'New User',
      email: user.email,
      phoneNumber: user.phoneNumber,
      profileImageUrl: user.photoURL ?? defaultPhoto,
      username: user.email != null && user.email!.contains('@')
          ? user.email!.split('@').first
          : 'user_${user.uid.substring(0, 5)}',
      bio: 'New user to MeetMap Addis!',
      tags: const [],
      savedPlaceIds: const [],
    );
  }

  Map<String, dynamic> _buildPublicUserFirestoreMap(UserModel model) {
    return {
      'id': model.id,
      'uid': model.id,
      'name': model.name,
      'username': model.username,
      'profileImageUrl': model.profileImageUrl,
      'photoUrl': model.profileImageUrl,
      'title': model.title,
      'bio': model.bio,
      'tags': model.tags,
      'recentImageUrls': model.recentImageUrls,
    };
  }

  Map<String, dynamic> _buildPrivateAccountFirestoreMap(UserModel model) {
    return {
      'email': model.email,
      'phoneNumber': model.phoneNumber,
      'notificationsEnabled': model.notificationsEnabled,
    };
  }

  DocumentReference<Map<String, dynamic>> _privateAccountRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('private')
        .doc('account');
  }

  Future<UserModel?> _readCachedUser(String userId) async {
    final cachedJson = await SecureStorageService.instance.read(
      CacheKeys.privateUserSession(userId),
    );
    if (cachedJson == null) return null;
    final cachedUser = UserModel.fromJson(cachedJson);
    return cachedUser.id == userId ? cachedUser : null;
  }

  Future<void> _cacheUser(UserModel user) async {
    final previousUid = await SecureStorageService.instance.read(
      CacheKeys.activeUserSessionUid,
    );
    if (previousUid != null && previousUid != user.id) {
      await SecureStorageService.instance.delete(
        CacheKeys.privateUserSession(previousUid),
      );
    }
    await SecureStorageService.instance.delete(CacheKeys.legacyUserSession);
    await SecureStorageService.instance.write(
      CacheKeys.privateUserSession(user.id),
      user.toJson(),
    );
    await SecureStorageService.instance.write(
      CacheKeys.activeUserSessionUid,
      user.id,
    );
  }

  Future<void> _clearCachedUser([String? userId]) async {
    final cachedUid =
        userId ??
        await SecureStorageService.instance.read(
          CacheKeys.activeUserSessionUid,
        );
    if (cachedUid != null && cachedUid.isNotEmpty) {
      await SecureStorageService.instance.delete(
        CacheKeys.privateUserSession(cachedUid),
      );
    }
    await SecureStorageService.instance.delete(CacheKeys.legacyUserSession);
    await SecureStorageService.instance.delete(CacheKeys.activeUserSessionUid);
  }

  Future<UserModel?> _loadCurrentUserProfile(fb.User firebaseUser) async {
    final publicSnapshot = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get()
        .timeout(const Duration(seconds: 4));
    if (!publicSnapshot.exists || publicSnapshot.data() == null) return null;

    final publicData = Map<String, dynamic>.from(publicSnapshot.data()!);
    final privateSnapshot = await _privateAccountRef(
      firebaseUser.uid,
    ).get().timeout(const Duration(seconds: 4));
    final privateData = privateSnapshot.data();

    publicData['id'] = firebaseUser.uid;
    publicData['uid'] = firebaseUser.uid;
    publicData['email'] =
        privateData?['email'] ?? publicData['email'] ?? firebaseUser.email;
    publicData['phoneNumber'] =
        privateData?['phoneNumber'] ?? publicData['phoneNumber'];
    publicData['notificationsEnabled'] =
        privateData?['notificationsEnabled'] ??
        publicData['notificationsEnabled'] ??
        true;
    return UserModel.fromMap(publicData);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) {
        try {
          await _clearCachedUser();
        } catch (_) {}
        return null;
      }

      // 1. Try cache first to avoid Firestore lookup if same user is logged in
      try {
        final cachedUser = await _readCachedUser(fbUser.uid);
        if (cachedUser != null) return cachedUser;
      } catch (e) {
        debugPrint('Error reading user session cache in authStateChanges: $e');
      }

      // 2. Fetch from Firestore
      try {
        final userModel = await _loadCurrentUserProfile(fbUser);
        if (userModel != null) {
          // Cache the profile and save last sync timestamp
          try {
            await _cacheUser(userModel);
            await LocalStorageService.instance.setString(
              CacheKeys.profileLastSync,
              DateTime.now().toIso8601String(),
            );
          } catch (_) {}
          return userModel;
        }
      } catch (e) {
        debugPrint('Error mapping authStateChanges from Firestore: $e');
      }

      // 3. Fallback: map from Firebase Auth
      final fallbackUser = _mapFirebaseUser(fbUser);
      try {
        await _cacheUser(fallbackUser);
      } catch (_) {}
      return fallbackUser;
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      try {
        await _clearCachedUser();
      } catch (_) {}
      return null;
    }

    // 1. Try cache first
    try {
      final cachedUser = await _readCachedUser(user.uid);
      if (cachedUser != null) return cachedUser;
    } catch (e) {
      debugPrint('Error reading user session cache in getCurrentUser: $e');
    }

    // 2. Fetch from Firestore
    try {
      final userModel = await _loadCurrentUserProfile(user);
      if (userModel != null) {
        try {
          await _cacheUser(userModel);
          await LocalStorageService.instance.setString(
            CacheKeys.profileLastSync,
            DateTime.now().toIso8601String(),
          );
        } catch (_) {}
        return userModel;
      }
    } catch (e) {
      debugPrint('Error getting current user from Firestore: $e');
    }

    // 3. Fallback: map from Firebase Auth
    final fallbackUser = _mapFirebaseUser(user);
    try {
      await _cacheUser(fallbackUser);
    } catch (_) {}
    return fallbackUser;
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
        final userModel = await _loadCurrentUserProfile(user);
        if (userModel != null) return userModel;
      } catch (e) {
        debugPrint(
          'Error fetching user profile from Firestore during login: $e',
        );
      }

      return _mapFirebaseUser(user);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_getLoginErrorMessage(e.code));
    } catch (e) {
      debugPrint('Login error: $e');
      final msg = e.toString();
      if (msg.contains('invalid-credential') ||
          msg.contains('INVALID_LOGIN_CREDENTIALS')) {
        throw Exception('Invalid email or password.');
      }
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
      final publicMap = _buildPublicUserFirestoreMap(userModel);
      final privateMap = _buildPrivateAccountFirestoreMap(userModel);
      publicMap['createdAt'] = FieldValue.serverTimestamp();
      privateMap['createdAt'] = FieldValue.serverTimestamp();

      try {
        final batch = _firestore.batch();
        batch.set(_firestore.collection('users').doc(user.uid), publicMap);
        batch.set(_privateAccountRef(user.uid), privateMap);
        await batch.commit().timeout(const Duration(seconds: 4));
      } catch (firestoreError) {
        debugPrint(
          'Error saving user profile to Firestore during signup: $firestoreError',
        );
        try {
          await _firebaseAuth.signOut();
        } catch (_) {}

        if (firestoreError.toString().contains('does not exist') ||
            firestoreError.toString().contains('disabled') ||
            firestoreError.toString().contains('TimeoutException') ||
            firestoreError.toString().contains('timeout')) {
          throw Exception(
            'Database services are currently unavailable. Please try again later.',
          );
        }
        throw Exception('Failed to create user profile. Please try again.');
      }

      return userModel;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_getSignupErrorMessage(e.code));
    } catch (e) {
      if (e.toString().contains('Database services') ||
          e.toString().contains('Failed to create user profile')) {
        rethrow;
      }
      throw Exception('An unexpected error occurred during sign up.');
    }
  }

  @override
  Future<void> logout() async {
    final userId = _firebaseAuth.currentUser?.uid;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _firebaseAuth.signOut();
    try {
      await _clearCachedUser(userId);
    } catch (_) {}
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null || currentUser.uid != user.id) {
        throw Exception('Please sign in to update your profile.');
      }

      final publicMap = _buildPublicUserFirestoreMap(user);
      final privateMap = _buildPrivateAccountFirestoreMap(user);
      publicMap['updatedAt'] = FieldValue.serverTimestamp();
      final privateAccountRef = _privateAccountRef(user.id);
      final privateAccountExists = (await privateAccountRef.get()).exists;
      if (privateAccountExists) {
        privateMap['updatedAt'] = FieldValue.serverTimestamp();
      } else {
        privateMap['createdAt'] = FieldValue.serverTimestamp();
      }
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('users').doc(user.id),
        publicMap,
        SetOptions(merge: true),
      );
      batch.set(privateAccountRef, privateMap, SetOptions(merge: true));
      await batch.commit().timeout(const Duration(seconds: 4));

      if (currentUser.displayName != user.name) {
        await currentUser.updateDisplayName(user.name);
      }

      await _cacheUser(user);
      await LocalStorageService.instance.setString(
        CacheKeys.profileLastSync,
        DateTime.now().toIso8601String(),
      );
      return user;
    } catch (e) {
      if (e.toString().contains('Please sign in')) rethrow;
      throw Exception('Failed to update profile. Please try again.');
    }
  }

  static const List<String> _googleScopes = ['email', 'profile'];

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      GoogleSignInClientAuthorization? clientAuth = await googleUser
          .authorizationClient
          .authorizationForScopes(_googleScopes);
      clientAuth ??= await googleUser.authorizationClient.authorizeScopes(
        _googleScopes,
      );

      final fb.AuthCredential credential = fb.GoogleAuthProvider.credential(
        accessToken: clientAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final fb.UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      final fb.User? user = userCredential.user;

      if (user == null) {
        throw fb.FirebaseAuthException(
          code: 'user-not-found',
          message: 'Sign in failed. User was null.',
        );
      }

      final docRef = _firestore.collection('users').doc(user.uid);
      UserModel userModel;

      try {
        final doc = await docRef.get().timeout(const Duration(seconds: 4));
        if (!doc.exists) {
          userModel = _mapFirebaseUser(user, name: user.displayName);
          final publicMap = _buildPublicUserFirestoreMap(userModel);
          final privateMap = _buildPrivateAccountFirestoreMap(userModel);
          publicMap['createdAt'] = FieldValue.serverTimestamp();
          privateMap['createdAt'] = FieldValue.serverTimestamp();
          final batch = _firestore.batch();
          batch.set(docRef, publicMap);
          batch.set(_privateAccountRef(user.uid), privateMap);
          await batch.commit().timeout(const Duration(seconds: 4));
        } else {
          userModel =
              await _loadCurrentUserProfile(user) ?? _mapFirebaseUser(user);
        }
      } catch (firestoreError) {
        debugPrint('Firestore error during Google Sign-In: $firestoreError');
        try {
          await _firebaseAuth.signOut();
        } catch (_) {}

        if (firestoreError.toString().contains('does not exist') ||
            firestoreError.toString().contains('disabled') ||
            firestoreError.toString().contains('TimeoutException') ||
            firestoreError.toString().contains('timeout')) {
          throw Exception(
            'Database services are currently unavailable. Please try again later.',
          );
        }
        throw Exception(
          'Failed to retrieve or create user profile. Please try again.',
        );
      }

      return userModel;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_getLoginErrorMessage(e.code));
    } catch (e) {
      debugPrint('Unexpected Google sign-in error: $e');
      if (e.toString().contains('Database services') ||
          e.toString().contains('Failed to retrieve or create user profile')) {
        rethrow;
      }
      if (e.toString().contains('sign_in_failed') ||
          e.toString().contains('api_exception') ||
          e.toString().contains('PlatformException')) {
        throw Exception(
          'Google Sign-In is not configured correctly on this device.',
        );
      }
      throw Exception('An unexpected error occurred during Google sign in.');
    }
  }

  // ————————————————————————————————————————————————————————————————
  // NEW PASSWORD RESET METHODS (Now correctly encapsulated inside class)
  // ————————————————————————————————————————————————————————————————
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_getResetErrorMessage(e.code));
    } catch (e) {
      throw Exception('An error occurred. Please try again.');
    }
  }

  String _getResetErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'invalid-email':
        return 'Invalid email format.';
      default:
        return 'Reset failed. Please try again.';
    }
  }

  String _getLoginErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network unavailable. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'sign_in_canceled':
        return 'Google sign in was canceled.';
      default:
        return 'Authentication failed. Please check your credentials.';
    }
  }

  String _getSignupErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'The email address is already registered.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'network-request-failed':
        return 'Network unavailable. Please try again.';
      case 'operation-not-allowed':
        return 'Email and password signup is not enabled. Please contact support.';
      default:
        return 'Sign up failed. Please check your information.';
    }
  }
} // End of FirebaseAuthRepository Class
