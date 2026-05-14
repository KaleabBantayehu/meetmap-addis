import 'package:meetmap_addis/shared/models/place_model.dart';

final List<PlaceModel> mockPlaces = [
  const PlaceModel(
    id: '1',
    name: 'Tomoca Coffee',
    imageUrl:
        'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=1200&q=80',
    category: 'Cafe',
    location: 'Bole',
    rating: 4.8,
    isOpen: true,
    latitude: 9.03,
    longitude: 38.74,
    priceRange: r'$$',
    reviewCount: 1200,
    tags: ['Study', 'History', 'Iconic'],
  ),
  const PlaceModel(
    id: '2',
    name: 'Garden of Coffee',
    imageUrl:
        'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085',
    category: 'Cafe',
    location: 'Kazanchis',
    rating: 4.9,
    isOpen: true,
    latitude: 9.02,
    longitude: 38.76,
    priceRange: r'$$$',
    reviewCount: 980,
    tags: ['Meeting', 'Date', 'Premium'],
  ),
  const PlaceModel(
    id: '3',
    name: 'Work-at-Bole',
    imageUrl:
        'https://images.unsplash.com/photo-1522202176988-66273c2fd55f',
    category: 'Coworking',
    location: 'Bole',
    rating: 4.5,
    isOpen: true,
    latitude: 9.01,
    longitude: 38.75,
    priceRange: r'$$',
    reviewCount: 540,
    tags: ['Fast Wifi', 'Quiet', 'Networking'],
  ),
];
