import 'dart:convert';
import 'package:flutter/foundation.dart';

class PlaceModel {
  static const List<int> priceLevels = [1, 2, 3, 4];

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

  final String description;
  final int priceLevel;
  final List<String> imageUrls;
  final List<String> amenities;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? phone;

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
    this.description = '',
    this.priceLevel = 2,
    this.imageUrls = const [],
    this.amenities = const [],
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.phone,
  }) : assert(rating >= 0 && rating <= 5);

  int get normalizedPriceLevel => normalizePriceLevel(priceLevel, priceRange);

  String get priceLabel => priceLabelFor(normalizedPriceLevel);

  String get priceDisplay => priceDisplayFor(normalizedPriceLevel);

  String get priceSummary => '$priceLabel • $priceDisplay';

  static int normalizePriceLevel(int? level, [String? legacyPriceRange]) {
    if (level != null && level >= 1 && level <= 4) {
      return level;
    }

    return switch (legacyPriceRange?.trim()) {
      r'$' => 1,
      r'$$' => 2,
      r'$$$' => 3,
      r'$$$$' => 4,
      _ => 2,
    };
  }

  static String priceLabelFor(int level) {
    return switch (normalizePriceLevel(level)) {
      1 => 'Budget',
      2 => 'Moderate',
      3 => 'Premium',
      4 => 'Luxury',
      _ => 'Moderate',
    };
  }

  static String priceDisplayFor(int level) {
    return switch (normalizePriceLevel(level)) {
      1 => 'Under 300 ETB',
      2 => '300–600 ETB',
      3 => '600–1500 ETB',
      4 => '1500+ ETB',
      _ => '300–600 ETB',
    };
  }

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
    String? description,
    int? priceLevel,
    List<String>? imageUrls,
    List<String>? amenities,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? phone,
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
      description: description ?? this.description,
      priceLevel: priceLevel ?? this.priceLevel,
      imageUrls: imageUrls ?? this.imageUrls,
      amenities: amenities ?? this.amenities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      phone: phone ?? this.phone,
    );
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val.runtimeType.toString() == 'Timestamp' ||
        val.toString().contains('Timestamp')) {
      try {
        return (val as dynamic).toDate();
      } catch (_) {}
    }
    return null;
  }

  static double _parseCoordinate(dynamic value, {required bool isLatitude}) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final type = value.runtimeType.toString();
    if (type == 'GeoPoint') {
      try {
        return isLatitude
            ? (value as dynamic).latitude.toDouble()
            : (value as dynamic).longitude.toDouble();
      } catch (_) {
        return 0;
      }
    }
    if (value is String) {
      return double.tryParse(value.trim()) ?? 0;
    }
    return 0;
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
      latitude: _parseCoordinate(
        map['latitude'] ??
            (map['coordinates'] is Map<String, dynamic>
                ? (map['coordinates'] as Map<String, dynamic>)['lat']
                : null),
        isLatitude: true,
      ),
      longitude: _parseCoordinate(
        map['longitude'] ??
            (map['coordinates'] is Map<String, dynamic>
                ? (map['coordinates'] as Map<String, dynamic>)['lng']
                : null),
        isLatitude: false,
      ),
      tags: List<String>.from(map['tags'] ?? []),
      reviewCount: map['reviewCount'] ?? 0,
      description: map['description'] ?? '',
      priceLevel: normalizePriceLevel(
        map['priceLevel'] is int
            ? map['priceLevel'] as int
            : int.tryParse('${map['priceLevel'] ?? ''}'),
        map['priceRange'] as String?,
      ),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      amenities: List<String>.from(map['amenities'] ?? []),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      createdBy: map['createdBy'] as String?,
      phone: map['phone'] as String?,
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
      'description': description,
      'priceLevel': normalizedPriceLevel,
      'imageUrls': imageUrls,
      'amenities': amenities,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'phone': phone,
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
        other.reviewCount == reviewCount &&
        other.description == description &&
        other.priceLevel == priceLevel &&
        listEquals(other.imageUrls, imageUrls) &&
        listEquals(other.amenities, amenities) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.createdBy == createdBy &&
        other.phone == phone;
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
        reviewCount.hashCode ^
        description.hashCode ^
        priceLevel.hashCode ^
        imageUrls.hashCode ^
        amenities.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        createdBy.hashCode ^
        phone.hashCode;
  }
}
