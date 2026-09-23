import 'package:flutter_dotenv/flutter_dotenv.dart';

class GebetaMapService {
  const GebetaMapService();

  static const double addisLatitude = 9.03;
  static const double addisLongitude = 38.74;
  static const double defaultZoom = 13.0;
  static const String styleAsset = 'assets/styles/basic.json';

  String get apiKey => dotenv.env['GEBETA_API_KEY']?.trim() ?? '';

  bool get isConfigured => apiKey.isNotEmpty;
}
