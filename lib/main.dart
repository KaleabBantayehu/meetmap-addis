import 'package:flutter/material.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/explore/screens/explore_screen.dart';
import 'features/profile/screens/profile_screen.dart';

void main() {
  runApp(const MeetMapApp());
}

class MeetMapApp extends StatelessWidget {
  const MeetMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MeetMap Addis',

      // Simple theme for now
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),

      // Start screen
      initialRoute: '/login',

      // Centralized routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainNavigation(),
        '/explore': (context) => const ExploreScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}