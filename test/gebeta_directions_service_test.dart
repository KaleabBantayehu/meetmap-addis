import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meetmap_addis/core/services/gebeta_directions_service.dart';

void main() {
  test('uses documented parameters and parses a successful route', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/route/direction/');
      expect(request.url.queryParameters['origin'], '{9.01,38.71}');
      expect(request.url.queryParameters['destination'], '{9.02,38.72}');
      expect(request.url.queryParameters['apiKey'], 'test-key');
      return http.Response(
        '{"msg":"Ok","timetaken":120,"totalDistance":1234,'
        '"direction":[[9.01,38.71],[9.02,38.72]]}',
        200,
      );
    });

    final result =
        await GebetaDirectionsService(
          client: client,
          apiKey: 'test-key',
        ).getDirections(
          originLat: 9.01,
          originLng: 38.71,
          destLat: 9.02,
          destLng: 38.72,
        );

    expect(result.distanceKm, 1.234);
    expect(result.durationMinutes, 2);
    expect(result.route, hasLength(2));
    expect(result.route.last.latitude, 9.02);
    expect(result.route.last.longitude, 38.72);
  });

  for (final (status, failure) in [
    (401, DirectionsFailureType.unauthorized),
    (404, DirectionsFailureType.noRoute),
    (422, DirectionsFailureType.invalidInput),
  ]) {
    test('maps HTTP $status to $failure', () async {
      final service = GebetaDirectionsService(
        client: MockClient((_) async => http.Response('{}', status)),
        apiKey: 'test-key',
      );

      expect(
        () => service.getDirections(
          originLat: 9.01,
          originLng: 38.71,
          destLat: 9.02,
          destLng: 38.72,
        ),
        throwsA(
          isA<DirectionsException>().having(
            (error) => error.type,
            'type',
            failure,
          ),
        ),
      );
    });
  }

  test('rejects invalid coordinates before sending a request', () async {
    final service = GebetaDirectionsService(
      client: MockClient((_) async => fail('request must not be sent')),
      apiKey: 'test-key',
    );

    expect(
      () => service.getDirections(
        originLat: 0,
        originLng: 0,
        destLat: 9.02,
        destLng: 38.72,
      ),
      throwsA(
        isA<DirectionsException>().having(
          (error) => error.type,
          'type',
          DirectionsFailureType.invalidInput,
        ),
      ),
    );
  });
}
