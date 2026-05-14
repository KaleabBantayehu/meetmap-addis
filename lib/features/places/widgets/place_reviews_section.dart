import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/reviews/screens/add_review_screen.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class PlaceReviewsSection extends StatelessWidget {
  const PlaceReviewsSection({super.key, required this.place});

  final PlaceModel place;

  static const List<_ReviewPreview> _reviews = [
    _ReviewPreview(
      author: 'Miriam A.',
      date: '2 days ago',
      rating: 5,
      text:
          'Great atmosphere for a quick meeting. The service was warm and the coffee was excellent.',
    ),
    _ReviewPreview(
      author: 'Dawit K.',
      date: '1 week ago',
      rating: 4,
      text:
          'Comfortable spot with reliable seating. It gets busy around lunch, but still worth it.',
    ),
    _ReviewPreview(
      author: 'Selam T.',
      date: '3 weeks ago',
      rating: 5,
      text:
          'Loved the location and calm mood. A good place to catch up with friends.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleReviews = _reviews.take(2).toList();

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
              TextButton(
                onPressed: () => _showAllReviews(context),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${place.rating.toStringAsFixed(1)} average from ${place.reviewCount} reviews',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ...visibleReviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ReviewTile(review: review),
            ),
          ),
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
  }

  void _showAllReviews(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            shrinkWrap: true,
            children: [
              Text(
                'All Reviews',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ..._reviews.map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ReviewTile(review: review),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final _ReviewPreview review;

  @override
  Widget build(BuildContext context) {
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
                child: Text(
                  review.author.isEmpty ? '?' : review.author[0],
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.author,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      review.date,
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
                  review.rating,
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
            review.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewPreview {
  const _ReviewPreview({
    required this.author,
    required this.date,
    required this.rating,
    required this.text,
  });

  final String author;
  final String date;
  final int rating;
  final String text;
}
