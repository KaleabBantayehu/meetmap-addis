class PlaceModel {
  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final String location;
  final double rating;

  final String priceRange;
  final bool isOpen;
  final double latitude;
  final double longitude;
  final List<String> tags;
  final int reviewCount;

  const PlaceModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.location,
    required this.rating,
    required this.priceRange,
    required this.isOpen,
    required this.latitude,
    required this.longitude,
    required this.tags,
    required this.reviewCount,
  }) : assert(rating >= 0 && rating <= 5);

  factory PlaceModel.fromMap(Map<String, dynamic> map) {
    return PlaceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      priceRange: map['priceRange'] ?? '',
      isOpen: map['isOpen'] ?? false,
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      tags: List<String>.from(map['tags'] ?? []),
      reviewCount: map['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'category': category,
      'location': location,
      'rating': rating,
      'priceRange': priceRange,
      'isOpen': isOpen,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags,
      'reviewCount': reviewCount,
    };
  }
}