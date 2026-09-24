import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/reviews/models/review_ui_models.dart';
import 'package:meetmap_addis/features/reviews/widgets/experience_input_field.dart';
import 'package:meetmap_addis/features/reviews/widgets/quick_tag_grid.dart';
import 'package:meetmap_addis/features/reviews/widgets/rating_selector.dart';
import 'package:meetmap_addis/features/reviews/widgets/review_top_bar.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:meetmap_addis/shared/models/review_model.dart';
import 'package:meetmap_addis/providers/reviews_provider.dart';
import 'package:meetmap_addis/providers/auth_provider.dart';

class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({super.key, required this.place});

  final PlaceModel place;

  @override
  AddReviewScreenState createState() => AddReviewScreenState();
}

class AddReviewScreenState extends State<AddReviewScreen> {
  int _rating = 4;
  bool _isSubmitting = false;
  final Set<String> _selectedTags = {};
  final TextEditingController _experienceController = TextEditingController();

  static const List<ReviewTag> reviewTags = [
    ReviewTag(label: 'Great Wi-Fi', icon: Icons.wifi_rounded),
    ReviewTag(label: 'Good Seating', icon: Icons.chair_rounded),
    ReviewTag(label: 'Affordable', icon: Icons.payments_rounded),
    ReviewTag(label: 'Excellent Staff', icon: Icons.volunteer_activism),
  ];

  @override
  void dispose() {
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ReviewTopBar(
              onClose: _isSubmitting
                  ? () {}
                  : () => Navigator.of(context).pop(),
              onPost: submitReview,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RatingSelector(
                      placeName: widget.place.name,
                      rating: _rating,
                      onRatingChanged: updateRating,
                    ),
                    const SizedBox(height: 56),
                    ExperienceInputField(controller: _experienceController),
                    const SizedBox(height: 42),
                    QuickTagGrid(
                      tags: reviewTags,
                      selectedTags: _selectedTags,
                      onTagSelected: toggleTag,
                    ),
                    const SizedBox(height: 56),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: AppColors.primary.withValues(
                            alpha: 0.22,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : submitReview,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Submit Review',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void updateRating(int rating) {
    setState(() => _rating = rating);
  }

  void toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> submitReview() async {
    if (_isSubmitting) return;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review')),
      );
      return;
    }

    final reviewText = _experienceController.text.trim();
    if (reviewText.isEmpty && _selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some details or select tags')),
      );
      return;
    }

    // Combine text and tags for the reviewText (simple approach for now)
    final combinedText = reviewText.isNotEmpty
        ? '$reviewText\n\nTags: ${_selectedTags.join(", ")}'
        : 'Tags: ${_selectedTags.join(", ")}';

    final review = ReviewModel(
      id: DateTime.now().millisecondsSinceEpoch
          .toString(), // Temporary ID for optimistic insert
      placeId: widget.place.id,
      userId: userId,
      rating: _rating.toDouble(),
      reviewText: combinedText.trim(),
      createdAt: DateTime.now(),
      likedUserIds: [],
    );

    setState(() => _isSubmitting = true);
    final reviewsProvider = context.read<ReviewsProvider>();
    final success = await reviewsProvider.createReview(widget.place.id, review);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reviewsProvider.errorMessage ??
                'Unable to submit review. Please try again.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted successfully.')),
    );
    Navigator.of(context).pop();
  }
}
