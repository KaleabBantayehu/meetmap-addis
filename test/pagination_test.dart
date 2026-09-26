import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meetmap_addis/core/repositories/page_result.dart';
import 'package:meetmap_addis/core/repositories/mock/mock_auth_repository.dart';
import 'package:meetmap_addis/core/repositories/mock/mock_event_repository.dart';
import 'package:meetmap_addis/core/repositories/mock/mock_hangout_repository.dart';
import 'package:meetmap_addis/core/repositories/mock/mock_place_repository.dart';
import 'package:meetmap_addis/core/repositories/mock/mock_review_repository.dart';
import 'package:meetmap_addis/core/storage/local_storage_service.dart';
import 'package:meetmap_addis/providers/auth_provider.dart';
import 'package:meetmap_addis/providers/events_provider.dart';
import 'package:meetmap_addis/providers/hangouts_provider.dart';
import 'package:meetmap_addis/providers/places_provider.dart';
import 'package:meetmap_addis/providers/reviews_provider.dart';
import 'package:meetmap_addis/shared/models/event_model.dart';
import 'package:meetmap_addis/shared/models/hangout_model.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:meetmap_addis/shared/models/review_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  test('places append pages and suppress duplicate load-more work', () async {
    final repository = _ControlledPlaceRepository();
    final provider = PlacesProvider(
      placeRepository: repository,
      isConnected: () => true,
    );

    final initial = provider.fetchPlaces();
    repository.requests.single.complete(
      PageResult(items: [_place('1')], nextCursor: '1', hasMore: true),
    );
    await initial;

    final firstLoadMore = provider.loadMorePlaces();
    final duplicateLoadMore = provider.loadMorePlaces();
    expect(repository.requests, hasLength(2));
    repository.requests.last.complete(
      PageResult(items: [_place('2')], nextCursor: '2', hasMore: false),
    );
    await Future.wait([firstLoadMore, duplicateLoadMore]);

    expect(provider.places.map((place) => place.id), ['1', '2']);
    expect(provider.hasMore, isFalse);
    await provider.loadMorePlaces();
    expect(repository.requests, hasLength(2));
    provider.dispose();
  });

  test('stale place page cannot overwrite a newer refresh', () async {
    final repository = _ControlledPlaceRepository();
    final provider = PlacesProvider(
      placeRepository: repository,
      isConnected: () => true,
    );
    final oldRequest = provider.fetchPlaces();
    final newRequest = provider.fetchPlaces();
    repository.requests[1].complete(
      PageResult(items: [_place('new')], nextCursor: null, hasMore: false),
    );
    await newRequest;
    repository.requests[0].complete(
      PageResult(items: [_place('old')], nextCursor: null, hasMore: false),
    );
    await oldRequest;
    expect(provider.places.single.id, 'new');
    provider.dispose();
  });

  test('event pagination excludes archived events', () async {
    final provider = EventsProvider(
      eventRepository: _PagedEventRepository(),
      isConnected: () => true,
    );
    await provider.fetchEvents();
    expect(provider.events.map((event) => event.id), ['active-1']);
    await provider.loadMoreEvents();
    expect(provider.events.map((event) => event.id), ['active-1', 'active-2']);
    provider.dispose();
  });

  test('hangout pagination excludes inactive hangouts', () async {
    final provider = HangoutsProvider(
      hangoutRepository: _PagedHangoutRepository(),
      isConnected: () => true,
    );
    await provider.fetchHangouts();
    await provider.loadMoreHangouts();
    final ids = [
      if (provider.activeHangout != null) provider.activeHangout!.id,
      ...provider.quickHangouts.map((hangout) => hangout.id),
    ];
    expect(ids, ['active-1', 'active-2']);
    provider.dispose();
  });

  test('review pages retain repeated and anonymized reviews', () async {
    final auth = AuthProvider(authRepository: MockAuthRepository());
    final provider = ReviewsProvider(
      reviewRepository: _PagedReviewRepository(),
      authProvider: auth,
      isConnected: () => true,
    );
    await provider.fetchReviews('place');
    await provider.loadMoreReviews('place');
    final reviews = provider.getReviews('place');
    expect(reviews, hasLength(3));
    expect(
      reviews.where((review) => review.userId == 'same-user'),
      hasLength(2),
    );
    expect(
      reviews.singleWhere((review) => review.id == 'anonymous').userId,
      isNull,
    );
    provider.dispose();
    auth.dispose();
  });
}

class _ControlledPlaceRepository extends MockPlaceRepository {
  final requests = <Completer<PageResult<PlaceModel>>>[];

  @override
  Future<PageResult<PlaceModel>> fetchPlacesPage({
    String? cursor,
    int limit = 20,
  }) {
    final request = Completer<PageResult<PlaceModel>>();
    requests.add(request);
    return request.future;
  }
}

class _PagedEventRepository extends MockEventRepository {
  @override
  Future<PageResult<EventModel>> getEventsPage({
    String? cursor,
    int limit = 20,
  }) async {
    if (cursor == null) {
      return PageResult(
        items: [
          _event('active-1'),
          _event('archived', status: 'archived'),
        ],
        nextCursor: 'page-1',
        hasMore: true,
      );
    }
    return PageResult(
      items: [_event('active-2')],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<EventModel?> getFeaturedEvent() async => null;
}

class _PagedHangoutRepository extends MockHangoutRepository {
  @override
  Future<PageResult<HangoutModel>> getHangoutsPage({
    String? cursor,
    int limit = 20,
  }) async {
    if (cursor == null) {
      return PageResult(
        items: [
          _hangout('active-1'),
          _hangout('inactive', status: 'inactive'),
        ],
        nextCursor: 'page-1',
        hasMore: true,
      );
    }
    return PageResult(
      items: [_hangout('active-2')],
      nextCursor: null,
      hasMore: false,
    );
  }
}

class _PagedReviewRepository extends MockReviewRepository {
  @override
  Future<PageResult<ReviewModel>> fetchReviewsPage(
    String placeId, {
    String? cursor,
    int limit = 15,
  }) async {
    if (cursor == null) {
      return PageResult(
        items: [_review('first', 'same-user'), _review('second', 'same-user')],
        nextCursor: 'page-1',
        hasMore: true,
      );
    }
    return PageResult(
      items: [_review('anonymous', null)],
      nextCursor: null,
      hasMore: false,
    );
  }
}

PlaceModel _place(String id) => PlaceModel(
  id: id,
  name: 'Place $id',
  imageUrl: '',
  category: 'Cafe',
  location: 'Addis Ababa',
  rating: 0,
  priceRange: r'$',
  isOpen: true,
  latitude: 9,
  longitude: 38,
  tags: const [],
  reviewCount: 0,
);

EventModel _event(String id, {String status = 'active'}) => EventModel(
  id: id,
  title: 'Event',
  category: 'Tech',
  location: 'Addis Ababa',
  date: '2026-10-01',
  time: '10:00',
  host: 'Host',
  imageUrl: '',
  attendeeCount: 0,
  description: 'Description',
  lifecycleStatus: status,
);

HangoutModel _hangout(String id, {String status = 'active'}) => HangoutModel(
  id: id,
  title: 'Hangout',
  category: 'Coffee',
  location: 'Addis Ababa',
  time: '10:00',
  imageUrl: '',
  attendeeCount: 0,
  description: 'Description',
  lifecycleStatus: status,
);

ReviewModel _review(String id, String? userId) => ReviewModel(
  id: id,
  placeId: 'place',
  userId: userId,
  rating: 5,
  reviewText: 'Review',
  createdAt: DateTime.utc(2026, 1, id.length),
);
