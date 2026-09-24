import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:meetmap_addis/shared/models/event_model.dart';
import 'package:meetmap_addis/shared/models/review_model.dart';

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

  test('review timestamps support Firestore, DateTime, string, and null', () {
    final expected = DateTime.utc(2026, 9, 24, 8, 30);

    ReviewModel parse(dynamic createdAt) => ReviewModel.fromMap({
      'id': 'review-1',
      'placeId': 'place-1',
      'userId': 'user-1',
      'rating': 4,
      'reviewText': 'A useful review',
      'createdAt': createdAt,
    });

    expect(
      parse(Timestamp.fromDate(expected)).createdAt.isAtSameMomentAs(expected),
      isTrue,
    );
    expect(parse(expected).createdAt, expected);
    expect(parse(expected.toIso8601String()).createdAt, expected);
    expect(parse(null).createdAt, isA<DateTime>());
  });

  test('event documents without coordinates remain locationless', () {
    final event = EventModel.fromMap({
      'id': 'event-1',
      'title': 'Community meetup',
    });

    expect(event.latitude, isNull);
    expect(event.longitude, isNull);
  });
}
