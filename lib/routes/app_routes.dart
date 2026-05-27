import 'package:flutter/material.dart';

import '../features/auth/screens/auth_gate.dart';
import '../features/explore/screens/explore_screen.dart';
import '../features/explore/screens/filter_screen.dart';
import '../features/navigation/screens/main_navigation.dart';
import '../features/places/screens/add_place_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/profile/screens/help_support_screen.dart';
import '../features/saved/screens/saved_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/network/screens/network_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const explore = '/explore';
  static const profile = '/profile';
  static const userProfile = '/user-profile';
  static const saved = '/saved';
  static const search = '/search';
  static const filters = '/filters';
  static const settings = '/settings';
  static const editProfile = '/edit-profile';
  static const helpSupport = '/help-support';
  static const reviewHistory = '/review-history';
  static const notifications = '/notifications';
  static const addPlace = '/add-place';
  static const network = '/network';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const AuthGate(),
    home: (context) => const MainNavigation(),
    explore: (context) => const ExploreScreen(),
    profile: (context) => const ProfileScreen(),
    // userProfile requires a userId argument — use MaterialPageRoute directly
    // e.g. Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: id)))
    saved: (context) => const SavedScreen(),
    search: (context) => const SearchScreen(),
    filters: (context) => const FilterScreen(),
    settings: (context) => const SettingsScreen(),
    editProfile: (context) => const EditProfileScreen(),
    helpSupport: (context) => const HelpSupportScreen(),
    // reviewHistory: (context) => const ReviewHistoryScreen(),
    // notifications: (context) => const NotificationsScreen(),
    addPlace: (context) => const AddPlaceScreen(),
    network: (context) => const NetworkScreen(),
  };
}
