import 'package:flutter/material.dart';
import '../core/repositories/network_repository.dart';
import '../shared/models/user_model.dart';

class NetworkProvider with ChangeNotifier {
  final NetworkRepository _networkRepository;

  NetworkProvider({required NetworkRepository networkRepository})
      : _networkRepository = networkRepository;

  List<UserModel> _suggestedUsers = [];
  List<UserModel> get suggestedUsers => _suggestedUsers;

  List<UserModel> _trendingReviewers = [];
  List<UserModel> get trendingReviewers => _trendingReviewers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNetworkData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _suggestedUsers = await _networkRepository.getSuggestedUsers();
      _trendingReviewers = await _networkRepository.getTrendingReviewers();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
