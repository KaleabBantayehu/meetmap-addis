import '../../shared/models/review_model.dart';
import 'page_result.dart';

abstract class ReviewRepository {
  Future<List<ReviewModel>> fetchReviews(String placeId);
  Future<PageResult<ReviewModel>> fetchReviewsPage(
    String placeId, {
    String? cursor,
    int limit = 15,
  });
  Future<ReviewModel> createReview(String placeId, ReviewModel review);
  Future<void> deleteReview(String reviewId, String placeId);
  Future<void> toggleLike(
    String reviewId,
    String placeId,
    String userId,
    bool isLiking,
  );
}
