import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/reviews/screens/add_review_screen.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:meetmap_addis/shared/models/review_model.dart';
import 'package:meetmap_addis/providers/reviews_provider.dart';
import 'package:meetmap_addis/providers/auth_provider.dart';

class PlaceReviewsSection extends StatelessWidget {
  const PlaceReviewsSection({super.key, required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewsProvider>(
      builder: (context, reviewsProvider, child) {
        final reviews = reviewsProvider.getReviews(place.id);
        final isLoading = reviewsProvider.isLoading(place.id);
        final visibleReviews = reviews.take(2).toList();

        // Calculate dynamic average if we have local reviews
        final averageRating = reviews.isEmpty
            ? place.rating
            : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                  reviews.length;

        final reviewCount = reviews.isEmpty
            ? place.reviewCount
            : reviews.length;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'User Reviews',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (reviews.length > 2)
                    TextButton(
                      onPressed: () => _showAllReviews(context, reviews),
                      child: const Text('View all'),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${averageRating.toStringAsFixed(1)} average from $reviewCount reviews',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              if (isLoading && reviews.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (reviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                ...visibleReviews.map(
                  (review) => Padding(
                    key: ValueKey(
                      review.id,
                    ), // Added unique key for list integrity
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ReviewTile(review: review, placeId: place.id),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.rate_review_rounded),
                  label: const Text('Write a Review'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final authProvider = context.read<AuthProvider>();
                    if (!authProvider.isAuthenticated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please log in to write a review'),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddReviewScreen(place: place),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAllReviews(BuildContext context, List<ReviewModel> allReviews) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            // Changed to builder pattern to protect memory and explicit index boundaries
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            shrinkWrap: true,
            itemCount: allReviews.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'All Reviews',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }
              final review = allReviews[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ReviewTile(review: review, placeId: place.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.placeId});

  final ReviewModel review;
  final String placeId;

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().currentUser?.id;
    final isOwnReview = currentUserId == review.userId;
    final isDeletedAuthor = review.userId == null;
    final reviewUserId = review.userId;

    // Defensively clamp rating count between 0 and 5 to protect list loop generation bounds
    final starCount = review.rating.round().clamp(0, 5);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(
                  Icons.person,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDeletedAuthor
                          ? 'Deleted user'
                          : isOwnReview
                          ? 'You'
                          : ((reviewUserId?.length ?? 0) > 4
                                ? 'User ${reviewUserId!.substring(0, 4)}'
                                : 'User'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  starCount,
                  (_) => const Icon(
                    Icons.star_rounded,
                    color: AppColors.accent,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.reviewText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          if (isOwnReview)
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  context.read<ReviewsProvider>().deleteReview(
                    review.id,
                    placeId,
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
