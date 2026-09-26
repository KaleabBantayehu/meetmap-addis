import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meetmap_addis/core/location/geo_bounds.dart';
import 'package:meetmap_addis/core/repositories/mock/mock_place_repository.dart';
import 'package:meetmap_addis/core/repositories/page_result.dart';
import 'package:meetmap_addis/core/storage/local_storage_service.dart';
import 'package:meetmap_addis/providers/places_provider.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  test('bounds validate and contain coordinates predictably', () {
    const bounds = GeoBounds(north: 9.1, south: 9, east: 38.8, west: 38.7);
    expect(bounds.isValid, isTrue);
    expect(bounds.contains(9.05, 38.75), isTrue);
    expect(bounds.contains(8.9, 38.75), isFalse);
    expect(
      const GeoBounds(north: 9, south: 9.1, east: 38.8, west: 38.7).isValid,
      isFalse,
    );
  });

  test('distance calculation is deterministic and excludes invalid points', () {
    final first = distanceKm(
      fromLatitude: 9.03,
      fromLongitude: 38.74,
      toLatitude: 9.04,
      toLongitude: 38.75,
    );
    final second = distanceKm(
      fromLatitude: 9.03,
      fromLongitude: 38.74,
      toLatitude: 9.04,
      toLongitude: 38.75,
    );
    expect(first, closeTo(second, 0.0000001));
    expect(first, greaterThan(0));
    expect(
      distanceKm(
        fromLatitude: 9.03,
        fromLongitude: 38.74,
        toLatitude: 0,
        toLongitude: 0,
      ),
      double.infinity,
    );
  });

  test(
    'bounded mock query honors limit and cursor without duplicates',
    () async {
      final repository = MockPlaceRepository();
      const bounds = GeoBounds(north: 10, south: 8, east: 40, west: 37);
      final first = await repository.fetchPlacesInBounds(bounds, limit: 2);
      expect(first.items.length, lessThanOrEqualTo(2));
      expect(first.hasMore, isTrue);
      final second = await repository.fetchPlacesInBounds(
        bounds,
        cursor: first.nextCursor,
        limit: 2,
      );
      expect(
        first.items
            .map((place) => place.id)
            .toSet()
            .intersection(second.items.map((place) => place.id).toSet()),
        isEmpty,
      );
    },
  );

  test(
    'radius query retains inside places and excludes outside places',
    () async {
      final repository = _RadiusRepository([
        _place('inside', 9.031, 38.741),
        _place('outside', 9.2, 38.9),
        _place('legacy', 0, 0),
      ]);
      final page = await repository.fetchNearbyPlaces(
        latitude: 9.03,
        longitude: 38.74,
        radiusKm: 5,
      );
      expect(page.items.map((place) => place.id), ['inside']);
      expect(repository.boundsRequests, 1);
    },
  );

  test('newer bounds request beats an older delayed response', () async {
    final repository = _ControlledGeoRepository();
    final provider = PlacesProvider(
      placeRepository: repository,
      isConnected: () => true,
    );
    const firstBounds = GeoBounds(north: 9.1, south: 9, east: 38.8, west: 38.7);
    const secondBounds = GeoBounds(
      north: 9.2,
      south: 9.1,
      east: 38.9,
      west: 38.8,
    );

    final first = provider.fetchPlacesInBounds(firstBounds);
    final second = provider.fetchPlacesInBounds(secondBounds);
    repository.boundsRequests[1].complete(
      PageResult(
        items: [_place('new', 9.15, 38.85)],
        nextCursor: null,
        hasMore: false,
      ),
    );
    await second;
    repository.boundsRequests[0].complete(
      PageResult(
        items: [_place('old', 9.05, 38.75)],
        nextCursor: null,
        hasMore: false,
      ),
    );
    await first;
    expect(provider.mapPlaces.single.id, 'new');
    provider.dispose();
  });

  test(
    'old-session geographic response cannot populate a new session',
    () async {
      final repository = _ControlledGeoRepository();
      final provider = PlacesProvider(
        placeRepository: repository,
        isConnected: () => true,
      );
      provider.syncSession('alice');
      final request = provider.fetchPlacesInBounds(
        const GeoBounds(north: 9.1, south: 9, east: 38.8, west: 38.7),
      );
      provider.syncSession('bob');
      repository.boundsRequests.single.complete(
        PageResult(
          items: [_place('alice', 9.05, 38.75)],
          nextCursor: null,
          hasMore: false,
        ),
      );
      await request;
      expect(provider.mapPlaces, isEmpty);
      provider.dispose();
    },
  );
}

class _ControlledGeoRepository extends MockPlaceRepository {
  final boundsRequests = <Completer<PageResult<PlaceModel>>>[];

  @override
  Future<PageResult<PlaceModel>> fetchPlacesInBounds(
    GeoBounds bounds, {
    String? cursor,
    int limit = 50,
  }) {
    final completer = Completer<PageResult<PlaceModel>>();
    boundsRequests.add(completer);
    return completer.future;
  }
}

class _RadiusRepository extends MockPlaceRepository {
  _RadiusRepository(this.places);

  final List<PlaceModel> places;
  int boundsRequests = 0;

  @override
  Future<PageResult<PlaceModel>> fetchPlacesPage({
    String? cursor,
    int limit = 20,
  }) => throw StateError('Radius discovery must not read general place pages.');

  @override
  Future<PageResult<PlaceModel>> fetchPlacesInBounds(
    GeoBounds bounds, {
    String? cursor,
    int limit = 50,
  }) async {
    boundsRequests++;
    final candidates = places
        .where(
          (place) =>
              hasValidCoordinates(place.latitude, place.longitude) &&
              bounds.contains(place.latitude, place.longitude),
        )
        .take(limit)
        .toList();
    return PageResult(items: candidates, nextCursor: null, hasMore: false);
  }
}

PlaceModel _place(String id, double latitude, double longitude) => PlaceModel(
  id: id,
  name: 'Place $id',
  imageUrl: '',
  category: 'Cafe',
  location: 'Addis Ababa',
  rating: 0,
  priceRange: r'$',
  isOpen: true,
  latitude: latitude,
  longitude: longitude,
  tags: const [],
  reviewCount: 0,
);
