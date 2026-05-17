import 'package:flutter/material.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/explore/screens/explore_screen.dart';
import '../features/meetings/screens/meetings_screen.dart';
import '../features/navigation/screens/main_navigation.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/saved/screens/saved_screen.dart';
import '../features/search/screens/search_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const explore = '/explore';
  static const profile = '/profile';
  static const saved = '/saved';
  static const search = '/search';
  static const meetings = '/meetings';
  static const settings = '/settings';
  static const editProfile = '/edit-profile';
  static const helpSupport = '/help-support';
  static const reviewHistory = '/review-history';
  static const notifications = '/notifications';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    home: (context) => const MainNavigation(),
    explore: (context) => const ExploreScreen(),
    profile: (context) => const ProfileScreen(),
    saved: (context) => const SavedScreen(),
    search: (context) => const SearchScreen(),
    meetings: (context) => const MeetingsScreen(),
    settings: (context) => const ProfileSettingsScreen(),
    editProfile: (context) => const EditProfileScreen(),
    helpSupport: (context) => const HelpSupportScreen(),
    reviewHistory: (context) => const ReviewHistoryScreen(),
    notifications: (context) => const NotificationsScreen(),
  };
}
