import 'package:flutter/material.dart';
import '../core/repositories/repository_error_mapper.dart';
import '../core/repositories/review_repository.dart';
import '../shared/models/review_model.dart';
import '../core/storage/local_storage_service.dart';
import '../core/storage/connectivity_service.dart';
import 'auth_provider.dart';

class ReviewsProvider with ChangeNotifier {
  final ReviewRepository _reviewRepository;
  final AuthProvider _authProvider;
  final bool Function() _isConnected;

  ReviewsProvider({
    required ReviewRepository reviewRepository,
    required AuthProvider authProvider,
    bool Function()? isConnected,
  }) : _reviewRepository = reviewRepository,
       _authProvider = authProvider,
       _isConnected =
           isConnected ?? (() => ConnectivityService.instance.isConnected);

  final Map<String, List<ReviewModel>> _reviewsByPlace = {};
  Map<String, List<ReviewModel>> get reviewsByPlace => _reviewsByPlace;

  final Map<String, bool> _loadingStates = {};
  bool isLoading(String placeId) => _loadingStates[placeId] ?? false;
  final Map<String, bool> _loadingMoreStates = {};
  final Map<String, bool> _hasMoreStates = {};
  final Map<String, bool> _loadedStates = {};
  final Map<String, String?> _nextCursors = {};
  final Map<String, int> _requestGenerations = {};
  bool isLoadingMore(String placeId) => _loadingMoreStates[placeId] ?? false;
  bool hasMore(String placeId) => _hasMoreStates[placeId] ?? false;
  bool hasLoaded(String placeId) => _loadedStates[placeId] ?? false;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ReviewModel> getReviews(String placeId) {
    return _reviewsByPlace[placeId] ?? [];
  }

  void _loadFromCache(String placeId) {
    try {
      final cached = LocalStorageService.instance.getCachedReviews(placeId);
      if (cached.isNotEmpty) {
        _reviewsByPlace[placeId] = cached;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached reviews for $placeId: $e');
    }
  }

  Future<void> _saveToCache(String placeId) async {
    try {
      final reviews = _reviewsByPlace[placeId] ?? [];
      await LocalStorageService.instance.saveCachedReviews(placeId, reviews);
    } catch (e) {
      debugPrint('Error saving reviews to cache for $placeId: $e');
    }
  }

  Future<void> fetchReviews(String placeId) async {
    final generation = (_requestGenerations[placeId] ?? 0) + 1;
    _requestGenerations[placeId] = generation;
    _loadingStates[placeId] = true;
    _errorMessage = null;
    notifyListeners();

    // Load from cache first for fast UX
    _loadFromCache(placeId);

    try {
      if (_isConnected()) {
        final page = await _reviewRepository.fetchReviewsPage(placeId);
        if (_requestGenerations[placeId] != generation) return;
        _reviewsByPlace[placeId] = page.items;
        _nextCursors[placeId] = page.nextCursor;
        _hasMoreStates[placeId] = page.hasMore;
        _loadedStates[placeId] = true;
        await _saveToCache(placeId);
      }
    } catch (e) {
      _errorMessage = cleanExceptionMessage(e, 'Failed to load reviews');
      debugPrint('Failed to fetch reviews: $e');
    } finally {
      if (_requestGenerations[placeId] == generation) {
        _loadingStates[placeId] = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreReviews(String placeId) async {
    if (isLoadingMore(placeId) || !hasMore(placeId) || !_isConnected()) {
      return;
    }
    final generation = _requestGenerations[placeId] ?? 0;
    _loadingMoreStates[placeId] = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final page = await _reviewRepository.fetchReviewsPage(
        placeId,
        cursor: _nextCursors[placeId],
      );
      if (_requestGenerations[placeId] != generation) {
        return;
      }
      final reviews = _reviewsByPlace[placeId] ?? <ReviewModel>[];
      final ids = reviews.map((review) => review.id).toSet();
      reviews.addAll(page.items.where((review) => ids.add(review.id)));
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _reviewsByPlace[placeId] = reviews;
      _nextCursors[placeId] = page.nextCursor;
      _hasMoreStates[placeId] = page.hasMore;
      await _saveToCache(placeId);
    } catch (e) {
      if (_requestGenerations[placeId] == generation) {
        _errorMessage = cleanExceptionMessage(e, 'Failed to load more reviews');
      }
    } finally {
      if (_requestGenerations[placeId] == generation) {
        _loadingMoreStates[placeId] = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createReview(String placeId, ReviewModel review) async {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) {
      _errorMessage = 'Must be logged in to review.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;

    // Optimistic Insert
    final currentList = _reviewsByPlace[placeId] ?? [];
    _reviewsByPlace[placeId] = [review, ...currentList];
    await _saveToCache(placeId);
    notifyListeners();

    try {
      final savedReview = await _reviewRepository.createReview(placeId, review);
      // Replace optimistic instance with saved (which might have accurate backend ID/timestamp)
      final index = _reviewsByPlace[placeId]!.indexWhere(
        (r) => r.id == review.id,
      );
      if (index != -1) {
        _reviewsByPlace[placeId]![index] = savedReview;
        await _saveToCache(placeId);
        notifyListeners();
      }
      return true;
    } catch (e) {
      // Rollback
      debugPrint('Review creation failed. Rolling back. $e');
      _reviewsByPlace[placeId]!.removeWhere((r) => r.id == review.id);
      await _saveToCache(placeId);
      _errorMessage = cleanExceptionMessage(e, 'Failed to submit review.');
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteReview(String reviewId, String placeId) async {
    final currentUserId = _authProvider.currentUser?.id;
    if (currentUserId == null) {
      _errorMessage = 'Must be logged in to delete reviews.';
      notifyListeners();
      return;
    }

    final currentList = _reviewsByPlace[placeId] ?? [];
    final reviewIndex = currentList.indexWhere((r) => r.id == reviewId);
    if (reviewIndex == -1) return;

    final reviewToRestore = currentList[reviewIndex];
    if (reviewToRestore.userId != currentUserId) {
      _errorMessage = 'You are not authorized to delete this review.';
      notifyListeners();
      return;
    }

    // Optimistic Delete
    currentList.removeAt(reviewIndex);
    _reviewsByPlace[placeId] = currentList;
    await _saveToCache(placeId);
    notifyListeners();

    try {
      await _reviewRepository.deleteReview(reviewId, placeId);
    } catch (e) {
      // Rollback
      debugPrint('Review deletion failed. Rolling back. $e');
      currentList.insert(reviewIndex, reviewToRestore);
      _reviewsByPlace[placeId] = currentList;
      await _saveToCache(placeId);
      _errorMessage = 'Failed to delete review.';
      notifyListeners();
    }
  }

  Future<void> toggleLike(String reviewId, String placeId) async {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) {
      _errorMessage = 'Must be logged in to like reviews.';
      notifyListeners();
      return;
    }

    final currentList = _reviewsByPlace[placeId] ?? [];
    final reviewIndex = currentList.indexWhere((r) => r.id == reviewId);
    if (reviewIndex == -1) return;

    final review = currentList[reviewIndex];
    final likes = List<String>.from(review.likedUserIds);
    final isLiking = !likes.contains(userId);

    // Optimistic Toggle
    if (isLiking) {
      likes.add(userId);
    } else {
      likes.remove(userId);
    }

    currentList[reviewIndex] = review.copyWith(likedUserIds: likes);
    _reviewsByPlace[placeId] = currentList;
    await _saveToCache(placeId);
    notifyListeners();

    try {
      await _reviewRepository.toggleLike(reviewId, placeId, userId, isLiking);
    } catch (e) {
      // Rollback
      debugPrint('Like toggle failed. Rolling back. $e');
      if (isLiking) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }
      currentList[reviewIndex] = review.copyWith(likedUserIds: likes);
      _reviewsByPlace[placeId] = currentList;
      await _saveToCache(placeId);
      notifyListeners();
    }
  }
}
