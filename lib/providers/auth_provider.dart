import 'dart:async';
import 'package:flutter/material.dart';
import '../core/repositories/auth_repository.dart';
import '../shared/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  StreamSubscription<UserModel?>? _authSubscription;

  AuthProvider({required AuthRepository authRepository})
    : _authRepository = authRepository {
    initializeAuth();
  }

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null;

  void initializeAuth() {
    _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen(
      (user) {
        _currentUser = user;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> loginWithEmail(String email, String password) async {
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.login(email, password);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  Future<bool> signupWithEmail(
    String email,
    String password,
    String name,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.signup(email, password, name);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.logout();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.signInWithGoogle();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ————————————————————————————————————————————————————————————————
  // FORGOT PASSWORD PROVIDER METHOD (Now safely tucked inside the class)
  // ————————————————————————————————————————————————————————————————
  Future<String?> resetPassword(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
      return null; // Null means success (no error)
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Backward compatibility wrappers to ensure zero compilation breaks
  Future<bool> login(String email, String password) =>
      loginWithEmail(email, password);
  Future<bool> signup(String email, String password, String name) =>
      signupWithEmail(email, password, name);
  Future<void> logout() => signOut();

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepository.deleteAccount();
      _currentUser = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authRepository.getCurrentUser();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(UserModel user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.updateProfile(user);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
} // End of AuthProvider Class
