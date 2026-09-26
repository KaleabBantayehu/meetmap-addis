import 'package:flutter_test/flutter_test.dart';
import 'package:meetmap_addis/core/repositories/saved_place_hydrator.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

void main() {
  test('ten saved places use one batched hydration operation', () async {
    final ids = List.generate(10, (index) => 'place-$index');
    var operations = 0;
    final result = await hydrateSavedPlaces(
      savedPlaceIds: ids,
      fetchBatch: (batch) async {
        operations++;
        return batch.reversed.map(_place).toList();
      },
    );

    expect(operations, 1);
    expect(result.map((place) => place.id), ids);
  });

  test(
    'missing places are skipped without changing valid saved order',
    () async {
      final result = await hydrateSavedPlaces(
        savedPlaceIds: const ['A', 'B', 'C', 'D'],
        fetchBatch: (_) async => [_place('C'), _place('A'), _place('D')],
      );

      expect(result.map((place) => place.id), ['A', 'C', 'D']);
    },
  );

  test('large saved sets are chunked, deduplicated, and ordered', () async {
    final ids = List.generate(65, (index) => 'place-$index');
    final requestedBatches = <List<String>>[];
    final result = await hydrateSavedPlaces(
      savedPlaceIds: [...ids, 'place-3', 'place-20'],
      fetchBatch: (batch) async {
        requestedBatches.add(List.from(batch));
        return batch.reversed.map(_place).toList();
      },
    );

    expect(requestedBatches.map((batch) => batch.length), [30, 30, 5]);
    expect(result.map((place) => place.id), ids);
  });
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
