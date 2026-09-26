class CacheKeys {
  static const String activeUserSessionUid = 'active_user_session_uid';
  static const String privateUserSessionPrefix = 'private_user_session_';
  static const String legacyUserSession = 'user_session_secure';
  static const String savedPlaces = 'saved_places_cache';
  static const String savedPlaceIds = 'saved_place_ids_cache';
  static const String searchHistory = 'search_history_cache';
  static const String placesCache = 'all_places_cache';
  static const String eventsCache = 'events_cache';
  static const String hangoutsCache = 'hangouts_cache';
  static const String venuesCache = 'venues_cache';
  static const String activitiesCache = 'activities_cache';
  static const String suggestedUsersCache = 'suggested_users_cache';
  static const String trendingReviewersCache = 'trending_reviewers_cache';

  // Reviews: keyed per-place as 'reviews_cache_<placeId>'
  static const String reviewsCachePrefix = 'reviews_cache_';

  // Sync Timestamps
  static const String savedPlacesLastSync = 'saved_places_last_sync';
  static const String profileLastSync = 'profile_last_sync';

  // Helpers
  static String reviewsForPlace(String placeId) =>
      '$reviewsCachePrefix$placeId';

  static String privateUserSession(String userId) =>
      '$privateUserSessionPrefix$userId';

  static String savedPlacesForUser(String userId) => '${savedPlaces}_$userId';

  static String savedPlaceIdsForUser(String userId) =>
      '${savedPlaceIds}_$userId';

  static String savedPlacesLastSyncForUser(String userId) =>
      '${savedPlacesLastSync}_$userId';
}
