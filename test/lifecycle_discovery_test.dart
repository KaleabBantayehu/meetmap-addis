import 'package:flutter_test/flutter_test.dart';
import 'package:meetmap_addis/core/repositories/mock/mock_event_repository.dart';
import 'package:meetmap_addis/core/repositories/mock/mock_hangout_repository.dart';
import 'package:meetmap_addis/core/storage/local_storage_service.dart';
import 'package:meetmap_addis/providers/events_provider.dart';
import 'package:meetmap_addis/providers/hangouts_provider.dart';
import 'package:meetmap_addis/shared/models/event_model.dart';
import 'package:meetmap_addis/shared/models/hangout_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  tearDown(() async {
    await LocalStorageService.instance.saveCachedEvents(const []);
    await LocalStorageService.instance.saveCachedHangouts(const []);
  });

  test('legacy lifecycle fields remain active when deserialized', () {
    expect(EventModel.fromMap(_eventMap()).isActive, isTrue);
    expect(HangoutModel.fromMap(_hangoutMap()).isActive, isTrue);
  });

  test('cached archived events cannot re-enter active discovery', () async {
    await LocalStorageService.instance.saveCachedEvents([
      EventModel.fromMap({..._eventMap(), 'id': 'active'}),
      EventModel.fromMap({
        ..._eventMap(),
        'id': 'archived',
        'lifecycleStatus': 'archived',
      }),
    ]);

    final provider = EventsProvider(
      eventRepository: MockEventRepository(),
      isConnected: () => false,
    );
    expect(provider.events.map((event) => event.id), ['active']);
    provider.dispose();
  });

  test('cached inactive hangouts cannot re-enter active discovery', () async {
    await LocalStorageService.instance.saveCachedHangouts([
      HangoutModel.fromMap({..._hangoutMap(), 'id': 'active'}),
      HangoutModel.fromMap({
        ..._hangoutMap(),
        'id': 'inactive',
        'lifecycleStatus': 'inactive',
      }),
    ]);

    final provider = HangoutsProvider(
      hangoutRepository: MockHangoutRepository(),
      isConnected: () => false,
    );
    final visibleIds = [
      if (provider.activeHangout != null) provider.activeHangout!.id,
      ...provider.quickHangouts.map((hangout) => hangout.id),
    ];
    expect(visibleIds, ['active']);
    provider.dispose();
  });
}

Map<String, dynamic> _eventMap() => {
  'id': 'legacy',
  'title': 'Event',
  'category': 'Community',
  'location': 'Addis Ababa',
  'date': 'September 30',
  'time': '6:00 PM',
  'host': 'Host',
  'imageUrl': '',
  'description': 'Description',
};

Map<String, dynamic> _hangoutMap() => {
  'id': 'legacy',
  'title': 'Hangout',
  'category': 'Social',
  'location': 'Addis Ababa',
  'time': '6:00 PM',
  'imageUrl': '',
  'description': 'Description',
};
