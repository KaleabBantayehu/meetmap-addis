import '../../shared/models/place_model.dart';

const int savedPlaceLookupBatchSize = 30;

Future<List<PlaceModel>> hydrateSavedPlaces({
  required List<String> savedPlaceIds,
  required Future<List<PlaceModel>> Function(List<String> ids) fetchBatch,
}) async {
  final uniqueIds = savedPlaceIds.where((id) => id.isNotEmpty).toSet().toList();
  final placesById = <String, PlaceModel>{};

  for (
    var start = 0;
    start < uniqueIds.length;
    start += savedPlaceLookupBatchSize
  ) {
    final end = start + savedPlaceLookupBatchSize < uniqueIds.length
        ? start + savedPlaceLookupBatchSize
        : uniqueIds.length;
    final places = await fetchBatch(uniqueIds.sublist(start, end));
    for (final place in places) {
      placesById[place.id] = place;
    }
  }

  return uniqueIds.map((id) => placesById[id]).whereType<PlaceModel>().toList();
}
