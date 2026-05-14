import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/reviews/models/review_ui_models.dart';
import 'package:meetmap_addis/features/reviews/widgets/experience_input_field.dart';
import 'package:meetmap_addis/features/reviews/widgets/photo_upload_strip.dart';
import 'package:meetmap_addis/features/reviews/widgets/quick_tag_grid.dart';
import 'package:meetmap_addis/features/reviews/widgets/rating_selector.dart';
import 'package:meetmap_addis/features/reviews/widgets/review_top_bar.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({super.key, required this.place});

  final PlaceModel place;

  @override
  AddReviewScreenState createState() => AddReviewScreenState();
}

class AddReviewScreenState extends State<AddReviewScreen> {
  int _rating = 4;
  final Set<String> _selectedTags = {'Great Wi-Fi', 'Good Seating'};

  static const List<ReviewPhoto> reviewPhotos = [
    ReviewPhoto(
      url:
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=400&q=80',
    ),
    ReviewPhoto(
      url:
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=400&q=80',
    ),
    ReviewPhoto(
      url:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  static const List<ReviewTag> reviewTags = [
    ReviewTag(label: 'Great Wi-Fi', icon: Icons.wifi_rounded),
    ReviewTag(label: 'Good Seating', icon: Icons.chair_rounded),
    ReviewTag(label: 'Affordable', icon: Icons.payments_rounded),
    ReviewTag(label: 'Excellent Staff', icon: Icons.volunteer_activism),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ReviewTopBar(
              onClose: () => Navigator.of(context).pop(),
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
                    const ExperienceInputField(),
                    const SizedBox(height: 40),
                    const PhotoUploadStrip(photos: reviewPhotos),
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
                          shadowColor: AppColors.primary.withValues(alpha: 0.22),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: submitReview,
                        child: Text(
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

  void submitReview() {
    Navigator.of(context).pop();
  }
}
