import '../../../shared/data/mock_hangouts.dart';
import '../../../shared/models/hangout_model.dart';
import '../hangout_repository.dart';
import '../page_result.dart';

class MockHangoutRepository implements HangoutRepository {
  late final List<HangoutModel> _hangouts = [activeHangout, ...quickHangouts];
  int _idCounter = 100;

  @override
  Future<List<HangoutModel>> getHangouts() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_hangouts);
  }

  @override
  Future<PageResult<HangoutModel>> getHangoutsPage({
    String? cursor,
    int limit = 20,
  }) async {
    final active = _hangouts.where((hangout) => hangout.isActive).toList();
    final start = cursor == null
        ? 0
        : active.indexWhere((h) => h.id == cursor) + 1;
    final safeStart = start < 0 ? 0 : start;
    final items = active.skip(safeStart).take(limit).toList();
    return PageResult(
      items: items,
      nextCursor: items.isEmpty ? null : items.last.id,
      hasMore: safeStart + items.length < active.length,
    );
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
