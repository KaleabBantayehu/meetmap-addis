import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeocodingResult {
  const GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
  });

  final double latitude;
  final double longitude;
  final String formattedAddress;
}

class GebetaGeocodingService {
  GebetaGeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _apiKey => dotenv.env['GEBETA_API_KEY']?.trim() ?? '';

  static const Map<String, GeocodingResult> _addisFallbacks = {
    'bole': GeocodingResult(
      latitude: 9.0108,
      longitude: 38.7613,
      formattedAddress: 'Bole, Addis Ababa, Ethiopia',
    ),
    'mexico': GeocodingResult(
      latitude: 9.0054,
      longitude: 38.7636,
      formattedAddress: 'Mexico Square, Addis Ababa, Ethiopia',
    ),
    '4 kilo': GeocodingResult(
      latitude: 9.0462,
      longitude: 38.7617,
      formattedAddress: '4 Kilo, Addis Ababa, Ethiopia',
    ),
    'cmc': GeocodingResult(
      latitude: 9.0392,
      longitude: 38.8536,
      formattedAddress: 'CMC, Addis Ababa, Ethiopia',
    ),
  };

  Future<GeocodingResult> forwardGeocode(String query) async {
    if (_apiKey.isEmpty) {
      throw Exception('Map service is not configured.');
    }
    final normalized = query.trim();
    if (normalized.isEmpty) {
      throw Exception('Please enter a location.');
    }

    final candidates = <String>[
      normalized,
      '$normalized Addis Ababa',
      '$normalized, Addis Ababa, Ethiopia',
    ];
    final endpoints = candidates
        .map(
          (candidate) => Uri.https(
            'mapapi.gebeta.app',
            '/v2/search/geocode',
            {
              'query': candidate,
              'country': 'et',
              'limit': '5',
              'apiKey': _apiKey,
            },
          ),
        )
        .toList();

    try {
      return await _requestAndParse(endpoints, fallbackAddress: normalized);
    } catch (e) {
      final fallback = _fallbackForAddisQuery(normalized);
      if (fallback != null) return fallback;
      rethrow;
    }
  }

  Future<GeocodingResult> reverseGeocode(double latitude, double longitude) async {
    if (_apiKey.isEmpty) {
      throw Exception('Map service is not configured.');
    }

    final endpoints = <Uri>[
      Uri.https('mapapi.gebeta.app', '/v2/search/reverse-geocoding', {
        'lat': '$latitude',
        'lon': '$longitude',
        'size': '1',
        'apiKey': _apiKey,
      }),
    ];

    return _requestAndParse(
      endpoints,
      fallbackAddress: '$latitude, $longitude',
    );
  }

  Future<GeocodingResult> _requestAndParse(
    List<Uri> endpoints, {
    required String fallbackAddress,
  }) async {
    Object? lastError;
    for (final uri in endpoints) {
      try {
        final response = await _client
            .get(
              uri,
              headers: {'Authorization': 'Bearer $_apiKey'},
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          if (response.statusCode == 401) {
            lastError = Exception('Map access is unauthorized.');
          } else if (response.statusCode == 403) {
            lastError = Exception('Geocoding is currently unavailable for this API key.');
          } else if (response.statusCode == 404) {
            lastError = Exception('Location not found.');
          }
          continue;
        }
        final decoded = json.decode(response.body);
        final parsed = _extractResult(decoded, fallbackAddress: fallbackAddress);
        if (parsed != null) {
          return parsed;
        }
      } on TimeoutException {
        lastError = Exception('Location request timed out.');
      } on SocketException {
        lastError = Exception('Network unavailable.');
      } on FormatException {
        lastError = Exception('Invalid location response.');
      } catch (e) {
        lastError = e;
      }
    }
    final cleaned = lastError?.toString().replaceFirst('Exception: ', '');
    final message = cleaned ?? 'Unable to find that location.';
    if (message.contains('internal state issue') ||
        message.contains('ServerError') ||
        message.contains('status":500') ||
        message.contains('HE00002')) {
      throw Exception('Location service is temporarily unavailable.');
    }
    throw Exception(message);
  }

  GeocodingResult? _extractResult(
    dynamic decoded, {
    required String fallbackAddress,
  }) {
    final candidates = <Map<String, dynamic>>[];
    if (decoded is Map<String, dynamic>) {
      final features = decoded['features'];
      if (features is List && features.isNotEmpty && features.first is Map<String, dynamic>) {
        candidates.add(Map<String, dynamic>.from(features.first as Map));
      }
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final results = data['results'];
        if (results is List && results.isNotEmpty && results.first is Map<String, dynamic>) {
          candidates.add(Map<String, dynamic>.from(results.first as Map));
        }
      }
      candidates.add(decoded);
    } else if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
      candidates.add(Map<String, dynamic>.from(decoded.first as Map));
    }

    for (final item in candidates) {
      final lat = _toDouble(item['lat'] ?? item['latitude'] ?? item['y']);
      final lng = _toDouble(
        item['lng'] ?? item['lon'] ?? item['long'] ?? item['longitude'] ?? item['x'],
      );
      final location = item['location'];
      double? lLat;
      double? lLng;
      if (location is Map<String, dynamic>) {
        lLat = _toDouble(location['lat']);
        lLng = _toDouble(location['lng']);
      }
      final geometry = item['geometry'];
      double? gLat;
      double? gLng;
      if (geometry is Map<String, dynamic>) {
        final coordinates = geometry['coordinates'];
        if (coordinates is List && coordinates.length >= 2) {
          gLng = _toDouble(coordinates[0]);
          gLat = _toDouble(coordinates[1]);
        }
      }
      final resolvedLat = lat ?? lLat ?? gLat;
      final resolvedLng = lng ?? lLng ?? gLng;
      if (resolvedLat == null || resolvedLng == null) {
        continue;
      }
      final address =
          (item['formatted_address'] ??
                  item['display_name'] ??
                  (item['address'] is Map<String, dynamic>
                      ? [
                          (item['address'] as Map<String, dynamic>)['city'],
                          (item['address'] as Map<String, dynamic>)['country'],
                        ].whereType<String>().join(', ')
                      : item['address']) ??
                  item['name'] ??
                  fallbackAddress)
              .toString();
      return GeocodingResult(
        latitude: resolvedLat,
        longitude: resolvedLng,
        formattedAddress: address,
      );
    }
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  GeocodingResult? _fallbackForAddisQuery(String query) {
    final normalized = query.toLowerCase().trim();
    for (final entry in _addisFallbacks.entries) {
      if (normalized == entry.key || normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}
