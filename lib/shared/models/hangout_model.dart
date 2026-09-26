import 'dart:convert';

class HangoutModel {
  final String id;
  final String title;
  final String category;
  final String location;
  final String time;
  final String imageUrl;
  final int attendeeCount;
  final String description;
  final bool isLive;
  final String? createdBy;
  final double? latitude;
  final double? longitude;
  final String lifecycleStatus;

  const HangoutModel({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.time,
    required this.imageUrl,
    required this.attendeeCount,
    required this.description,
    this.isLive = false,
    this.createdBy,
    this.latitude,
    this.longitude,
    this.lifecycleStatus = 'active',
  });

  bool get isActive => lifecycleStatus == 'active';

  HangoutModel copyWith({
    String? id,
    String? title,
    String? category,
    String? location,
    String? time,
    String? imageUrl,
    int? attendeeCount,
    String? description,
    bool? isLive,
    String? createdBy,
    double? latitude,
    double? longitude,
    String? lifecycleStatus,
  }) {
    return HangoutModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      location: location ?? this.location,
      time: time ?? this.time,
      imageUrl: imageUrl ?? this.imageUrl,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      description: description ?? this.description,
      isLive: isLive ?? this.isLive,
      createdBy: createdBy ?? this.createdBy,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
    );
  }

  factory HangoutModel.fromMap(Map<String, dynamic> map) {
    return HangoutModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      time: map['time'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      attendeeCount: map['attendeeCount'] ?? 0,
      description: map['description'] ?? '',
      isLive: map['isLive'] ?? false,
      createdBy: map['createdBy'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      lifecycleStatus: map['lifecycleStatus'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'location': location,
      'time': time,
      'imageUrl': imageUrl,
      'attendeeCount': attendeeCount,
      'description': description,
      'isLive': isLive,
      'createdBy': createdBy,
      'latitude': latitude,
      'longitude': longitude,
      'lifecycleStatus': lifecycleStatus,
    };
  }

  String toJson() => json.encode(toMap());

  factory HangoutModel.fromJson(String source) =>
      HangoutModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HangoutModel &&
        other.id == id &&
        other.title == title &&
        other.category == category &&
        other.location == location &&
        other.time == time &&
        other.imageUrl == imageUrl &&
        other.attendeeCount == attendeeCount &&
        other.description == description &&
        other.isLive == isLive &&
        other.createdBy == createdBy &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.lifecycleStatus == lifecycleStatus;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        category.hashCode ^
        location.hashCode ^
        time.hashCode ^
        imageUrl.hashCode ^
        attendeeCount.hashCode ^
        description.hashCode ^
        isLive.hashCode ^
        createdBy.hashCode ^
        (latitude?.hashCode ?? 0) ^
        (longitude?.hashCode ?? 0) ^
        lifecycleStatus.hashCode;
  }
}

class VenueModel {
  final String id;
  final String name;
  final String location;
  final double rating;
  final String imageUrl;

  const VenueModel({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.imageUrl,
  });

  VenueModel copyWith({
    String? id,
    String? name,
    String? location,
    double? rating,
    String? imageUrl,
  }) {
    return VenueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory VenueModel.fromMap(Map<String, dynamic> map) {
    return VenueModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'rating': rating,
      'imageUrl': imageUrl,
    };
  }

  String toJson() => json.encode(toMap());

  factory VenueModel.fromJson(String source) =>
      VenueModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VenueModel &&
        other.id == id &&
        other.name == name &&
        other.location == location &&
        other.rating == rating &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        location.hashCode ^
        rating.hashCode ^
        imageUrl.hashCode;
  }
}

class ActivityModel {
  final String id;
  final String authorName;
  final String message;
  final String timestamp;
  final String? avatarUrl;
  final bool hasGroupIcon;

  const ActivityModel({
    required this.id,
    required this.authorName,
    required this.message,
    required this.timestamp,
    this.avatarUrl,
    this.hasGroupIcon = false,
  });

  ActivityModel copyWith({
    String? id,
    String? authorName,
    String? message,
    String? timestamp,
    String? avatarUrl,
    bool? hasGroupIcon,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hasGroupIcon: hasGroupIcon ?? this.hasGroupIcon,
    );
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'] ?? '',
      authorName: map['authorName'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? '',
      avatarUrl: map['avatarUrl'],
      hasGroupIcon: map['hasGroupIcon'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorName': authorName,
      'message': message,
      'timestamp': timestamp,
      'avatarUrl': avatarUrl,
      'hasGroupIcon': hasGroupIcon,
    };
  }

  String toJson() => json.encode(toMap());

  factory ActivityModel.fromJson(String source) =>
      ActivityModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ActivityModel &&
        other.id == id &&
        other.authorName == authorName &&
        other.message == message &&
        other.timestamp == timestamp &&
        other.avatarUrl == avatarUrl &&
        other.hasGroupIcon == hasGroupIcon;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        authorName.hashCode ^
        message.hashCode ^
        timestamp.hashCode ^
        avatarUrl.hashCode ^
        hasGroupIcon.hashCode;
  }
}
