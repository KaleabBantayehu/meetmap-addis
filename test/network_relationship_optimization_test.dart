import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meetmap_addis/core/repositories/mock/mock_network_repository.dart';
import 'package:meetmap_addis/core/repositories/network_repository.dart';
import 'package:meetmap_addis/core/storage/local_storage_service.dart';
import 'package:meetmap_addis/providers/network_provider.dart';
import 'package:meetmap_addis/shared/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  test(
    'discovery hydrates relationships with one repository contract call',
    () async {
      final repository = _RelationshipRepository();
      final provider = NetworkProvider(
        networkRepository: repository,
        isConnected: () => true,
      );
      provider.syncSession('alice');
      await provider.fetchNetworkData();
      await provider.loadFollowState('alice');

      expect(repository.summaryCalls, 1);
      expect(repository.singleStateCalls, 0);
      expect(provider.isFollowing('bob'), isTrue);
      expect(provider.isFollowing('carol'), isFalse);
      expect(provider.followerCountFor(_user('bob')), 4);
      expect(provider.followerCountFor(_user('carol')), 7);
      provider.dispose();
    },
  );

  test(
    'follow and unfollow keep state and authoritative count correct',
    () async {
      final repository = _RelationshipRepository();
      final provider = NetworkProvider(
        networkRepository: repository,
        isConnected: () => true,
      );
      provider.syncSession('alice');
      await provider.fetchNetworkData();
      await provider.loadFollowState('alice');

      expect(
        await provider.toggleFollow(
          currentUserId: 'alice',
          targetUser: _user('carol'),
        ),
        isTrue,
      );
      expect(provider.isFollowing('carol'), isTrue);
      expect(provider.followerCountFor(_user('carol')), 8);

      expect(
        await provider.toggleFollow(
          currentUserId: 'alice',
          targetUser: _user('carol'),
        ),
        isTrue,
      );
      expect(provider.isFollowing('carol'), isFalse);
      expect(provider.followerCountFor(_user('carol')), 7);
      expect(repository.relationships, contains('bob'));
      provider.dispose();
    },
  );

  test('old relationship response cannot populate a new session', () async {
    final repository = _DelayedRelationshipRepository();
    final provider = NetworkProvider(
      networkRepository: repository,
      isConnected: () => true,
    );
    provider.syncSession('alice');
    final request = provider.loadFollowState('alice');
    await Future<void>.delayed(Duration.zero);
    provider.syncSession('dave');
    repository.request.complete(
      const NetworkRelationshipSummary(
        followingUserIds: {'bob'},
        followerCounts: {'bob': 9},
      ),
    );
    await request;

    expect(provider.isFollowing('bob'), isFalse);
    expect(provider.followerCountFor(_user('bob')), 0);
    provider.dispose();
  });
}

class _RelationshipRepository extends MockNetworkRepository {
  final relationships = <String>{'bob'};
  final counts = <String, int>{'bob': 4, 'carol': 7};
  int summaryCalls = 0;
  int singleStateCalls = 0;

  @override
  Future<List<UserModel>> getSuggestedUsers() async => [
    _user('bob'),
    _user('carol'),
  ];

  @override
  Future<List<UserModel>> getTrendingReviewers() async => [
    _user('bob'),
    _user('carol'),
  ];

  @override
  Future<NetworkRelationshipSummary> getRelationshipSummary(
    String currentUserId,
    List<String> targetUserIds,
  ) async {
    summaryCalls++;
    return NetworkRelationshipSummary(
      followingUserIds: relationships.intersection(targetUserIds.toSet()),
      followerCounts: {for (final id in targetUserIds) id: counts[id] ?? 0},
    );
  }

  @override
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    singleStateCalls++;
    return relationships.contains(targetUserId);
  }

  @override
  Future<void> followUser(String currentUserId, String targetUserId) async {
    relationships.add(targetUserId);
    counts[targetUserId] = (counts[targetUserId] ?? 0) + 1;
  }

  @override
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    relationships.remove(targetUserId);
    counts[targetUserId] = (counts[targetUserId] ?? 1) - 1;
  }

  @override
  Future<int> getFollowerCount(String userId) async => counts[userId] ?? 0;
}

class _DelayedRelationshipRepository extends MockNetworkRepository {
  final request = Completer<NetworkRelationshipSummary>();

  @override
  Future<NetworkRelationshipSummary> getRelationshipSummary(
    String currentUserId,
    List<String> targetUserIds,
  ) => request.future;
}

UserModel _user(String id) => UserModel(id: id, name: id, profileImageUrl: '');
