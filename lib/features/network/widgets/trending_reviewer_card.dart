import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:meetmap_addis/features/profile/screens/user_profile_screen.dart';

import '../../../core/constants/colors.dart';
import '../../../shared/models/user_model.dart';

class TrendingReviewerCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onFollow;
  final bool isFollowing;
  final bool isLoading;
  final int followerCount;

  const TrendingReviewerCard({
    super.key,
    required this.user,
    this.onFollow,
    this.isFollowing = false,
    this.isLoading = false,
    this.followerCount = 0,
  });

  void _openProfile(BuildContext context) {
    if (user.id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: user.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: avatar | info | follow button ──────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tappable avatar
              GestureDetector(
                onTap: () => _openProfile(context),
                child: _UserAvatar(
                  imageUrl: user.profileImageUrl,
                  radius: 30,
                ),
              ),
              const SizedBox(width: 12),

              // Name + username — Expanded prevents overflow
              Expanded(
                child: GestureDetector(
                  onTap: () => _openProfile(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name row with optional verified badge
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (user.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 15,
                              color: Colors.blue,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username ?? ''} · ${_followersLabel(followerCount)} followers',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Follow button — fixed width so it never causes overflow
              SizedBox(
                width: 96,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing
                        ? AppColors.surfaceVariant
                        : AppColors.primary,
                    foregroundColor: isFollowing
                        ? AppColors.textPrimary
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLoading
                        ? '...'
                        : (isFollowing ? 'Following' : 'Follow'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Bio ──────────────────────────────────────────────────────────
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              user.bio!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],

          // ── Tags ─────────────────────────────────────────────────────────
          if (user.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.tags.map((tag) => _buildTag(tag)).toList(),
            ),
          ],

          // ── Recent images ─────────────────────────────────────────────────
          if (user.recentImageUrls.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildImage(user.recentImageUrls[0]),
                ),
                if (user.recentImageUrls.length > 1) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildImage(user.recentImageUrls[1]),
                  ),
                ],
                if (user.recentImageUrls.length > 2) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLastImage(user.recentImageUrls[2]),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Container(color: AppColors.surfaceVariant),
          errorWidget: (_, __, ___) =>
              Container(color: AppColors.surfaceVariant),
        ),
      ),
    );
  }

  Widget _buildLastImage(String url) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: AppColors.surfaceVariant),
              errorWidget: (_, __, ___) =>
                  Container(color: AppColors.surfaceVariant),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              '+more',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _followersLabel(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }
}

// ── Shared reusable avatar widget ─────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.imageUrl, this.radius = 26});

  final String imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.imagePlaceholder,
      child: ClipOval(
        child: imageUrl.isEmpty
            ? Icon(
                Icons.person_rounded,
                color: AppColors.textSecondary,
                size: radius,
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: AppColors.surfaceVariant),
                errorWidget: (_, __, ___) => Icon(
                  Icons.person_rounded,
                  color: AppColors.textSecondary,
                  size: radius,
                ),
              ),
      ),
    );
  }
}
