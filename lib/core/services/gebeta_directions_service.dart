import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DirectionsResult {
  const DirectionsResult({
    required this.distanceKm,
    required this.durationMinutes,
  });

  final double distanceKm;
  final int durationMinutes;

  String get distanceDisplay {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get durationDisplay {
    if (durationMinutes < 1) {
      return '< 1 min';
    }
    return '$durationMinutes min';
  }
}

class GebetaDirectionsService {
  GebetaDirectionsService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  String get _apiKey => dotenv.env['GEBETA_API_KEY']?.trim() ?? '';

  Future<DirectionsResult?> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    if (_apiKey.isEmpty) {
      return null;
    }

    try {
      final uri = Uri.https(
        'api.gebeta.app',
        '/v1/directions/route',
        {
          'startLng': '$originLng',
          'startLat': '$originLat',
          'endLng': '$destLng',
          'endLat': '$destLat',
          'apiKey': _apiKey,
        },
      );

      final response = await _client
          .get(
            uri,
            headers: {'Authorization': 'Bearer $_apiKey'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return _parseDirectionsResponse(decoded);
      }

      return null;
    } on TimeoutException {
      return null;
    } on SocketException {
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>?> getDirectionsRaw({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    if (_apiKey.isEmpty) {
      return null;
    }

    try {
      final uri = Uri.https(
        'mapapi.gebeta.app',
        '/v1/directions/route',
        {
          'startLng': '$originLng',
          'startLat': '$originLat',
          'endLng': '$destLng',
          'endLat': '$destLat',
          'apiKey': _apiKey,
        },
      );

      final response = await _client
          .get(
            uri,
            headers: {'Authorization': 'Bearer $_apiKey'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return _extractPolylineCoordinates(decoded);
      }

      return null;
    } on TimeoutException {
      return null;
    } on SocketException {
      return null;
    } catch (e) {
      return null;
    }
  }

  List<dynamic>? _extractPolylineCoordinates(dynamic decoded) {
    try {
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final direction = decoded['direction'];
      if (direction is List && direction.isNotEmpty) {
        return direction;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  DirectionsResult? _parseDirectionsResponse(dynamic decoded) {
    try {
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final totalDistance = decoded['totalDistance'] as num?;
      final timetaken = decoded['timetaken'] as num?;

      if (totalDistance == null || timetaken == null) {
        return null;
      }

      final distanceKm = totalDistance.toDouble();
      final durationMinutes = (timetaken.toDouble() / 60).round();

      return DirectionsResult(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
      );
    } catch (_) {
      return null;
    }
  }
}