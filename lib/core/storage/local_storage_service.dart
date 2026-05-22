import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/place_model.dart';
import 'cache_keys.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  late final SharedPreferences _prefs;

  LocalStorageService._();

  static LocalStorageService get instance {
    if (_instance == null) {
      throw Exception('LocalStorageService must be initialized by calling init()');
    }
    return _instance!;
  }

  static Future<void> init() async {
    if (_instance != null) return;
    final prefs = await SharedPreferences.getInstance();
    _instance = LocalStorageService._().._prefs = prefs;
  }

  // --- Search History ---
  List<String> getSearchHistory() {
    return _prefs.getStringList(CacheKeys.searchHistory) ?? [];
  }

  Future<void> saveSearchHistory(List<String> history) async {
    await _prefs.setStringList(CacheKeys.searchHistory, history);
  }

  // --- Saved Place IDs ---
  List<String> getSavedPlaceIds() {
    return _prefs.getStringList(CacheKeys.savedPlaceIds) ?? [];
  }

  Future<void> saveSavedPlaceIds(List<String> ids) async {
    await _prefs.setStringList(CacheKeys.savedPlaceIds, ids);
  }

  // --- Saved Places Cache ---
  List<PlaceModel> getSavedPlaces() {
    final jsonStr = _prefs.getString(CacheKeys.savedPlaces);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded
          .map((item) => PlaceModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('Error parsing cached saved places: $e');
      return [];
    }
  }

  Future<void> saveSavedPlaces(List<PlaceModel> places) async {
    final List<Map<String, dynamic>> maps = places.map((p) => p.toMap()).toList();
    final jsonStr = json.encode(maps);
    await _prefs.setString(CacheKeys.savedPlaces, jsonStr);
  }

  // --- General Support for Timestamps and Metadata ---
  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> clearAll() => _prefs.clear();
}
