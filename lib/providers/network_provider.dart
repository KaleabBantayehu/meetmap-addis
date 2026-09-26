import 'package:flutter/material.dart';
import '../core/repositories/network_repository.dart';
import '../core/repositories/repository_error_mapper.dart';
import '../core/storage/connectivity_service.dart';
import '../core/storage/local_storage_service.dart';
import '../shared/models/user_model.dart';

class NetworkProvider with ChangeNotifier {
  final NetworkRepository _networkRepository;
  final bool Function() _isConnected;

  NetworkProvider({
    required NetworkRepository networkRepository,
    bool Function()? isConnected,
  }) : _networkRepository = networkRepository,
       _isConnected =
           isConnected ?? (() => ConnectivityService.instance.isConnected) {
    _loadFromCache();
  }

  List<UserModel> _suggestedUsers = [];
  List<UserModel> get suggestedUsers => _suggestedUsers;

  List<UserModel> _trendingReviewers = [];
  List<UserModel> get trendingReviewers => _trendingReviewers;
  List<UserModel> _searchResults = [];
  List<UserModel> get searchResults => _searchResults;
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  final Set<String> _followingUserIds = <String>{};
  final Set<String> _followActionInProgress = <String>{};
  final Map<String, int> _followerCounts = <String, int>{};
  final Map<String, int> _followingCounts = <String, int>{};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? _sessionUserId;
  int _sessionGeneration = 0;

  void syncSession(String? userId) {
    if (_sessionUserId == userId) return;
    _sessionGeneration++;
    _sessionUserId = userId;
    _followingUserIds.clear();
    _followActionInProgress.clear();
    _followerCounts.clear();
    _followingCounts.clear();
    _searchQuery = '';
    _searchResults = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  bool get hasActiveSearch => _searchQuery.trim().isNotEmpty;

  void _loadFromCache() {
    try {
      _suggestedUsers = LocalStorageService.instance.getCachedSuggestedUsers();
      _trendingReviewers = LocalStorageService.instance
          .getCachedTrendingReviewers();
      if (_suggestedUsers.isNotEmpty || _trendingReviewers.isNotEmpty) {
        _applySearch();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached network data: $e');
    }
  }

  Future<void> fetchNetworkData() async {
    final generation = _sessionGeneration;
    if (_suggestedUsers.isEmpty && _trendingReviewers.isEmpty) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isConnected()) {
        final suggestedUsers = await _networkRepository.getSuggestedUsers();
        if (!_isCurrentGeneration(generation)) return;
        final trendingReviewers = await _networkRepository
            .getTrendingReviewers();
        if (!_isCurrentGeneration(generation)) return;
        _suggestedUsers = suggestedUsers;
        _trendingReviewers = trendingReviewers;
        await LocalStorageService.instance.saveCachedSuggestedUsers(
          _suggestedUsers,
        );
        await LocalStorageService.instance.saveCachedTrendingReviewers(
          _trendingReviewers,
        );
        _applySearch();
      } else if (_suggestedUsers.isEmpty && _trendingReviewers.isEmpty) {
        _loadFromCache();
      }
    } catch (e) {
      if (!_isCurrentGeneration(generation)) return;
      _errorMessage = cleanExceptionMessage(e, 'Failed to load network data');
      if (_suggestedUsers.isEmpty && _trendingReviewers.isEmpty) {
        _loadFromCache();
      }
    } finally {
      if (_isCurrentGeneration(generation)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> searchUsers(String query) async {
    _searchQuery = query.trim();
    _errorMessage = null;
    _applySearch();
    notifyListeners();
  }

  bool isFollowing(String userId) => _followingUserIds.contains(userId);

  bool isFollowActionInProgress(String userId) =>
      _followActionInProgress.contains(userId);

  int followerCountFor(UserModel user) =>
      _followerCounts[user.id] ?? user.followerCount;

  int followingCountFor(UserModel user) =>
      _followingCounts[user.id] ?? user.followingCount;

  Future<void> loadProfileCounts(
    String userId, {
    required bool includeFollowing,
  }) async {
    if (userId.isEmpty) return;
    final generation = _sessionGeneration;
    try {
      final followerCount = await _networkRepository.getFollowerCount(userId);
      if (!_isCurrentGeneration(generation)) return;
      _followerCounts[userId] = followerCount;
      if (includeFollowing) {
        final followingCount = await _networkRepository.getFollowingCount(
          userId,
        );
        if (!_isCurrentGeneration(generation)) return;
        _followingCounts[userId] = followingCount;
      }
      notifyListeners();
    } catch (e) {
      if (!_isCurrentGeneration(generation)) return;
      _errorMessage = cleanExceptionMessage(e, 'Unable to load profile counts');
      notifyListeners();
    }
  }

  Future<void> loadFollowState(String currentUserId) async {
    final generation = _sessionGeneration;
    if (_sessionUserId != currentUserId) return;
    final allUsers = [..._suggestedUsers, ..._trendingReviewers];
    for (final user in allUsers) {
      if (user.id.isEmpty || user.id == currentUserId) continue;
      try {
        final isFollowingUser = await _networkRepository.isFollowing(
          currentUserId,
          user.id,
        );
        if (!_isCurrentSession(currentUserId, generation)) return;
        if (isFollowingUser) {
          _followingUserIds.add(user.id);
        } else {
          _followingUserIds.remove(user.id);
        }
        final count = await _networkRepository.getFollowerCount(user.id);
        if (!_isCurrentSession(currentUserId, generation)) return;
        _followerCounts[user.id] = count;
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<bool> toggleFollow({
    required String currentUserId,
    required UserModel targetUser,
  }) async {
    final targetId = targetUser.id;
    if (targetId.isEmpty ||
        targetId == currentUserId ||
        _followActionInProgress.contains(targetId)) {
      return false;
    }
    final generation = _sessionGeneration;
    if (_sessionUserId != currentUserId) return false;

    final wasFollowing = _followingUserIds.contains(targetId);
    final previousCount = followerCountFor(targetUser);
    _followActionInProgress.add(targetId);
    if (wasFollowing) {
      _followingUserIds.remove(targetId);
      _followerCounts[targetId] = previousCount > 0 ? previousCount - 1 : 0;
    } else {
      _followingUserIds.add(targetId);
      _followerCounts[targetId] = previousCount + 1;
    }
    notifyListeners();

    try {
      if (wasFollowing) {
        await _networkRepository.unfollowUser(currentUserId, targetId);
      } else {
        await _networkRepository.followUser(currentUserId, targetId);
      }
      if (!_isCurrentSession(currentUserId, generation)) return false;
      await _refreshFollowerCount(targetId, generation);
      if (!_isCurrentSession(currentUserId, generation)) return false;
      return true;
    } catch (e) {
      if (!_isCurrentSession(currentUserId, generation)) return false;
      if (wasFollowing) {
        _followingUserIds.add(targetId);
      } else {
        _followingUserIds.remove(targetId);
      }
      _followerCounts[targetId] = previousCount;
      _errorMessage = cleanExceptionMessage(
        e,
        'Unable to update follow status',
      );
      return false;
    } finally {
      if (_isCurrentSession(currentUserId, generation)) {
        _followActionInProgress.remove(targetId);
        notifyListeners();
      }
    }
  }

  Future<void> _refreshFollowerCount(String userId, int generation) async {
    try {
      final count = await _networkRepository.getFollowerCount(userId);
      if (!_isCurrentGeneration(generation)) return;
      _followerCounts[userId] = count;
    } catch (_) {}
  }

  bool _isCurrentGeneration(int generation) => _sessionGeneration == generation;

  bool _isCurrentSession(String userId, int generation) =>
      _sessionUserId == userId && _isCurrentGeneration(generation);

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _searchResults = [];
      return;
    }
    final query = _searchQuery.toLowerCase();
    final seenIds = <String>{};
    final allUsers = [..._suggestedUsers, ..._trendingReviewers];
    _searchResults = allUsers.where((user) {
      if (user.id.isNotEmpty && !seenIds.add(user.id)) {
        return false;
      }
      final username = (user.username ?? '').toLowerCase();
      final displayName = user.name.toLowerCase();
      final bio = (user.bio ?? '').toLowerCase();
      return username.contains(query) ||
          displayName.contains(query) ||
          bio.contains(query);
    }).toList();
  }
}
