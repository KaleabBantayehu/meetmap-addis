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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _loadFromCache() {
    try {
      _suggestedUsers = LocalStorageService.instance.getCachedSuggestedUsers();
      _trendingReviewers = LocalStorageService.instance
          .getCachedTrendingReviewers();
      if (_suggestedUsers.isNotEmpty || _trendingReviewers.isNotEmpty) {
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
}
