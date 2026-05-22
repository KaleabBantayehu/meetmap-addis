import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/review_model.dart';
import '../review_repository.dart';

class FirebaseReviewRepository implements ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ReviewModel _mapDocToReview(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['id'] = doc.id;
    return ReviewModel.fromMap(data);
  }

  @override
  Future<List<ReviewModel>> fetchReviews(String placeId) async {
    try {
      final snapshot = await _firestore
          .collection('places')
          .doc(placeId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 4));
      return snapshot.docs.map(_mapDocToReview).toList();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  @override
  Future<ReviewModel> createReview(String placeId, ReviewModel review) async {
    try {
      final docRef = _firestore
          .collection('places')
          .doc(placeId)
          .collection('reviews')
          .doc(review.id);
      
      final data = review.toMap();
      data['createdAt'] = FieldValue.serverTimestamp(); // Ensure accurate backend timestamp
      
      await docRef.set(data).timeout(const Duration(seconds: 4));
      return review;
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  @override
  Future<void> deleteReview(String reviewId, String placeId) async {
    try {
      await _firestore
          .collection('places')
          .doc(placeId)
          .collection('reviews')
          .doc(reviewId)
          .delete()
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  @override
  Future<void> toggleLike(String reviewId, String placeId, String userId, bool isLiking) async {
    try {
      final docRef = _firestore
          .collection('places')
          .doc(placeId)
          .collection('reviews')
          .doc(reviewId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) throw Exception('Review not found');

        final currentLikes = List<String>.from(doc.data()?['likedUserIds'] ?? []);
        if (isLiking) {
          if (!currentLikes.contains(userId)) currentLikes.add(userId);
        } else {
          currentLikes.remove(userId);
        }
        transaction.update(docRef, {'likedUserIds': currentLikes});
      }).timeout(const Duration(seconds: 4));
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }
}
