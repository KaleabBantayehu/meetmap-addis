import 'package:flutter/material.dart';
import '../core/repositories/hangout_repository.dart';
import '../shared/models/hangout_model.dart';

class HangoutsProvider with ChangeNotifier {
  final HangoutRepository _hangoutRepository;

  HangoutsProvider({required HangoutRepository hangoutRepository})
    : _hangoutRepository = hangoutRepository;

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

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchHangouts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final allHangouts = await _hangoutRepository.getHangouts();
      if (allHangouts.isNotEmpty) {
        _activeHangout = allHangouts.firstWhere(
          (h) => h.isLive,
          orElse: () => allHangouts.first,
        );
        _quickHangouts = allHangouts
            .where((h) => h.id != _activeHangout?.id)
            .toList();
      } else {
        _activeHangout = null;
        _quickHangouts = [];
      }
      _topPickVenues = await _hangoutRepository.getTopPickVenues();
      _recentActivities = await _hangoutRepository.getRecentActivities();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
