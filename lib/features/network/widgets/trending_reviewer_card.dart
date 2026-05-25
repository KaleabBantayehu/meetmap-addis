import 'package:flutter/material.dart';

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
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(user.profileImageUrl),
                backgroundColor: AppColors.imagePlaceholder,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '@${user.username ?? ''} • ${_followersLabel(followerCount)} followers',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : onFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing
                      ? AppColors.surfaceVariant
                      : AppColors.primary,
                  foregroundColor: isFollowing ? AppColors.textPrimary : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  isLoading ? '...' : (isFollowing ? 'Following' : 'Follow'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (user.bio != null)
            Text(
              user.bio!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.tags.map((tag) => _buildTag(tag)).toList(),
          ),
          const SizedBox(height: 16),
          if (user.recentImageUrls.isNotEmpty)
            Row(
              children: [
                Expanded(child: _buildImage(user.recentImageUrls[0])),
                const SizedBox(width: 8),
                Expanded(child: _buildImage(user.recentImageUrls[1])),
                const SizedBox(width: 8),
                Expanded(
                  child: user.recentImageUrls.length > 2
                      ? _buildLastImage(user.recentImageUrls[2])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
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
        child: Image.network(url, fit: BoxFit.cover),
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
            child: Image.network(url, fit: BoxFit.cover),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              '+12',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
