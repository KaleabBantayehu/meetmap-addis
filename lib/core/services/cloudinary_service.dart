import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> uploadImage(File imageFile, String folder) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']?.trim();
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET']?.trim();

    if (cloudName == null ||
        cloudName.isEmpty ||
        uploadPreset == null ||
        uploadPreset.isEmpty) {
      throw Exception('Cloudinary is not configured.');
    }

    try {
      final uri = Uri.https(
        'api.cloudinary.com',
        '/v1_1/$cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Unable to upload image');
      }

      final payload = json.decode(response.body) as Map<String, dynamic>;
      final secureUrl = payload['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('Unable to upload image');
      }

      return secureUrl;
    } on TimeoutException {
      throw Exception('Request timed out');
    } on SocketException {
      throw Exception('Network unavailable');
    } on FormatException {
      throw Exception('Unable to upload image');
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      if (message == 'Request timed out' ||
          message == 'Network unavailable' ||
          message == 'Unable to upload image' ||
          message == 'Cloudinary is not configured.') {
        throw Exception(message);
      }
      throw Exception('Unable to upload image');
    }
  }
}
