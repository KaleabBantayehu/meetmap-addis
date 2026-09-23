import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/hangouts/screens/hangouts_screen.dart';
import 'package:meetmap_addis/features/navigation/screens/main_navigation.dart';
import 'package:meetmap_addis/routes/app_routes.dart';

class AppMenuButton extends StatelessWidget {
  const AppMenuButton({
    super.key,
    this.color,
    this.size,
    this.activeDestination,
  });

  final Color? color;
  final double? size;
  final String? activeDestination;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Open navigation',
      onPressed: () => _openNavigation(context),
      icon: Icon(
        Icons.menu_rounded,
        color: color ?? AppColors.primary,
        size: size ?? 28,
      ),
    );
  }

  Future<void> _openNavigation(BuildContext context) async {
    final destination = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close navigation',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, _) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              right: false,
              child: SizedBox(
                width: math.min(
                  MediaQuery.sizeOf(dialogContext).width * 0.82,
                  320,
                ),
                height: double.infinity,
                child: _AppNavigationDrawer(
                  activeDestination:
                      activeDestination ?? _bottomDestinationName(),
                  onSelected: (value) => Navigator.of(dialogContext).pop(value),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
    );

    if (destination == null || !context.mounted) return;
    _navigate(context, destination);
  }

  String _bottomDestinationName() {
    return switch (MainNavigation.selectedIndexNotifier.value) {
      0 => 'Home',
      1 => 'Explore',
      2 => 'Events',
      3 => 'Profile',
      _ => 'Home',
    };
  }

  void _navigate(BuildContext context, String destination) {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);

    switch (destination) {
      case 'Home':
        MainNavigation.setIndex(0);
      case 'Explore':
        MainNavigation.setIndex(1);
      case 'Events':
        MainNavigation.setIndex(2);
      case 'Profile':
        MainNavigation.setIndex(3);
      case 'Hangouts':
        navigator.push(
          MaterialPageRoute(builder: (_) => const HangoutsScreen()),
        );
      case 'Networking':
        navigator.pushNamed(AppRoutes.network);
      case 'Saved':
        navigator.pushNamed(AppRoutes.saved);
      case 'Settings':
        navigator.pushNamed(AppRoutes.settings);
    }
  }
}

class _AppNavigationDrawer extends StatelessWidget {
  const _AppNavigationDrawer({
    required this.activeDestination,
    required this.onSelected,
  });

  final String activeDestination;
  final ValueChanged<String> onSelected;

  static const _destinations = <(String, IconData)>[
    ('Home', Icons.home_rounded),
    ('Explore', Icons.explore_rounded),
    ('Events', Icons.event_rounded),
    ('Hangouts', Icons.groups_rounded),
    ('Networking', Icons.people_alt_rounded),
    ('Saved', Icons.bookmark_rounded),
    ('Profile', Icons.person_rounded),
    ('Settings', Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 12, 18),
            color: AppColors.primary,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'MeetMap Addis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close navigation',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                for (final (label, icon) in _destinations)
                  _DrawerDestination(
                    label: label,
                    icon: icon,
                    selected: label == activeDestination,
                    onTap: () => onSelected(label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerDestination extends StatelessWidget {
  const _DrawerDestination({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        selected: selected,
        selectedColor: AppColors.primary,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(icon),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: selected ? const Icon(Icons.check_rounded, size: 20) : null,
        onTap: onTap,
      ),
    );
  }
}
