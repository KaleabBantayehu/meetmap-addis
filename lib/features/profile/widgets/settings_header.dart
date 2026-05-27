import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class SettingsHeader extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String? username;
  final String? email;
  final String? bio;
  final VoidCallback? onViewProfile;

  const SettingsHeader({
    super.key,
    required this.name,
    required this.imageUrl,
    this.username,
    this.email,
    this.bio,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.imagePlaceholder,
            backgroundImage: imageUrl.trim().isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            child: imageUrl.trim().isEmpty
                ? const Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (username != null && username!.isNotEmpty)
                  Text(
                    '@$username',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (email != null && email!.isNotEmpty)
                  Text(
                    email!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (bio != null && bio!.isNotEmpty)
                  Text(
                    bio!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onViewProfile,
                  child: const Text(
                    'VIEW PROFILE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.outline),
        ],
      ),
    );
  }
}
