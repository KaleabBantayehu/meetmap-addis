import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/profile/screens/user_profile_screen.dart';
import 'package:meetmap_addis/shared/models/user_model.dart';

class SuggestionCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onFollow;
  final bool isFollowing;
  final bool isLoading;

  const SuggestionCard({
    super.key,
    required this.user,
    this.onFollow,
    this.isFollowing = false,
    this.isLoading = false,
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
      width: 150,
      margin: const EdgeInsets.only(right: 12, bottom: 10, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Tappable avatar
          GestureDetector(
            onTap: () => _openProfile(context),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.imagePlaceholder,
              child: ClipOval(
                child: user.profileImageUrl.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        color: AppColors.textSecondary,
                        size: 34,
                      )
                    : CachedNetworkImage(
                        imageUrl: user.profileImageUrl,
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                        placeholder: (_, url) =>
                            Container(color: AppColors.surfaceVariant),
                        errorWidget: (_, url, err) => const Icon(
                          Icons.person_rounded,
                          color: AppColors.textSecondary,
                          size: 34,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Tappable name
          GestureDetector(
            onTap: () => _openProfile(context),
            child: Text(
              user.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            user.title ?? '',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isFollowing ? AppColors.surfaceVariant : AppColors.primary,
                foregroundColor:
                    isFollowing ? AppColors.textPrimary : Colors.white,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isLoading ? '...' : (isFollowing ? 'FOLLOWING' : 'FOLLOW'),
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
