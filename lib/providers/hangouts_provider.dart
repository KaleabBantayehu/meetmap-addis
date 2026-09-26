import 'package:flutter/material.dart';
import '../core/repositories/hangout_repository.dart';
import '../core/repositories/repository_error_mapper.dart';
import '../core/storage/connectivity_service.dart';
import '../core/storage/local_storage_service.dart';
import '../shared/models/hangout_model.dart';

class HangoutsProvider with ChangeNotifier {
  final HangoutRepository _hangoutRepository;
  final bool Function() _isConnected;

  HangoutsProvider({
    required HangoutRepository hangoutRepository,
    bool Function()? isConnected,
  }) : _hangoutRepository = hangoutRepository,
       _isConnected =
           isConnected ?? (() => ConnectivityService.instance.isConnected) {
    _loadFromCache();
  }

  HangoutModel? _activeHangout;
  HangoutModel? get activeHangout => _activeHangout;

  List<HangoutModel> _quickHangouts = [];
  List<HangoutModel> get quickHangouts => _quickHangouts;

  List<VenueModel> _topPickVenues = [];
  List<VenueModel> get topPickVenues => _topPickVenues;

  List<ActivityModel> _recentActivities = [];
  List<ActivityModel> get recentActivities => _recentActivities;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  String? _nextCursor;
  int _requestGeneration = 0;
  final List<HangoutModel> _loadedHangouts = [];

  bool _isAdding = false;
  bool get isAdding => _isAdding;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _applyHangouts(List<HangoutModel> hangouts) {
    final activeHangouts = hangouts
        .where((hangout) => hangout.isActive)
        .toList();
    if (activeHangouts.isNotEmpty) {
      _activeHangout = activeHangouts.firstWhere(
        (h) => h.isLive,
        orElse: () => activeHangouts.first,
      );
      _quickHangouts = activeHangouts
          .where((h) => h.id != _activeHangout?.id)
          .toList();
    } else {
      _activeHangout = null;
      _quickHangouts = [];
    }
  }

  void _loadFromCache() {
    try {
      _applyHangouts(LocalStorageService.instance.getCachedHangouts());
      _topPickVenues = LocalStorageService.instance.getCachedVenues();
      _recentActivities = LocalStorageService.instance.getCachedActivities();
      if (_activeHangout != null ||
          _quickHangouts.isNotEmpty ||
          _topPickVenues.isNotEmpty ||
          _recentActivities.isNotEmpty) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached hangouts: $e');
    }
  }

  Future<void> fetchHangouts() async {
    final generation = ++_requestGeneration;
    if (_activeHangout == null && _quickHangouts.isEmpty) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isConnected()) {
        final page = await _hangoutRepository.getHangoutsPage();
        if (generation != _requestGeneration) return;
        _loadedHangouts
          ..clear()
          ..addAll(page.items);
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _applyHangouts(_loadedHangouts);
        _topPickVenues = await _hangoutRepository.getTopPickVenues();
        _recentActivities = await _hangoutRepository.getRecentActivities();
        await LocalStorageService.instance.saveCachedHangouts(_loadedHangouts);
        await LocalStorageService.instance.saveCachedVenues(_topPickVenues);
        await LocalStorageService.instance.saveCachedActivities(
          _recentActivities,
        );
      } else if (_activeHangout == null && _quickHangouts.isEmpty) {
        _loadFromCache();
      }
    } catch (e) {
      _errorMessage = cleanExceptionMessage(e, 'Failed to load hangouts');
      if (_activeHangout == null && _quickHangouts.isEmpty) _loadFromCache();
    } finally {
      if (generation == _requestGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreHangouts() async {
    if (_isLoadingMore || !_hasMore || !_isConnected()) {
      return;
    }
    final generation = _requestGeneration;
    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final page = await _hangoutRepository.getHangoutsPage(
        cursor: _nextCursor,
      );
      if (generation != _requestGeneration) {
        return;
      }
      final ids = _loadedHangouts.map((hangout) => hangout.id).toSet();
      _loadedHangouts.addAll(
        page.items.where((hangout) => hangout.isActive && ids.add(hangout.id)),
      );
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;
      _applyHangouts(_loadedHangouts);
      await LocalStorageService.instance.saveCachedHangouts(_loadedHangouts);
    } catch (e) {
      if (generation == _requestGeneration) {
        _errorMessage = cleanExceptionMessage(
          e,
          'Failed to load more hangouts',
        );
      }
    } finally {
      if (generation == _requestGeneration) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addHangout(HangoutModel hangout) async {
    if (_isAdding) return false;

    if (!_isConnected()) {
      _errorMessage = 'No internet connection';
      notifyListeners();
      return false;
    }

    try {
      _isAdding = true;
      _errorMessage = null;
      notifyListeners();

      final createdHangout = await _hangoutRepository.createHangout(hangout);
      _quickHangouts.insert(0, createdHangout);
      await LocalStorageService.instance.saveCachedHangouts(
        _activeHangout != null
            ? [_activeHangout!, ..._quickHangouts]
            : _quickHangouts,
      );

      _fetchHangoutsInBackground();

      return true;
    } catch (e) {
      _errorMessage = cleanExceptionMessage(e, 'Failed to create hangout');
      notifyListeners();
      return false;
    } finally {
      _isAdding = false;
      notifyListeners();
    }
  }

  void _fetchHangoutsInBackground() {
    fetchHangouts().catchError((e) {
      debugPrint('Background hangout refresh failed: $e');
    });
  }
}
