class ProfileReviewData {
  const ProfileReviewData({
    required this.placeName,
    required this.excerpt,
    required this.timeAgo,
    required this.rating,
  });

  final String placeName;
  final String excerpt;
  final String timeAgo;
  final int rating;
}

const List<ProfileReviewData> profileReviewSamples = [
  ProfileReviewData(
    placeName: 'Tomoca Coffee, Bole',
    excerpt:
        'Perfect spot for a morning networking session. The aroma is unmatched...',
    timeAgo: '2d ago',
    rating: 4,
  ),
  ProfileReviewData(
    placeName: 'Sheraton Addis',
    excerpt:
        'Very quiet meeting corner. Ideal for signing important documents...',
    timeAgo: '1w ago',
    rating: 5,
  ),
];
