import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/review_model.dart';
import '../review_repository.dart';

class FirebaseReviewRepository implements ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<ReviewModel>> getReviews(String placeId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('placeId', isEqualTo: placeId)
          .get();
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to load reviews: $e');
    }
  }

  @override
  Future<ReviewModel> submitReview(ReviewModel review) async {
    try {
      await _firestore.collection('reviews').doc(review.id).set(review.toMap());
      return review;
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }
}
