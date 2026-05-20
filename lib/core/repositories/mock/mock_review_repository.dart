import '../../../shared/models/review_model.dart';
import '../review_repository.dart';

class MockReviewRepository implements ReviewRepository {
  final List<ReviewModel> _reviews = [
    ReviewModel(
      id: 'rev_1',
      placeId: '1',
      userId: 'u1',
      rating: 5.0,
      reviewText: 'Outstanding Ethiopian coffee experience. The atmosphere is vibrant and iconic!',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ReviewModel(
      id: 'rev_2',
      placeId: '1',
      userId: 'u2',
      rating: 4.0,
      reviewText: 'Perfect spot for a morning networking session. The aroma is unmatched.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ReviewModel(
      id: 'rev_3',
      placeId: '2',
      userId: 'u3',
      rating: 4.5,
      reviewText: 'Great selection of specialty coffees. Friendly staff and cozy space.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  Future<List<ReviewModel>> getReviews(String placeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _reviews.where((r) => r.placeId == placeId).toList();
  }

  @override
  Future<ReviewModel> submitReview(ReviewModel review) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newReview = ReviewModel(
      id: 'rev_${_reviews.length + 1}',
      placeId: review.placeId,
      userId: review.userId,
      rating: review.rating,
      reviewText: review.reviewText,
      createdAt: DateTime.now(),
    );
    _reviews.add(newReview);
    return newReview;
  }
}
