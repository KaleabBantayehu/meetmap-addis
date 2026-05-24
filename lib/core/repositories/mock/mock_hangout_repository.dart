import '../../../shared/data/mock_hangouts.dart';
import '../../../shared/models/hangout_model.dart';
import '../hangout_repository.dart';

class MockHangoutRepository implements HangoutRepository {
  late final List<HangoutModel> _hangouts = [activeHangout, ...quickHangouts];
  int _idCounter = 100;

  @override
  Future<List<HangoutModel>> getHangouts() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_hangouts);
  }

  @override
  Future<List<VenueModel>> getTopPickVenues() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(topPickVenues);
  }

  @override
  Future<List<ActivityModel>> getRecentActivities() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(recentActivities);
  }

  @override
  Future<HangoutModel> createHangout(HangoutModel hangout) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newHangout = hangout.copyWith(id: 'mock_hangout_${_idCounter++}');
    _hangouts.add(newHangout);
    return newHangout;
  }
}
