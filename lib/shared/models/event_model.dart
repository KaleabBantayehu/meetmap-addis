import 'dart:convert';

class EventModel {
  final String id;
  final String title;
  final String category;
  final String location;
  final String date;
  final String time;
  final String host;
  final String imageUrl;
  final int attendeeCount;
  final String description;
  final bool isFeatured;
  final String? createdBy;

  const EventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.date,
    required this.time,
    required this.host,
    required this.imageUrl,
    required this.attendeeCount,
    required this.description,
    this.isFeatured = false,
    this.createdBy,
  });

  EventModel copyWith({
    String? id,
    String? title,
    String? category,
    String? location,
    String? date,
    String? time,
    String? host,
    String? imageUrl,
    int? attendeeCount,
    String? description,
    bool? isFeatured,
    String? createdBy,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      location: location ?? this.location,
      date: date ?? this.date,
      time: time ?? this.time,
      host: host ?? this.host,
      imageUrl: imageUrl ?? this.imageUrl,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      description: description ?? this.description,
      isFeatured: isFeatured ?? this.isFeatured,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      host: map['host'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      attendeeCount: map['attendeeCount'] ?? 0,
      description: map['description'] ?? '',
      isFeatured: map['isFeatured'] ?? false,
      createdBy: map['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'location': location,
      'date': date,
      'time': time,
      'host': host,
      'imageUrl': imageUrl,
      'attendeeCount': attendeeCount,
      'description': description,
      'isFeatured': isFeatured,
      'createdBy': createdBy,
    };
  }

  String toJson() => json.encode(toMap());

  factory EventModel.fromJson(String source) =>
      EventModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EventModel &&
        other.id == id &&
        other.title == title &&
        other.category == category &&
        other.location == location &&
        other.date == date &&
        other.time == time &&
        other.host == host &&
        other.imageUrl == imageUrl &&
        other.attendeeCount == attendeeCount &&
        other.description == description &&
        other.isFeatured == isFeatured &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        category.hashCode ^
        location.hashCode ^
        date.hashCode ^
        time.hashCode ^
        host.hashCode ^
        imageUrl.hashCode ^
        attendeeCount.hashCode ^
        description.hashCode ^
        isFeatured.hashCode ^
        createdBy.hashCode;
  }
}
