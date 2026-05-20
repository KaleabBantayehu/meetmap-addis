import '../../shared/models/review_model.dart';

abstract class ReviewRepository {
  Future<List<ReviewModel>> getReviews(String placeId);
  Future<ReviewModel> submitReview(ReviewModel review);
}
