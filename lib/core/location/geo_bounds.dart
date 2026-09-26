import 'dart:convert';
import 'dart:math' as math;

class GeoBounds {
  const GeoBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  final double north;
  final double south;
  final double east;
  final double west;

  bool get isValid =>
      north.isFinite &&
      south.isFinite &&
      east.isFinite &&
      west.isFinite &&
      north >= south &&
      north <= 90 &&
      south >= -90 &&
      east <= 180 &&
      west >= -180 &&
      east >= west;

  bool contains(double latitude, double longitude) =>
      isValid &&
      latitude >= south &&
      latitude <= north &&
      longitude >= west &&
      longitude <= east;

  factory GeoBounds.around({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    if (!hasValidCoordinates(latitude, longitude) || radiusKm <= 0) {
      throw ArgumentError('A valid center and positive radius are required.');
    }
    const kilometersPerLatitudeDegree = 111.32;
    final latitudeDelta = radiusKm / kilometersPerLatitudeDegree;
    final longitudeScale = math.cos(degreesToRadians(latitude)).abs();
    final longitudeDelta = longitudeScale < 0.000001
        ? 180.0
        : radiusKm / (kilometersPerLatitudeDegree * longitudeScale);
    return GeoBounds(
      north: math.min(90, latitude + latitudeDelta),
      south: math.max(-90, latitude - latitudeDelta),
      east: math.min(180, longitude + longitudeDelta),
      west: math.max(-180, longitude - longitudeDelta),
    );
  }
}

bool hasValidCoordinates(double latitude, double longitude) =>
    latitude.isFinite &&
    longitude.isFinite &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180 &&
    (latitude != 0 || longitude != 0);

double distanceKm({
  required double fromLatitude,
  required double fromLongitude,
  required double toLatitude,
  required double toLongitude,
}) {
  if (!hasValidCoordinates(fromLatitude, fromLongitude) ||
      !hasValidCoordinates(toLatitude, toLongitude)) {
    return double.infinity;
  }
  const earthRadiusKm = 6371.0;
  final latitudeDelta = degreesToRadians(toLatitude - fromLatitude);
  final longitudeDelta = degreesToRadians(toLongitude - fromLongitude);
  final a =
      math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
      math.cos(degreesToRadians(fromLatitude)) *
          math.cos(degreesToRadians(toLatitude)) *
          math.sin(longitudeDelta / 2) *
          math.sin(longitudeDelta / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double degreesToRadians(double degrees) => degrees * math.pi / 180;

String encodeGeoCursor(double latitude, double longitude, String documentId) =>
    jsonEncode([latitude, longitude, documentId]);

({double latitude, double longitude, String documentId})? decodeGeoCursor(
  String? cursor,
) {
  if (cursor == null) return null;
  try {
    final values = jsonDecode(cursor) as List<dynamic>;
    if (values.length != 3) return null;
    return (
      latitude: (values[0] as num).toDouble(),
      longitude: (values[1] as num).toDouble(),
      documentId: values[2] as String,
    );
  } catch (_) {
    return null;
  }
}
