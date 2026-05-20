import 'dart:convert';
import 'package:flutter/foundation.dart';

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

  PlaceModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? category,
    String? location,
    double? rating,
    String? priceRange,
    bool? isOpen,
    double? latitude,
    double? longitude,
    List<String>? tags,
    int? reviewCount,
  }) {
    return PlaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      priceRange: priceRange ?? this.priceRange,
      isOpen: isOpen ?? this.isOpen,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tags: tags ?? this.tags,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

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

  String toJson() => json.encode(toMap());

  factory PlaceModel.fromJson(String source) =>
      PlaceModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlaceModel &&
        other.id == id &&
        other.name == name &&
        other.imageUrl == imageUrl &&
        other.category == category &&
        other.location == location &&
        other.rating == rating &&
        other.priceRange == priceRange &&
        other.isOpen == isOpen &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        listEquals(other.tags, tags) &&
        other.reviewCount == reviewCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        imageUrl.hashCode ^
        category.hashCode ^
        location.hashCode ^
        rating.hashCode ^
        priceRange.hashCode ^
        isOpen.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        tags.hashCode ^
        reviewCount.hashCode;
  }
}