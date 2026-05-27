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

  DirectionsResult? _parseDirectionsResponse(dynamic decoded) {
    try {
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) {
        return null;
      }

      final route = routes.first;
      if (route is! Map<String, dynamic>) {
        return null;
      }

      final distance = route['distance'] as num?;
      final duration = route['duration'] as num?;

      if (distance == null || duration == null) {
        return null;
      }

      final distanceKm = distance.toDouble() / 1000.0;
      final durationMinutes = (duration.toDouble() / 60).round();

      return DirectionsResult(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
      );
    } catch (_) {
      return null;
    }
  }
}
