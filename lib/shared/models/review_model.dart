import 'dart:convert';

/// A scalable data model representing a review in MeetMap Addis.
/// Designed for Firebase/REST integration, supporting ratings, media,
/// social engagement, and moderation.
class ReviewModel {
  final String id;
  final String placeId;
  final String? userId;
  final double rating;
  final String reviewText;
  final List<String> imageUrls;

  // Metadata
  final DateTime createdAt;
  final bool isEdited;

  // Social Engagement
  final List<String> likedUserIds;

  // Moderation
  final int reportCount;

  const ReviewModel({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.rating,
    required this.reviewText,
    this.imageUrls = const [],
    required this.createdAt,
    this.isEdited = false,
    this.likedUserIds = const [],
    this.reportCount = 0,
  });

  /// Helper to get the number of likes
  int get likesCount => likedUserIds.length;

  ReviewModel copyWith({
    String? id,
    String? placeId,
    String? userId,
    double? rating,
    String? reviewText,
    List<String>? imageUrls,
    DateTime? createdAt,
    bool? isEdited,
    List<String>? likedUserIds,
    int? reportCount,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      isEdited: isEdited ?? this.isEdited,
      likedUserIds: likedUserIds ?? this.likedUserIds,
      reportCount: reportCount ?? this.reportCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'placeId': placeId,
      'userId': userId,
      'rating': rating,
      'reviewText': reviewText,
      'comment': reviewText,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'isEdited': isEdited,
      'likedUserIds': likedUserIds,
      'reportCount': reportCount,
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      placeId: map['placeId'] ?? '',
      userId: map['userId'] as String?,
      rating: (map['rating'] ?? 0).toDouble(),
      reviewText: map['reviewText'] ?? map['comment'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: _parseDate(map['createdAt']),
      isEdited: map['isEdited'] ?? false,
      likedUserIds: List<String>.from(map['likedUserIds'] ?? []),
      reportCount: map['reportCount'] ?? 0,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    try {
      final parsed = (value as dynamic)?.toDate();
      if (parsed is DateTime) return parsed;
    } catch (_) {}
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String toJson() => json.encode(toMap());

  factory ReviewModel.fromJson(String source) =>
      ReviewModel.fromMap(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReviewModel &&
        other.id == id &&
        other.placeId == placeId &&
        other.userId == userId &&
        other.rating == rating &&
        other.reviewText == reviewText &&
        other.createdAt == createdAt &&
        other.isEdited == isEdited;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        placeId.hashCode ^
        userId.hashCode ^
        rating.hashCode ^
        reviewText.hashCode ^
        createdAt.hashCode ^
        isEdited.hashCode;
  }
}
