import 'package:flutter/material.dart';
import '../core/repositories/event_repository.dart';
import '../shared/models/event_model.dart';

class EventsProvider with ChangeNotifier {
  final EventRepository _eventRepository;

  EventsProvider({required EventRepository eventRepository})
      : _eventRepository = eventRepository;

  List<EventModel> _events = [];
  List<EventModel> get events => _events;

  EventModel? _featuredEvent;
  EventModel? get featuredEvent => _featuredEvent;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _eventRepository.getEvents();
      _featuredEvent = await _eventRepository.getFeaturedEvent();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
