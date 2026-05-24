import 'package:flutter/material.dart';
import '../core/repositories/event_repository.dart';
import '../core/repositories/repository_error_mapper.dart';
import '../core/storage/connectivity_service.dart';
import '../core/storage/local_storage_service.dart';
import '../shared/models/event_model.dart';

class EventsProvider with ChangeNotifier {
  final EventRepository _eventRepository;

  EventsProvider({required EventRepository eventRepository})
    : _eventRepository = eventRepository {
    _loadFromCache();
  }

  List<EventModel> _events = [];
  List<EventModel> get events => _events;

  EventModel? _featuredEvent;
  EventModel? get featuredEvent => _featuredEvent;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAdding = false;
  bool get isAdding => _isAdding;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _loadFromCache() {
    try {
      _events = LocalStorageService.instance.getCachedEvents();
      _featuredEvent = _firstFeaturedEvent(_events);
      if (_events.isNotEmpty) notifyListeners();
    } catch (e) {
      debugPrint('Error loading cached events: $e');
    }
  }

  Future<void> fetchEvents() async {
    if (_events.isEmpty) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      if (ConnectivityService.instance.isConnected) {
        _events = await _eventRepository.getEvents();
        _featuredEvent =
            await _eventRepository.getFeaturedEvent() ??
            _firstFeaturedEvent(_events);
        await LocalStorageService.instance.saveCachedEvents(_events);
      } else if (_events.isEmpty) {
        _loadFromCache();
      }
    } catch (e) {
      _errorMessage = cleanExceptionMessage(e, 'Failed to load events');
      if (_events.isEmpty) _loadFromCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  EventModel? _firstFeaturedEvent(List<EventModel> events) {
    for (final event in events) {
      if (event.isFeatured) return event;
    }
    return null;
  }

  Future<bool> addEvent(EventModel event) async {
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

      final createdEvent = await _eventRepository.createEvent(event);
      _events.insert(0, createdEvent);
      await LocalStorageService.instance.saveCachedEvents(_events);

      _fetchEventsInBackground();

      return true;
    } catch (e) {
      _errorMessage = cleanExceptionMessage(e, 'Failed to create event');
      notifyListeners();
      return false;
    } finally {
      _isAdding = false;
      notifyListeners();
    }
  }

  void _fetchEventsInBackground() {
    fetchEvents().catchError((e) {
      debugPrint('Background event refresh failed: $e');
    });
  }
}
