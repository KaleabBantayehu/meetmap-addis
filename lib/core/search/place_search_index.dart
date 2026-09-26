const int placeSearchMinimumLength = 2;
const int placeSearchMaximumPrefixLength = 50;
const int placeSearchMaximumPrefixes = 200;

String normalizePlaceSearchQuery(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

List<String> buildPlaceSearchPrefixes(Iterable<String> values) {
  final prefixes = <String>{};

  for (final value in values) {
    final normalized = normalizePlaceSearchQuery(value);
    if (normalized.isEmpty) continue;

    final words = normalized.split(' ');
    for (var wordIndex = 0; wordIndex < words.length; wordIndex++) {
      final phrase = words.skip(wordIndex).join(' ');
      final upperBound = phrase.length < placeSearchMaximumPrefixLength
          ? phrase.length
          : placeSearchMaximumPrefixLength;
      for (
        var length = placeSearchMinimumLength;
        length <= upperBound;
        length++
      ) {
        prefixes.add(phrase.substring(0, length));
        if (prefixes.length >= placeSearchMaximumPrefixes) {
          return prefixes.toList();
        }
      }
    }
  }

  return prefixes.toList();
}
