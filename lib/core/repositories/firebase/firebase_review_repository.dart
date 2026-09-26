import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/review_model.dart';
import '../review_repository.dart';
import '../page_result.dart';
import '../repository_error_mapper.dart';

class FirebaseReviewRepository implements ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ReviewModel _mapDocToReview(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['id'] = doc.id;
    return ReviewModel.fromMap(data);
  }

  @override
  Future<List<ReviewModel>> fetchReviews(String placeId) async {
    return (await fetchReviewsPage(placeId)).items;
  }

  @override
  Future<PageResult<ReviewModel>> fetchReviewsPage(
    String placeId, {
    String? cursor,
    int limit = 15,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('places')
          .doc(placeId)
          .collection('reviews')
          .orderBy(FieldPath.documentId, descending: true)
          .limit(limit + 1);
      if (cursor != null) query = query.startAfter([cursor]);
      final snapshot = await query
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 4));
      final hasMore = snapshot.docs.length > limit;
      final docs = snapshot.docs.take(limit).toList();
      final reviews = docs.map(_mapDocToReview).toList();
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return PageResult(
        items: reviews,
        nextCursor: docs.isEmpty ? null : docs.last.id,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to load reviews'));
    }
  }

  @override
  Future<ReviewModel> createReview(String placeId, ReviewModel review) async {
    try {
      final persistedReview = review.copyWith(placeId: placeId);
      final docRef = _firestore
          .collection('places')
          .doc(placeId)
          .collection('reviews')
          .doc(persistedReview.id);

      final data = persistedReview.toMap();
      data.remove('likedUserIds');
      data.remove('reportCount');
      data['createdAt'] =
          FieldValue.serverTimestamp(); // Ensure accurate backend timestamp

      // Firestore writes cannot be cancelled by Future.timeout. Timing out here
      // can report failure even though the write later commits successfully.
      await docRef.set(data);
      await _firestore.waitForPendingWrites();
      final savedSnapshot = await docRef.get(
        const GetOptions(source: Source.server),
      );
      if (!savedSnapshot.exists || savedSnapshot.metadata.hasPendingWrites) {
        throw Exception('Review was not saved');
      }
      return _mapDocToReview(savedSnapshot);
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to create review'));
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
      throw Exception(mapRepositoryError(e, 'Failed to delete review'));
    }
  }

  @override
  Future<void> toggleLike(
    String reviewId,
    String placeId,
    String userId,
    bool isLiking,
  ) async {
    try {
      final docRef = _firestore
          .collection('places')
          .doc(placeId)
          .collection('reviews')
          .doc(reviewId);

      await _firestore
          .runTransaction((transaction) async {
            final doc = await transaction.get(docRef);
            if (!doc.exists) throw Exception('Review not found');

            final currentLikes = List<String>.from(
              doc.data()?['likedUserIds'] ?? [],
            );
            if (isLiking) {
              if (!currentLikes.contains(userId)) currentLikes.add(userId);
            } else {
              currentLikes.remove(userId);
            }
            transaction.update(docRef, {'likedUserIds': currentLikes});
          })
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      throw Exception(mapRepositoryError(e, 'Failed to update review'));
    }
  }
}
