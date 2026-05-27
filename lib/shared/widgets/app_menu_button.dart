import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/routes/app_routes.dart';
import 'package:meetmap_addis/features/navigation/screens/main_navigation.dart';
import 'package:meetmap_addis/features/hangouts/screens/hangouts_screen.dart';

class AppMenuButton extends StatelessWidget {
  final Color? color;
  final double? size;

  const AppMenuButton({
    super.key,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.menu_rounded,
        color: color ?? AppColors.primary,
        size: size ?? 28,
      ),
      onSelected: (option) => _handleNavigation(context, option),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Home', child: Text('Home')),
        const PopupMenuItem(value: 'Explore', child: Text('Explore')),
        const PopupMenuItem(value: 'Events', child: Text('Events')),
        const PopupMenuItem(value: 'Hangouts', child: Text('Hangouts')),
        const PopupMenuItem(value: 'Networking', child: Text('Networking')),
        const PopupMenuItem(value: 'Saved', child: Text('Saved')),
        const PopupMenuItem(value: 'Profile', child: Text('Profile')),
        const PopupMenuItem(value: 'Settings', child: Text('Settings')),
      ],
    );
  }

  void _handleNavigation(BuildContext context, String option) {
    Navigator.of(context).popUntil((route) => route.isFirst);

    switch (option) {
      case 'Home':
        MainNavigation.setIndex(0);
        break;
      case 'Explore':
        MainNavigation.setIndex(1);
        break;
      case 'Events':
        MainNavigation.setIndex(2);
        break;
      case 'Profile':
        MainNavigation.setIndex(3);
        break;
      case 'Hangouts':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HangoutsScreen()),
        );
        break;
      case 'Networking':
        Navigator.of(context).pushNamed(AppRoutes.network);
        break;
      case 'Saved':
        Navigator.of(context).pushNamed(AppRoutes.saved);
        break;
      case 'Settings':
        Navigator.of(context).pushNamed(AppRoutes.settings);
        break;
    }
  }
}
