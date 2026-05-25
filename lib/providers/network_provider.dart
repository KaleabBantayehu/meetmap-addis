import 'package:flutter/material.dart';
import '../core/repositories/network_repository.dart';
import '../core/repositories/repository_error_mapper.dart';
import '../core/storage/connectivity_service.dart';
import '../core/storage/local_storage_service.dart';
import '../shared/models/user_model.dart';

class NetworkProvider with ChangeNotifier {
  final NetworkRepository _networkRepository;

  NetworkProvider({required NetworkRepository networkRepository})
    : _networkRepository = networkRepository {
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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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
    if (_suggestedUsers.isEmpty && _trendingReviewers.isEmpty) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      if (ConnectivityService.instance.isConnected) {
        _suggestedUsers = await _networkRepository.getSuggestedUsers();
        _trendingReviewers = await _networkRepository.getTrendingReviewers();
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
      _errorMessage = cleanExceptionMessage(e, 'Failed to load network data');
      if (_suggestedUsers.isEmpty && _trendingReviewers.isEmpty) {
        _loadFromCache();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<void> loadFollowState(String currentUserId) async {
    final allUsers = [..._suggestedUsers, ..._trendingReviewers];
    for (final user in allUsers) {
      if (user.id.isEmpty || user.id == currentUserId) continue;
      try {
        final isFollowingUser = await _networkRepository.isFollowing(
          currentUserId,
          user.id,
        );
        if (isFollowingUser) {
          _followingUserIds.add(user.id);
        } else {
          _followingUserIds.remove(user.id);
        }
        final count = await _networkRepository.getFollowerCount(user.id);
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
      await _refreshFollowerCount(targetId);
      return true;
    } catch (e) {
      if (wasFollowing) {
        _followingUserIds.add(targetId);
      } else {
        _followingUserIds.remove(targetId);
      }
      _followerCounts[targetId] = previousCount;
      _errorMessage = cleanExceptionMessage(e, 'Unable to update follow status');
      return false;
    } finally {
      _followActionInProgress.remove(targetId);
      notifyListeners();
    }
  }

  Future<void> _refreshFollowerCount(String userId) async {
    try {
      final count = await _networkRepository.getFollowerCount(userId);
      _followerCounts[userId] = count;
    } catch (_) {}
  }

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
