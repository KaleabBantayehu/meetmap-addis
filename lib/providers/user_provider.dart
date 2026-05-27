import 'package:flutter/material.dart';
import '../core/repositories/user_repository.dart';
import '../shared/models/user_model.dart';

/// Caches and exposes public user profiles by userId.
/// Call [fetchUser] before reading [getUser].
class UserProvider with ChangeNotifier {
  UserProvider({required UserRepository userRepository})
      : _userRepository = userRepository;

  final UserRepository _userRepository;

  final Map<String, UserModel> _cache = {};
  final Set<String> _loading = {};
  final Map<String, String?> _errors = {};

  UserModel? getUser(String userId) => _cache[userId];
  bool isLoading(String userId) => _loading.contains(userId);
  String? getError(String userId) => _errors[userId];

  /// Fetches user by [userId] from repository if not already cached.
  Future<void> fetchUser(String userId) async {
    if (userId.isEmpty ||
        _cache.containsKey(userId) ||
        _loading.contains(userId)) {
      return;
    }

    _loading.add(userId);
    _errors.remove(userId);
    notifyListeners();

    try {
      final user = await _userRepository.getUserById(userId);
      if (user != null) {
        _cache[userId] = user;
      } else {
        _errors[userId] = 'User not found.';
      }
    } catch (_) {
      _errors[userId] = 'Failed to load user profile.';
    } finally {
      _loading.remove(userId);
      notifyListeners();
    }
  }

  /// Force-refreshes a user profile, bypassing the cache.
  Future<void> refreshUser(String userId) async {
    _cache.remove(userId);
    await fetchUser(userId);
  }
}
