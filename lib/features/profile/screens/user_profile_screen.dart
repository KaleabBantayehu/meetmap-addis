import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/providers/user_provider.dart';
import 'package:meetmap_addis/providers/network_provider.dart';
import 'package:meetmap_addis/providers/auth_provider.dart';
import 'package:meetmap_addis/shared/models/user_model.dart';

/// Displays the public profile of any user by [userId].
/// Loads data from Firestore via [UserProvider]. Follow state is managed
/// by [NetworkProvider].
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUser(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final isLoading = userProvider.isLoading(widget.userId);
        final user = userProvider.getUser(widget.userId);
        final error = userProvider.getError(widget.userId);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── App bar with avatar ──────────────────────────────────────
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                backgroundColor: AppColors.surface,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _ProfileHeroHeader(user: user),
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    if (isLoading) ...[
                      const SizedBox(height: 60),
                      const Center(child: CircularProgressIndicator()),
                    ] else if (error != null) ...[
                      const SizedBox(height: 60),
                      Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.person_off_outlined,
                              size: 56,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              error,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => context
                                  .read<UserProvider>()
                                  .refreshUser(widget.userId),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ] else if (user != null) ...[
                      _ProfileBody(user: user),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Hero header section ──────────────────────────────────────────────────────

class _ProfileHeroHeader extends StatelessWidget {
  const _ProfileHeroHeader({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user?.profileImageUrl ?? '';

    return Container(
      color: AppColors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 36),
          // Avatar
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: imageUrl.isEmpty
                  ? Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.surfaceVariant),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          // Name
          if (user != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user!.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                if (user!.isVerified) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, size: 18, color: Colors.blue),
                ],
              ],
            ),
          if (user?.username != null)
            Text(
              '@${user!.username}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Profile body ─────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        context.watch<AuthProvider>().currentUser?.id;
    final networkProvider = context.watch<NetworkProvider>();
    final isCurrentUser = currentUserId == user.id;
    final isFollowing = networkProvider.isFollowing(user.id);
    final isActionInProgress =
        networkProvider.isFollowActionInProgress(user.id);
    final followerCount = networkProvider.followerCountFor(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stats row ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _StatItem(
                label: 'Reviews',
                value: '${user.reviewIds.length}',
              ),
              _StatDivider(),
              _StatItem(label: 'Followers', value: _formatCount(followerCount)),
              _StatDivider(),
              _StatItem(
                label: 'Following',
                value: _formatCount(user.followingCount),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Follow button ────────────────────────────────────────────────
        if (!isCurrentUser && currentUserId != null && currentUserId.isNotEmpty)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isActionInProgress
                  ? null
                  : () => context.read<NetworkProvider>().toggleFollow(
                        currentUserId: currentUserId,
                        targetUser: user,
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isFollowing ? AppColors.surfaceVariant : AppColors.primary,
                foregroundColor:
                    isFollowing ? AppColors.textPrimary : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isActionInProgress
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        const SizedBox(height: 24),

        // ── Bio ──────────────────────────────────────────────────────────
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          Text(
            'About',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            user.bio!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Tags ─────────────────────────────────────────────────────────
        if (user.tags.isNotEmpty) ...[
          Text(
            'Interests',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.tags.map((tag) => _TagChip(tag: tag)).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ── Recent images ────────────────────────────────────────────────
        if (user.recentImageUrls.isNotEmpty) ...[
          Text(
            'Recent Places',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: user.recentImageUrls.length.clamp(0, 6),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: user.recentImageUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppColors.surfaceVariant),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.surfaceVariant),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.outline.withValues(alpha: 0.4),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
