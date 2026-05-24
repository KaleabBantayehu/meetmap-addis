import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/profile/widgets/profile_section_header.dart';

class ProfileReviewsSection extends StatelessWidget {
  const ProfileReviewsSection({super.key, required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileSectionHeader(
          title: 'My Reviews',
          actionLabel: 'View All',
          onActionTap: onViewAll,
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'No reviews yet',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
