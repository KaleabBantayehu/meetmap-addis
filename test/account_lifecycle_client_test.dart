import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meetmap_addis/core/repositories/auth_repository.dart';
import 'package:meetmap_addis/core/repositories/network_repository.dart';
import 'package:meetmap_addis/core/repositories/place_repository.dart';
import 'package:meetmap_addis/core/repositories/saved_repository.dart';
import 'package:meetmap_addis/core/services/best_effort_cleanup.dart';
import 'package:meetmap_addis/core/storage/cache_keys.dart';
import 'package:meetmap_addis/core/storage/local_storage_service.dart';
import 'package:meetmap_addis/providers/auth_provider.dart';
import 'package:meetmap_addis/providers/network_provider.dart';
import 'package:meetmap_addis/providers/places_provider.dart';
import 'package:meetmap_addis/providers/saved_provider.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:meetmap_addis/shared/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  test('saved results from an old session are discarded', () async {
    final authRepository = _TestAuthRepository();
    final authProvider = AuthProvider(authRepository: authRepository);
    await authProvider.loginWithEmail('alice@example.com', 'password');
    final savedRepository = _DelayedSavedRepository();
    final provider = SavedProvider(
      savedRepository: savedRepository,
      authProvider: authProvider,
      isConnected: () => true,
    );
    await Future<void>.delayed(Duration.zero);

    await authProvider.loginWithEmail('bob@example.com', 'password');
    provider.syncSession('bob');
    await Future<void>.delayed(Duration.zero);

    savedRepository.requests[0].complete([_place('alice-place')]);
    await Future<void>.delayed(Duration.zero);
    expect(provider.savedPlaces, isEmpty);

    savedRepository.requests[1].complete([_place('bob-place')]);
    await Future<void>.delayed(Duration.zero);
    expect(provider.savedPlaces.single.id, 'bob-place');
    authProvider.dispose();
    provider.dispose();
  });

  test('network results from an old session are discarded', () async {
    final repository = _DelayedNetworkRepository();
    final provider = NetworkProvider(
      networkRepository: repository,
      isConnected: () => true,
    );
    provider.syncSession('alice');
    final request = provider.fetchNetworkData();
    await Future<void>.delayed(Duration.zero);

    provider.syncSession('bob');
    repository.suggested.complete([_testUser('alice-result')]);
    await request;

    expect(provider.suggestedUsers, isEmpty);
    expect(repository.trendingRequested, isFalse);
    provider.dispose();
  });

  test('best-effort cleanup continues after a failed operation', () async {
    final completed = <String>[];

    await runBestEffortCleanup([
      () async => completed.add('first'),
      () async => throw StateError('injected failure'),
      () async => completed.add('last'),
    ]);

    expect(completed, ['first', 'last']);
  });

  test('search history is isolated and restored by user session', () async {
    final storage = LocalStorageService.instance;
    await storage.remove(CacheKeys.searchHistoryForUser('alice'));
    await storage.remove(CacheKeys.searchHistoryForUser('bob'));
    await storage.remove(CacheKeys.searchHistoryForUser(null));
    final provider = PlacesProvider(placeRepository: _TestPlaceRepository());

    provider.syncSession('alice');
    await provider.addRecentSearch('coffee');
    expect(storage.getSearchHistory('alice'), ['coffee']);

    provider.syncSession('bob');
    expect(provider.recentSearches, isEmpty);
    await provider.addRecentSearch('lunch');
    expect(storage.getSearchHistory('bob'), ['lunch']);
    expect(provider.recentSearches, ['lunch']);

    provider.syncSession('alice');
    expect(provider.recentSearches, ['coffee']);
    provider.syncSession(null);
    expect(provider.recentSearches, isEmpty);
    provider.dispose();
  });

  test('legacy global search history does not enter a user session', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(CacheKeys.legacySearchHistory, ['legacy query']);
    await LocalStorageService.instance.remove(
      CacheKeys.searchHistoryForUser('alice'),
    );

    final provider = PlacesProvider(placeRepository: _TestPlaceRepository());
    provider.syncSession('alice');

    expect(provider.recentSearches, isEmpty);
    provider.dispose();
  });

  test('an old session search write cannot repopulate a new session', () async {
    final storage = LocalStorageService.instance;
    await storage.remove(CacheKeys.searchHistoryForUser('alice'));
    await storage.remove(CacheKeys.searchHistoryForUser('bob'));
    final provider = PlacesProvider(placeRepository: _TestPlaceRepository());
    provider.syncSession('alice');

    final aliceWrite = provider.addRecentSearch('alice query');
    provider.syncSession('bob');
    await aliceWrite;

    expect(provider.recentSearches, isEmpty);
    expect(storage.getSearchHistory('alice'), ['alice query']);
    expect(storage.getSearchHistory('bob'), isEmpty);
    provider.dispose();
  });
}

PlaceModel _place(String id) => PlaceModel(
  id: id,
  name: 'Test Place',
  imageUrl: '',
  category: 'Cafe',
  location: 'Addis Ababa',
  rating: 0,
  priceRange: r'$',
  isOpen: true,
  latitude: 9,
  longitude: 38,
  tags: const [],
  reviewCount: 0,
);

UserModel _testUser(String id) =>
    UserModel(id: id, name: id, profileImageUrl: '');

class _TestAuthRepository implements AuthRepository {
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _user;

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  Future<UserModel> login(String email, String password) async {
    _user = _testUser(email.startsWith('alice') ? 'alice' : 'bob');
    return _user!;
  }

  @override
  Future<void> logout() async => _user = null;

  @override
  Future<UserModel?> getCurrentUser() async => _user;

  @override
  Future<UserModel> signup(String email, String password, String name) =>
      login(email, password);

  @override
  Future<UserModel> signInWithGoogle() => login('alice@example.com', '');

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<UserModel> updateProfile(UserModel user) async => user;

  @override
  Future<void> deleteAccount() async => _user = null;
}

class _DelayedSavedRepository implements SavedRepository {
  final requests = <Completer<List<PlaceModel>>>[];

  @override
  Future<List<PlaceModel>> fetchSavedPlaces(String userId) {
    final request = Completer<List<PlaceModel>>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<bool> isSaved(String userId, String placeId) async => false;

  @override
  Future<void> toggleSaved(
    String userId,
    String placeId,
    bool isSaving,
  ) async {}

  @override
  Future<List<String>> getSavedPlaceIds() async => [];

  @override
  Future<void> removePlace(String placeId) async {}

  @override
  Future<void> savePlace(String placeId) async {}
}

class _DelayedNetworkRepository implements NetworkRepository {
  final suggested = Completer<List<UserModel>>();
  bool trendingRequested = false;

  @override
  Future<List<UserModel>> getSuggestedUsers() => suggested.future;

  @override
  Future<List<UserModel>> getTrendingReviewers() async {
    trendingRequested = true;
    return [];
  }

  @override
  Future<void> followUser(String currentUserId, String targetUserId) async {}

  @override
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {}

  @override
  Future<bool> isFollowing(String currentUserId, String targetUserId) async =>
      false;

  @override
  Future<int> getFollowerCount(String userId) async => 0;

  @override
  Future<int> getFollowingCount(String userId) async => 0;
}

class _TestPlaceRepository implements PlaceRepository {
  @override
  Future<PlaceModel> createPlace(PlaceModel place) async => place;

  @override
  Future<List<PlaceModel>> fetchFeaturedPlaces() async => [];

  @override
  Future<List<PlaceModel>> fetchPlaces() async => [];

  @override
  Future<PlaceModel?> fetchPlaceById(String id) async => null;

  @override
  Future<List<PlaceModel>> fetchSavedPlaces() async => [];

  @override
  Future<List<PlaceModel>> filterPlaces({
    String? category,
    String? priceRange,
    double? minRating,
    List<String>? amenities,
  }) async => [];

  @override
  Future<PlaceModel?> getPlaceById(String id) async => null;

  @override
  Future<List<PlaceModel>> getPlaces() async => [];

  @override
  Future<List<PlaceModel>> getSavedPlaces() async => [];

  @override
  Future<List<PlaceModel>> searchPlaces(String query) async => [];
}
