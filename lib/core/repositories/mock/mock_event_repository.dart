import '../../../shared/data/mock_events.dart';
import '../../../shared/models/event_model.dart';
import '../event_repository.dart';
import '../page_result.dart';

class MockEventRepository implements EventRepository {
  final List<EventModel> _events = List.from(mockEvents);
  final EventModel _featured = featuredEvent;
  int _idCounter = 100;

  @override
  Future<List<EventModel>> getEvents() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_events);
  }

  @override
  Future<PageResult<EventModel>> getEventsPage({
    String? cursor,
    int limit = 20,
  }) async {
    final active = _events.where((event) => event.isActive).toList();
    final start = cursor == null
        ? 0
        : active.indexWhere((e) => e.id == cursor) + 1;
    final safeStart = start < 0 ? 0 : start;
    final items = active.skip(safeStart).take(limit).toList();
    return PageResult(
      items: items,
      nextCursor: items.isEmpty ? null : items.last.id,
      hasMore: safeStart + items.length < active.length,
    );
  }

  @override
  Future<EventModel?> getFeaturedEvent() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _featured;
  }

  @override
  Future<EventModel> createEvent(EventModel event) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newEvent = event.copyWith(id: 'mock_event_${_idCounter++}');
    _events.add(newEvent);
    return newEvent;
  }
}
