import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

enum DirectionsFailureType {
  configuration,
  invalidInput,
  unauthorized,
  noRoute,
  network,
  timeout,
  invalidResponse,
}

class DirectionsException implements Exception {
  const DirectionsException(this.type);

  final DirectionsFailureType type;

  String get userMessage => switch (type) {
    DirectionsFailureType.configuration || DirectionsFailureType.unauthorized =>
      'The map service is temporarily unavailable.',
    DirectionsFailureType.invalidInput =>
      'The route destination is not available.',
    DirectionsFailureType.noRoute =>
      'No route could be found to this destination.',
    DirectionsFailureType.network || DirectionsFailureType.timeout =>
      'The route could not be loaded. Check your connection and retry.',
    DirectionsFailureType.invalidResponse =>
      'The route could not be loaded. Please retry.',
  };

  bool get canRetry =>
      type == DirectionsFailureType.network ||
      type == DirectionsFailureType.timeout ||
      type == DirectionsFailureType.invalidResponse;
}

class RouteCoordinate {
  const RouteCoordinate(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class DirectionsResult {
  const DirectionsResult({
    required this.distanceKm,
    required this.durationMinutes,
    required this.route,
  });

  final double distanceKm;
  final int durationMinutes;
  final List<RouteCoordinate> route;

  String get distanceDisplay {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get durationDisplay =>
      durationMinutes < 1 ? '< 1 min' : '$durationMinutes min';
}

class GebetaDirectionsService {
  GebetaDirectionsService({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKeyOverride = apiKey;

  final http.Client _client;
  final String? _apiKeyOverride;

  String get _apiKey =>
      _apiKeyOverride ?? dotenv.env['GEBETA_API_KEY']?.trim() ?? '';

  Future<DirectionsResult> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    if (_apiKey.isEmpty) {
      throw const DirectionsException(DirectionsFailureType.configuration);
    }
    if (!_isValidCoordinate(originLat, originLng) ||
        !_isValidCoordinate(destLat, destLng)) {
      throw const DirectionsException(DirectionsFailureType.invalidInput);
    }

    debugPrint(
      'Route request: origin=$originLat,$originLng '
      'destination=$destLat,$destLng',
    );

    final uri = Uri.https('mapapi.gebeta.app', '/api/route/direction/', {
      'origin': '{$originLat,$originLng}',
      'destination': '{$destLat,$destLng}',
      'apiKey': _apiKey,
    });

    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 20));
      debugPrint('Gebeta Directions response status: ${response.statusCode}');

      switch (response.statusCode) {
        case 200:
          return _parseDirectionsResponse(json.decode(response.body));
        case 401:
          throw const DirectionsException(DirectionsFailureType.unauthorized);
        case 404:
          throw const DirectionsException(DirectionsFailureType.noRoute);
        case 422:
          throw const DirectionsException(DirectionsFailureType.invalidInput);
        default:
          throw const DirectionsException(
            DirectionsFailureType.invalidResponse,
          );
      }
    } on DirectionsException {
      rethrow;
    } on TimeoutException {
      throw const DirectionsException(DirectionsFailureType.timeout);
    } on SocketException {
      throw const DirectionsException(DirectionsFailureType.network);
    } on FormatException {
      throw const DirectionsException(DirectionsFailureType.invalidResponse);
    } on http.ClientException {
      throw const DirectionsException(DirectionsFailureType.network);
    }
  }

  DirectionsResult _parseDirectionsResponse(dynamic decoded) {
    if (decoded is! Map<String, dynamic> ||
        decoded['msg']?.toString().toLowerCase() != 'ok') {
      throw const DirectionsException(DirectionsFailureType.invalidResponse);
    }

    final totalDistance = decoded['totalDistance'];
    final timeTaken = decoded['timetaken'];
    final direction = decoded['direction'];
    if (totalDistance is! num || timeTaken is! num || direction is! List) {
      throw const DirectionsException(DirectionsFailureType.invalidResponse);
    }

    final route = <RouteCoordinate>[];
    for (final value in direction) {
      if (value is! List || value.length < 2) continue;
      final latitude = value[0];
      final longitude = value[1];
      if (latitude is num &&
          longitude is num &&
          _isValidCoordinate(latitude.toDouble(), longitude.toDouble())) {
        route.add(RouteCoordinate(latitude.toDouble(), longitude.toDouble()));
      }
    }
    if (route.length < 2) {
      throw const DirectionsException(DirectionsFailureType.invalidResponse);
    }

    return DirectionsResult(
      distanceKm: totalDistance.toDouble() / 1000,
      durationMinutes: (timeTaken.toDouble() / 60).round(),
      route: List.unmodifiable(route),
    );
  }

  bool _isValidCoordinate(double latitude, double longitude) {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        (latitude != 0 || longitude != 0);
  }
}
