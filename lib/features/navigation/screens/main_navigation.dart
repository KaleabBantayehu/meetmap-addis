import 'package:flutter/material.dart';

import 'package:meetmap_addis/features/home/screens/home_screen.dart';
import 'package:meetmap_addis/features/explore/screens/explore_screen.dart';
import 'package:meetmap_addis/features/events/screens/events_screen.dart';
import 'package:meetmap_addis/features/profile/screens/profile_screen.dart';

import 'package:meetmap_addis/core/constants/colors.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  static final ValueNotifier<int> selectedIndexNotifier = ValueNotifier<int>(0);

  static void setIndex(int index) {
    selectedIndexNotifier.value = index;
  }

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    EventsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    MainNavigation.selectedIndexNotifier.value = 0;
    _currentIndex = 0;
    MainNavigation.selectedIndexNotifier.addListener(_onIndexChanged);
  }

  @override
  void dispose() {
    MainNavigation.selectedIndexNotifier.removeListener(_onIndexChanged);
    super.dispose();
  }

  void _onIndexChanged() {
    if (mounted) {
      setState(() {
        _currentIndex = MainNavigation.selectedIndexNotifier.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          MainNavigation.selectedIndexNotifier.value = index;
        },

        type: BottomNavigationBarType.fixed,

        backgroundColor: AppColors.surface,

        elevation: 10,

        selectedItemColor: AppColors.primary,

        unselectedItemColor: AppColors.textSecondary,

        selectedFontSize: 12,
        unselectedFontSize: 12,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.event_rounded),
            label: 'Events',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
