import 'package:flutter/material.dart';
import '../core/repositories/hangout_repository.dart';
import '../core/repositories/repository_error_mapper.dart';
import '../core/storage/connectivity_service.dart';
import '../core/storage/local_storage_service.dart';
import '../shared/models/hangout_model.dart';

class HangoutsProvider with ChangeNotifier {
  final HangoutRepository _hangoutRepository;

  HangoutsProvider({required HangoutRepository hangoutRepository})
    : _hangoutRepository = hangoutRepository {
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
    if (_activeHangout == null && _quickHangouts.isEmpty) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      if (ConnectivityService.instance.isConnected) {
        final allHangouts = await _hangoutRepository.getHangouts();
        _applyHangouts(allHangouts);
        _topPickVenues = await _hangoutRepository.getTopPickVenues();
        _recentActivities = await _hangoutRepository.getRecentActivities();
        await LocalStorageService.instance.saveCachedHangouts(allHangouts);
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
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addHangout(HangoutModel hangout) async {
    if (_isAdding) return false;

    if (!ConnectivityService.instance.isConnected) {
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
