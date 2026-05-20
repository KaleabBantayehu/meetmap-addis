import '../../shared/models/event_model.dart';

abstract class EventRepository {
  Future<List<EventModel>> getEvents();
  Future<EventModel?> getFeaturedEvent();
}
