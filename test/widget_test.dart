import 'package:flutter_test/flutter_test.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

void main() {
  test('legacy place pricing remains compatible', () {
    final place = PlaceModel.fromMap({
      'id': 'legacy-place',
      'name': 'Legacy Place',
      'imageUrl': '',
      'category': 'Cafe',
      'location': 'Addis Ababa',
      'rating': 4.0,
      'priceRange': r'$$$',
      'isOpen': true,
      'latitude': 9.03,
      'longitude': 38.74,
      'tags': <String>[],
      'reviewCount': 0,
    });

    expect(place.normalizedPriceLevel, 3);
    expect(place.priceLabel, 'Premium');
    expect(place.priceDisplay, '600–1500 ETB');
  });
}
