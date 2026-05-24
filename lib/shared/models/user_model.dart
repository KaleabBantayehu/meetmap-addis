import 'dart:convert';

/// A scalable data model representing a user in MeetMap Addis.
/// Designed for Firebase/REST integration, supporting authentication,
/// profile management, networking, and activity tracking.
class UserModel {
  final String id;
  final String name;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final String profileImageUrl;
  final String? title; // e.g., "Tech Guru", "Art Curator"
  final String? bio;
  final List<String> tags;
  final List<String> recentImageUrls;
  final bool isVerified;

  // Relationship data (Scalable IDs)
  final List<String> followingIds;
  final List<String> followerIds;

  // App Integration IDs
  final List<String> savedPlaceIds;
  final List<String> reviewIds;
  final List<String> joinedHangoutIds;

  // Metadata & Preferences
  final DateTime? createdAt;
  final bool notificationsEnabled;

  const UserModel({
    required this.id,
    required this.name,
    this.username,
    this.email,
    this.phoneNumber,
    required this.profileImageUrl,
    this.title,
    this.bio,
    this.tags = const [],
    this.recentImageUrls = const [],
    this.isVerified = false,
    this.followingIds = const [],
    this.followerIds = const [],
    this.savedPlaceIds = const [],
    this.reviewIds = const [],
    this.joinedHangoutIds = const [],
    this.createdAt,
    this.notificationsEnabled = true,
  });

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value.runtimeType.toString() == 'Timestamp' ||
        value.toString().contains('Timestamp')) {
      try {
        return (value as dynamic).toDate();
      } catch (_) {}
    }
    return null;
  }

  /// Helper getter for follower count derived from the IDs list
  int get followerCount => followerIds.length;

  /// Helper getter for following count derived from the IDs list
  int get followingCount => followingIds.length;

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? title,
    String? bio,
    List<String>? tags,
    List<String>? recentImageUrls,
    bool? isVerified,
    List<String>? followingIds,
    List<String>? followerIds,
    List<String>? savedPlaceIds,
    List<String>? reviewIds,
    List<String>? joinedHangoutIds,
    DateTime? createdAt,
    bool? notificationsEnabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      tags: tags ?? this.tags,
      recentImageUrls: recentImageUrls ?? this.recentImageUrls,
      isVerified: isVerified ?? this.isVerified,
      followingIds: followingIds ?? this.followingIds,
      followerIds: followerIds ?? this.followerIds,
      savedPlaceIds: savedPlaceIds ?? this.savedPlaceIds,
      reviewIds: reviewIds ?? this.reviewIds,
      joinedHangoutIds: joinedHangoutIds ?? this.joinedHangoutIds,
      createdAt: createdAt ?? this.createdAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'title': title,
      'bio': bio,
      'tags': tags,
      'recentImageUrls': recentImageUrls,
      'isVerified': isVerified,
      'followingIds': followingIds,
      'followerIds': followerIds,
      'savedPlaceIds': savedPlaceIds,
      'reviewIds': reviewIds,
      'joinedHangoutIds': joinedHangoutIds,
      'createdAt': createdAt?.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? map['uid'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] as String?,
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      profileImageUrl: map['profileImageUrl'] ?? map['photoUrl'] ?? '',
      title: map['title'] as String?,
      bio: map['bio'] as String?,
      tags: List<String>.from(map['tags'] ?? []),
      recentImageUrls: List<String>.from(map['recentImageUrls'] ?? []),
      isVerified: map['isVerified'] ?? false,
      followingIds: List<String>.from(map['followingIds'] ?? []),
      followerIds: List<String>.from(map['followerIds'] ?? []),
      savedPlaceIds: List<String>.from(map['savedPlaceIds'] ?? []),
      reviewIds: List<String>.from(map['reviewIds'] ?? []),
      joinedHangoutIds: List<String>.from(map['joinedHangoutIds'] ?? []),
      createdAt: _parseDate(map['createdAt']),
      notificationsEnabled: map['notificationsEnabled'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.username == username &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.profileImageUrl == profileImageUrl &&
        other.title == title &&
        other.bio == bio &&
        other.isVerified == isVerified &&
        other.createdAt == createdAt &&
        other.notificationsEnabled == notificationsEnabled;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        username.hashCode ^
        email.hashCode ^
        phoneNumber.hashCode ^
        profileImageUrl.hashCode ^
        title.hashCode ^
        bio.hashCode ^
        isVerified.hashCode ^
        createdAt.hashCode ^
        notificationsEnabled.hashCode;
  }
}
