
import 'package:flutter/material.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/explore/screens/explore_screen.dart';
import '../features/navigation/screens/main_navigation.dart';
import '../features/profile/screens/profile_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const explore = '/explore';
  static const profile = '/profile';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    home: (context) => const MainNavigation(),
    explore: (context) => const ExploreScreen(),
    profile: (context) => const ProfileScreen(),
  };
}