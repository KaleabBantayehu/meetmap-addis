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
  const PlaceModel(
    id: '4',
    name: 'Lime Tree',
    imageUrl:
        'https://images.unsplash.com/photo-1598514982205-f36b96d1e8d4?auto=format&fit=crop&w=1200&q=80',
    category: 'International',
    location: 'Kazanchis',
    rating: 4.5,
    isOpen: true,
    latitude: 9.018,
    longitude: 38.761,
    priceRange: r'$$$',
    reviewCount: 430,
    tags: ['Dining', 'Garden', 'International'],
  ),
  const PlaceModel(
    id: '5',
    name: 'Kuriftu Bistro',
    imageUrl:
        'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?auto=format&fit=crop&w=1200&q=80',
    category: 'Fine Dining',
    location: 'Sarbet',
    rating: 4.7,
    isOpen: true,
    latitude: 9.004,
    longitude: 38.724,
    priceRange: r'$$$$',
    reviewCount: 360,
    tags: ['Dining', 'Date', 'Premium'],
  ),
];

final List<PlaceModel> savedMockPlaces = [
  mockPlaces[0],
  mockPlaces[1],
  mockPlaces[2],
];
