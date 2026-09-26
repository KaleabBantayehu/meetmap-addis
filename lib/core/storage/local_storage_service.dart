import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/event_model.dart';
import '../../shared/models/hangout_model.dart';
import '../../shared/models/place_model.dart';
import '../../shared/models/review_model.dart';
import '../../shared/models/user_model.dart';
import 'cache_keys.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  late final SharedPreferences _prefs;

  LocalStorageService._();

  static LocalStorageService get instance {
    if (_instance == null) {
      throw Exception(
        'LocalStorageService must be initialized by calling init()',
      );
    }
    return _instance!;
  }

  static Future<void> init() async {
    if (_instance != null) return;
    final prefs = await SharedPreferences.getInstance();
    _instance = LocalStorageService._().._prefs = prefs;
  }

  // --- Search History ---
  List<String> getSearchHistory(String? userId) {
    return _prefs.getStringList(CacheKeys.searchHistoryForUser(userId)) ?? [];
  }

  Future<void> saveSearchHistory(String? userId, List<String> history) async {
    await _prefs.setStringList(CacheKeys.searchHistoryForUser(userId), history);
  }

  // --- Saved Place IDs ---
  List<String> getSavedPlaceIds(String userId) {
    return _prefs.getStringList(CacheKeys.savedPlaceIdsForUser(userId)) ?? [];
  }

  Future<void> saveSavedPlaceIds(String userId, List<String> ids) async {
    await _prefs.setStringList(CacheKeys.savedPlaceIdsForUser(userId), ids);
  }

  // --- Saved Places Cache ---
  List<PlaceModel> getSavedPlaces(String userId) {
    final jsonStr = _prefs.getString(CacheKeys.savedPlacesForUser(userId));
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

  Future<void> saveSavedPlaces(String userId, List<PlaceModel> places) async {
    final List<Map<String, dynamic>> maps = places
        .map((p) => p.toMap())
        .toList();
    final jsonStr = json.encode(maps);
    await _prefs.setString(CacheKeys.savedPlacesForUser(userId), jsonStr);
  }

  // --- All Places Cache ---
  List<PlaceModel> getCachedPlaces() {
    final jsonStr = _prefs.getString(CacheKeys.placesCache);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded
          .map((item) => PlaceModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('Error parsing cached all places: $e');
      return [];
    }
  }

  Future<void> saveCachedPlaces(List<PlaceModel> places) async {
    final List<Map<String, dynamic>> maps = places
        .map((p) => p.toMap())
        .toList();
    final jsonStr = json.encode(maps);
    await _prefs.setString(CacheKeys.placesCache, jsonStr);
  }

  // --- Reviews Cache (per-place) ---
  List<ReviewModel> getCachedReviews(String placeId) {
    final jsonStr = _prefs.getString(CacheKeys.reviewsForPlace(placeId));
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded
          .map((item) => ReviewModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('Error parsing cached reviews for $placeId: $e');
      return [];
    }
  }

  Future<void> saveCachedReviews(
    String placeId,
    List<ReviewModel> reviews,
  ) async {
    final maps = reviews.map((r) => r.toMap()).toList();
    await _prefs.setString(
      CacheKeys.reviewsForPlace(placeId),
      json.encode(maps),
    );
  }

  Future<void> clearCachedReviews(String placeId) async {
    await _prefs.remove(CacheKeys.reviewsForPlace(placeId));
  }

  List<EventModel> getCachedEvents() {
    return _readModelList(CacheKeys.eventsCache, EventModel.fromMap);
  }

  Future<void> saveCachedEvents(List<EventModel> events) async {
    await _saveModelList(CacheKeys.eventsCache, events.map((e) => e.toMap()));
  }

  List<HangoutModel> getCachedHangouts() {
    return _readModelList(CacheKeys.hangoutsCache, HangoutModel.fromMap);
  }

  Future<void> saveCachedHangouts(List<HangoutModel> hangouts) async {
    await _saveModelList(
      CacheKeys.hangoutsCache,
      hangouts.map((h) => h.toMap()),
    );
  }

  List<VenueModel> getCachedVenues() {
    return _readModelList(CacheKeys.venuesCache, VenueModel.fromMap);
  }

  Future<void> saveCachedVenues(List<VenueModel> venues) async {
    await _saveModelList(CacheKeys.venuesCache, venues.map((v) => v.toMap()));
  }

  List<ActivityModel> getCachedActivities() {
    return _readModelList(CacheKeys.activitiesCache, ActivityModel.fromMap);
  }

  Future<void> saveCachedActivities(List<ActivityModel> activities) async {
    await _saveModelList(
      CacheKeys.activitiesCache,
      activities.map((a) => a.toMap()),
    );
  }

  List<UserModel> getCachedSuggestedUsers() {
    return _readModelList(CacheKeys.suggestedUsersCache, UserModel.fromMap);
  }

  Future<void> saveCachedSuggestedUsers(List<UserModel> users) async {
    await _saveModelList(
      CacheKeys.suggestedUsersCache,
      users.map((u) => u.toMap()),
    );
  }

  List<UserModel> getCachedTrendingReviewers() {
    return _readModelList(CacheKeys.trendingReviewersCache, UserModel.fromMap);
  }

  Future<void> saveCachedTrendingReviewers(List<UserModel> users) async {
    await _saveModelList(
      CacheKeys.trendingReviewersCache,
      users.map((u) => u.toMap()),
    );
  }

  List<T> _readModelList<T>(
    String key,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    final jsonStr = _prefs.getString(key);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded
          .map((item) => fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('Error parsing cache for $key: $e');
      return [];
    }
  }

  Future<void> _saveModelList(
    String key,
    Iterable<Map<String, dynamic>> maps,
  ) async {
    await _prefs.setString(key, json.encode(maps.toList()));
  }

  // --- General Support for Timestamps and Metadata ---
  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> clearAll() => _prefs.clear();
}
