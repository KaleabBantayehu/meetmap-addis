import '../../shared/models/event_model.dart';
import 'page_result.dart';

abstract class EventRepository {
  Future<List<EventModel>> getEvents();
  Future<PageResult<EventModel>> getEventsPage({
    String? cursor,
    int limit = 20,
  });
  Future<EventModel?> getFeaturedEvent();
  Future<EventModel> createEvent(EventModel event);
}
