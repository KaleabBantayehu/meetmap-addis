import '../models/user_model.dart';

class MockNetworkData {
  static const List<UserModel> suggestedUsers = [
    UserModel(
      id: '1',
      name: 'Dawit K.',
      profileImageUrl: 'https://i.pravatar.cc/150?u=dawit',
      title: 'Tech Guru',
    ),
    UserModel(
      id: '2',
      name: 'Lydia M.',
      profileImageUrl: 'https://i.pravatar.cc/150?u=lydia',
      title: 'Art Curator',
    ),
    UserModel(
      id: '3',
      name: 'Samuel G.',
      profileImageUrl: 'https://i.pravatar.cc/150?u=samuel',
      title: 'Architect',
    ),
    UserModel(
      id: '4',
      name: 'Eskender T.',
      profileImageUrl: 'https://i.pravatar.cc/150?u=eskender',
      title: 'Foodie',
    ),
  ];

  static const List<UserModel> trendingReviewers = [
    UserModel(
      id: 't1',
      name: 'Salem H.',
      username: 'salem_eats',
      profileImageUrl: 'https://i.pravatar.cc/150?u=salem',
      followerCount: 4200,
      bio: 'Chasing the best macchiato in Bole. Exploring Addis one plate of Tibs at a time. 🇪🇹☕',
      tags: ['COFFEE LOVER', 'FOOD CRITIC', 'TRADITIONAL'],
      recentImageUrls: [
        'https://images.unsplash.com/photo-1541167760496-162955ed8a9f?q=80&w=300&h=300&fit=crop',
        'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?q=80&w=300&h=300&fit=crop',
        'https://images.unsplash.com/photo-1615485290382-441e4d0c9cb5?q=80&w=300&h=300&fit=crop',
      ],
    ),
    UserModel(
      id: 't2',
      name: 'Brook T.',
      username: 'brook_arch',
      profileImageUrl: 'https://i.pravatar.cc/150?u=brook',
      followerCount: 2800,
      bio: 'Architectural photographer. Finding beauty in the urban sprawl of Addis. 🏗️📸',
      tags: ['DESIGN', 'PHOTOGRAPHY', 'NIGHTLIFE'],
      recentImageUrls: [
        'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=300&h=300&fit=crop',
        'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?q=80&w=300&h=300&fit=crop',
        'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?q=80&w=300&h=300&fit=crop',
      ],
    ),
  ];
}
