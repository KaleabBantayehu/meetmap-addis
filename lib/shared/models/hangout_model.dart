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
  });
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
}
