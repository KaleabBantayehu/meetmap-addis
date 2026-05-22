import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SecureStorageService {
  static SecureStorageService? _instance;
  late final FlutterSecureStorage _storage;

  SecureStorageService._();

  static SecureStorageService get instance {
    if (_instance == null) {
      throw Exception('SecureStorageService must be initialized by calling init()');
    }
    return _instance!;
  }

  static Future<void> init() async {
    if (_instance != null) return;
    
    const storage = FlutterSecureStorage();
    _instance = SecureStorageService._().._storage = storage;
    
    // Warm up the secure storage mechanism to detect platform-level issues early
    try {
      await _instance!._storage.write(key: 'init_test', value: 'warmup');
      await _instance!._storage.delete(key: 'init_test');
    } catch (e) {
      debugPrint('SecureStorageService warmup failed: $e');
    }
  }

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
