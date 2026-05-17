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
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth * 0.82)
                .clamp(244.0, 300.0)
                .toDouble();

            return SizedBox(
              height: 174,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: profileReviewSamples.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return ProfileReviewCard(
                    review: profileReviewSamples[index],
                    width: cardWidth,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class ProfileReviewCard extends StatelessWidget {
  const ProfileReviewCard({super.key, required this.review, required this.width});

  final ProfileReviewData review;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to review detail when review IDs are available.
        },
        child: Container(
          width: width,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: ProfileReviewStars(rating: review.rating)),
                  Text(
                    review.timeAgo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                review.placeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '"${review.excerpt}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.78),
                  fontStyle: FontStyle.italic,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileReviewStars extends StatelessWidget {
  const ProfileReviewStars({super.key, required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        children: List.generate(5, (index) {
          return Icon(
            Icons.star_rounded,
            color: index < rating
                ? const Color(0xFF6F3D00)
                : AppColors.outline.withValues(alpha: 0.7),
            size: 21,
          );
        }),
      ),
    );
  }
}

class ProfileReviewData {
  const ProfileReviewData({
    required this.placeName,
    required this.excerpt,
    required this.timeAgo,
    required this.rating,
  });

  final String placeName;
  final String excerpt;
  final String timeAgo;
  final int rating;
}

const List<ProfileReviewData> profileReviewSamples = [
  ProfileReviewData(
    placeName: 'Tomoca Coffee, Bole',
    excerpt: 'Perfect spot for a morning networking session. The aroma is unmatched...',
    timeAgo: '2d ago',
    rating: 4,
  ),
  ProfileReviewData(
    placeName: 'Sheraton Addis',
    excerpt: 'Very quiet meeting corner. Ideal for signing important documents...',
    timeAgo: '1w ago',
    rating: 5,
  ),
];
