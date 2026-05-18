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
  });
}
