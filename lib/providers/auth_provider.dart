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
  int _sessionGeneration = 0;
  Future<void> _authMutationChain = Future<void>.value();
  int _pendingAuthMutations = 0;
  bool _hasDeferredAuthState = false;
  UserModel? _deferredAuthState;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null;

  void initializeAuth() {
    _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen(
      (user) {
        if (_authRepository.currentUserId != user?.id) return;
        if (_pendingAuthMutations > 0) {
          _hasDeferredAuthState = true;
          _deferredAuthState = user;
          return;
        }
        _applyAuthState(user);
      },
      onError: (error) {
        _sessionGeneration++;
        _errorMessage = error.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> loginWithEmail(String email, String password) async {
    final generation = ++_sessionGeneration;
    return _serializeAuthMutation(() async {
      _errorMessage = null;
      notifyListeners();

      try {
        final user = await _authRepository.login(email, password);
        return _applyCompletedUser(user, generation);
      } catch (e) {
        if (!_isCurrentGeneration(generation)) return false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        return false;
      }
    });
  }

  Future<bool> signupWithEmail(
    String email,
    String password,
    String name,
  ) async {
    final generation = ++_sessionGeneration;
    return _serializeAuthMutation(() async {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      try {
        final user = await _authRepository.signup(email, password, name);
        return _applyCompletedUser(user, generation);
      } catch (e) {
        if (!_isCurrentGeneration(generation)) return false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        return false;
      } finally {
        if (_isCurrentGeneration(generation)) {
          _isLoading = false;
          notifyListeners();
        }
      }
    });
  }

  Future<void> signOut() async {
    final generation = ++_sessionGeneration;
    return _serializeAuthMutation(() async {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      try {
        await _authRepository.logout();
        if (_isCurrentGeneration(generation) &&
            _authRepository.currentUserId == null) {
          _currentUser = null;
        }
      } catch (e) {
        if (!_isCurrentGeneration(generation)) return;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      } finally {
        if (_isCurrentGeneration(generation)) {
          _isLoading = false;
          notifyListeners();
        }
      }
    });
  }

  Future<bool> loginWithGoogle() async {
    final generation = ++_sessionGeneration;
    return _serializeAuthMutation(() async {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      try {
        final user = await _authRepository.signInWithGoogle();
        return _applyCompletedUser(user, generation);
      } catch (e) {
        if (!_isCurrentGeneration(generation)) return false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        return false;
      } finally {
        if (_isCurrentGeneration(generation)) {
          _isLoading = false;
          notifyListeners();
        }
      }
    });
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
    final generation = ++_sessionGeneration;
    return _serializeAuthMutation(() async {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      try {
        await _authRepository.deleteAccount();
        if (!_isCurrentGeneration(generation) ||
            _authRepository.currentUserId != null) {
          return false;
        }
        _currentUser = null;
        return true;
      } catch (error) {
        if (!_isCurrentGeneration(generation)) return false;
        _errorMessage = error.toString().replaceAll('Exception: ', '');
        return false;
      } finally {
        if (_isCurrentGeneration(generation)) {
          _isLoading = false;
          notifyListeners();
        }
      }
    });
  }

  Future<void> checkCurrentUser() async {
    final generation = ++_sessionGeneration;
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _authRepository.getCurrentUser();
      if (_pendingAuthMutations == 0 && _isCurrentResult(user, generation)) {
        _currentUser = user;
      }
    } catch (e) {
      if (!_isCurrentGeneration(generation)) return;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (_isCurrentGeneration(generation)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> updateProfile(UserModel user) async {
    final generation = ++_sessionGeneration;
    return _serializeAuthMutation(() async {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      try {
        final updatedUser = await _authRepository.updateProfile(user);
        return _applyCompletedUser(updatedUser, generation);
      } catch (e) {
        if (!_isCurrentGeneration(generation)) return false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        return false;
      } finally {
        if (_isCurrentGeneration(generation)) {
          _isLoading = false;
          notifyListeners();
        }
      }
    });
  }

  Future<T> _serializeAuthMutation<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _pendingAuthMutations++;
    _authMutationChain = _authMutationChain.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        _pendingAuthMutations--;
        if (_pendingAuthMutations == 0) {
          if (_hasDeferredAuthState &&
              _authRepository.currentUserId == _deferredAuthState?.id) {
            _applyAuthState(_deferredAuthState);
          }
          _hasDeferredAuthState = false;
          _deferredAuthState = null;
          _reconcileAuthoritativeSession();
        }
      }
    });
    return completer.future;
  }

  Future<void> _reconcileAuthoritativeSession() async {
    final generation = _sessionGeneration;
    try {
      final user = await _authRepository.getCurrentUser();
      if (_pendingAuthMutations > 0 || !_isCurrentResult(user, generation)) {
        return;
      }
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      // The initiating operation already reports its own user-facing failure.
    }
  }

  void _applyAuthState(UserModel? user) {
    _sessionGeneration++;
    _currentUser = user;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  bool _applyCompletedUser(UserModel user, int generation) {
    if (_isCurrentResult(user, generation)) {
      _currentUser = user;
      return true;
    }
    return _currentUser?.id == user.id &&
        _authRepository.currentUserId == user.id;
  }

  bool _isCurrentResult(UserModel? user, int generation) =>
      _isCurrentGeneration(generation) &&
      _authRepository.currentUserId == user?.id;

  bool _isCurrentGeneration(int generation) => _sessionGeneration == generation;

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
} // End of AuthProvider Class
