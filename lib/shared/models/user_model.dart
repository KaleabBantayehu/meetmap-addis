class UserModel {
  final String id;
  final String name;
  final String? username;
  final String profileImageUrl;
  final String? title; // e.g., "Tech Guru", "Art Curator"
  final String? bio;
  final int? followerCount;
  final List<String>? tags;
  final List<String>? recentImageUrls;
  final bool isFollowing;
  final bool isVerified;

  const UserModel({
    required this.id,
    required this.name,
    this.username,
    required this.profileImageUrl,
    this.title,
    this.bio,
    this.followerCount,
    this.tags,
    this.recentImageUrls,
    this.isFollowing = false,
    this.isVerified = false,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? profileImageUrl,
    String? title,
    String? bio,
    int? followerCount,
    List<String>? tags,
    List<String>? recentImageUrls,
    bool? isFollowing,
    bool? isVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      followerCount: followerCount ?? this.followerCount,
      tags: tags ?? this.tags,
      recentImageUrls: recentImageUrls ?? this.recentImageUrls,
      isFollowing: isFollowing ?? this.isFollowing,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
