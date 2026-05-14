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
    name: 'Moyee Coffee',
    imageUrl:
        'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=1200&q=80',
    category: 'Specialty Roastery',
    location: 'Kazanchis',
    rating: 4.7,
    isOpen: true,
    latitude: 9.02,
    longitude: 38.76,
    priceRange: r'$$',
    reviewCount: 980,
    tags: ['Coffee', 'Roastery', 'Meetups'],
  ),
  const PlaceModel(
    id: '3',
    name: "Kaldi's Coffee",
    imageUrl:
        'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
    category: 'Cafe Chain',
    location: 'Sarbet',
    rating: 4.5,
    isOpen: false,
    latitude: 9.00,
    longitude: 38.72,
    priceRange: r'$',
    reviewCount: 540,
    tags: ['Coffee', 'Casual', 'Chain'],
  ),
];

final List<PlaceModel> savedMockPlaces = [
  mockPlaces[0],
  mockPlaces[1],
  mockPlaces[2],
];
