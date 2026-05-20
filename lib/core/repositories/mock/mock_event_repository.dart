import '../../../shared/data/mock_events.dart';
import '../../../shared/models/event_model.dart';
import '../event_repository.dart';

class MockEventRepository implements EventRepository {
  final List<EventModel> _events = List.from(mockEvents);
  final EventModel _featured = featuredEvent;

  @override
  Future<List<EventModel>> getEvents() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_events);
  }

  @override
  Future<EventModel?> getFeaturedEvent() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _featured;
  }
}
