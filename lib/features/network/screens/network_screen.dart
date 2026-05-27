import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/network_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/app_menu_button.dart';
import '../widgets/network_search_bar.dart';
import '../widgets/suggestion_card.dart';
import '../widgets/trending_reviewer_card.dart';


class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NetworkProvider>();
      final currentUserId = context.read<AuthProvider>().currentUser?.id;
      if (provider.suggestedUsers.isEmpty && provider.trendingReviewers.isEmpty) {
        provider.fetchNetworkData().then((_) {
          if (!mounted || currentUserId == null || currentUserId.isEmpty) return;
          provider.loadFollowState(currentUserId);
        });
      } else if (currentUserId != null && currentUserId.isNotEmpty) {
        provider.loadFollowState(currentUserId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final networkProvider = context.watch<NetworkProvider>();
    final currentUserId = context.watch<AuthProvider>().currentUser?.id;
    final isSearch = networkProvider.hasActiveSearch;
    final suggested = (isSearch
            ? networkProvider.searchResults
            : networkProvider.suggestedUsers)
        .where((u) => currentUserId == null || u.id != currentUserId)
        .toList();
    final trending = (isSearch
            ? networkProvider.searchResults
            : networkProvider.trendingReviewers)
        .where((u) => currentUserId == null || u.id != currentUserId)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppMenuButton(
          color: AppColors.textPrimary,
          size: 24,
        ),
        title: const Text('Network'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Builder(builder: (context) {
              final avatarUrl =
                  context.watch<AuthProvider>().currentUser?.profileImageUrl ??
                      '';
              return GestureDetector(
                onTap: () {},
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.imagePlaceholder,
                  child: ClipOval(
                    child: avatarUrl.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            color: AppColors.textSecondary,
                            size: 18,
                          )
                        : CachedNetworkImage(
                            imageUrl: avatarUrl,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            placeholder: (_, url) =>
                                Container(color: AppColors.surfaceVariant),
                            errorWidget: (_, url, err) => const Icon(
                              Icons.person_rounded,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            NetworkSearchBar(
              onChanged: (value) {
                networkProvider.searchUsers(value);
              },
            ),
            const SizedBox(height: 24),
            if (!isSearch) _buildSectionHeader('Suggested for you', onSeeAll: () {}),
            const SizedBox(height: 16),
            _buildSuggestedList(
              networkProvider: networkProvider,
              currentUserId: currentUserId,
              suggested: suggested,
            ),
            const SizedBox(height: 32),
            if (!isSearch)
              const Text(
                'Trending Reviewers',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            const SizedBox(height: 16),
            _buildTrendingList(
              networkProvider: networkProvider,
              currentUserId: currentUserId,
              trending: trending,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedList({
    required NetworkProvider networkProvider,
    required String? currentUserId,
    required List<UserModel> suggested,
  }) {
    if (networkProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (suggested.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No users found.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggested.length,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          final user = suggested[index];
          return SuggestionCard(
            user: user,
            isFollowing: networkProvider.isFollowing(user.id),
            isLoading: networkProvider.isFollowActionInProgress(user.id),
            onFollow: currentUserId == null || currentUserId.isEmpty
                ? null
                : () => _onFollowTap(
                    networkProvider: networkProvider,
                    currentUserId: currentUserId,
                    user: user,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingList({
    required NetworkProvider networkProvider,
    required String? currentUserId,
    required List<UserModel> trending,
  }) {
    if (networkProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (trending.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No users found.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trending.length,
      itemBuilder: (context, index) {
        final user = trending[index];
        return TrendingReviewerCard(
          user: user,
          followerCount: networkProvider.followerCountFor(user),
          isFollowing: networkProvider.isFollowing(user.id),
          isLoading: networkProvider.isFollowActionInProgress(user.id),
          onFollow: currentUserId == null || currentUserId.isEmpty
              ? null
              : () => _onFollowTap(
                  networkProvider: networkProvider,
                  currentUserId: currentUserId,
                  user: user,
                ),
        );
      },
    );
  }

  Future<void> _onFollowTap({
    required NetworkProvider networkProvider,
    required String currentUserId,
    required UserModel user,
  }) async {
    final ok = await networkProvider.toggleFollow(
      currentUserId: currentUserId,
      targetUser: user,
    );
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          networkProvider.errorMessage ?? 'Unable to update follow status.',
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text(
            'View All',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
