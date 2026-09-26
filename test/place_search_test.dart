import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meetmap_addis/core/repositories/mock/mock_place_repository.dart';
import 'package:meetmap_addis/core/repositories/page_result.dart';
import 'package:meetmap_addis/core/search/place_search_index.dart';
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

  test('search query normalization is whitespace and case stable', () {
    expect(normalizePlaceSearchQuery(' Cafe '), 'cafe');
    expect(normalizePlaceSearchQuery('cafe'), 'cafe');
    expect(normalizePlaceSearchQuery('  CAFE  '), 'cafe');
    expect(normalizePlaceSearchQuery('  Bole   Cafe  '), 'bole cafe');
  });

  test('prefix index supports word-start public discovery matching', () {
    final prefixes = buildPlaceSearchPrefixes([
      'Tomoca Coffee',
      'Cafe',
      'Bole Atlas',
    ]);
    expect(prefixes, containsAll(['tom', 'tomoca coffee', 'coffee', 'caf']));
    expect(prefixes, containsAll(['bole', 'atlas']));
    expect(prefixes, isNot(contains('moca')));
  });

  test('empty and one-character searches do not call the repository', () async {
    final repository = _ControlledSearchRepository();
    final provider = PlacesProvider(
      placeRepository: repository,
      isConnected: () => true,
    );

    await provider.searchPlaces('   ');
    await provider.searchPlaces('c');

    expect(repository.requests, isEmpty);
    expect(provider.searchResults, isEmpty);
    provider.dispose();
  });

  test(
    'search pages append without duplicates and stop when complete',
    () async {
      final repository = _ControlledSearchRepository();
      final provider = PlacesProvider(
        placeRepository: repository,
        isConnected: () => true,
      );

      final first = provider.searchPlaces(' Cafe ');
      repository.requests.single.completer.complete(
        PageResult(
          items: [_place('a'), _place('b')],
          nextCursor: 'b',
          hasMore: true,
        ),
      );
      await first;

      final second = provider.loadMoreSearchResults();
      expect(repository.requests.last.cursor, 'b');
      repository.requests.last.completer.complete(
        PageResult(
          items: [_place('b'), _place('c')],
          nextCursor: 'c',
          hasMore: false,
        ),
      );
      await second;

      expect(provider.searchResults.map((place) => place.id), ['a', 'b', 'c']);
      await provider.loadMoreSearchResults();
      expect(repository.requests, hasLength(2));
      provider.dispose();
    },
  );

  test('late older query cannot overwrite the current query', () async {
    final repository = _ControlledSearchRepository();
    final provider = PlacesProvider(
      placeRepository: repository,
      isConnected: () => true,
    );

    final cafe = provider.searchPlaces('cafe');
    final restaurant = provider.searchPlaces('restaurant');
    repository.requests[1].completer.complete(
      PageResult(
        items: [_place('restaurant')],
        nextCursor: null,
        hasMore: false,
      ),
    );
    await restaurant;
    repository.requests[0].completer.complete(
      PageResult(items: [_place('cafe')], nextCursor: null, hasMore: false),
    );
    await cafe;

    expect(provider.searchResults.single.id, 'restaurant');
    provider.dispose();
  });

  test(
    'late result from an old session cannot enter the new session',
    () async {
      final repository = _ControlledSearchRepository();
      final provider = PlacesProvider(
        placeRepository: repository,
        isConnected: () => true,
      );
      provider.syncSession('alice');

      final request = provider.searchPlaces('cafe');
      provider.syncSession('bob');
      repository.requests.single.completer.complete(
        PageResult(
          items: [_place('alice-result')],
          nextCursor: null,
          hasMore: false,
        ),
      );
      await request;

      expect(provider.searchResults, isEmpty);
      provider.dispose();
    },
  );

  test(
    'mock search pagination is deterministic at cursor boundaries',
    () async {
      final repository = MockPlaceRepository();
      final first = await repository.searchPlacesPage('ca', limit: 1);
      final repeated = await repository.searchPlacesPage('ca', limit: 1);
      expect(
        first.items.map((place) => place.id),
        repeated.items.map((p) => p.id),
      );
      expect(first.nextCursor, repeated.nextCursor);
      if (first.hasMore) {
        final second = await repository.searchPlacesPage(
          'ca',
          cursor: first.nextCursor,
          limit: 1,
        );
        expect(
          second.items
              .map((place) => place.id)
              .toSet()
              .intersection(first.items.map((place) => place.id).toSet()),
          isEmpty,
        );
      }
    },
  );
}

class _SearchRequest {
  _SearchRequest(this.query, this.cursor);

  final String query;
  final String? cursor;
  final Completer<PageResult<PlaceModel>> completer = Completer();
}

class _ControlledSearchRepository extends MockPlaceRepository {
  final requests = <_SearchRequest>[];

  @override
  Future<PageResult<PlaceModel>> searchPlacesPage(
    String normalizedQuery, {
    String? cursor,
    int limit = 20,
  }) {
    final request = _SearchRequest(normalizedQuery, cursor);
    requests.add(request);
    return request.completer.future;
  }
}

PlaceModel _place(String id) => PlaceModel(
  id: id,
  name: 'Cafe $id',
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
