import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfilePlaceholderScreen(
      title: 'Edit Profile',
      icon: Icons.edit_rounded,
      message: 'Profile editing will connect to the user account API.',
    );
  }
}

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfilePlaceholderScreen(
      title: 'Settings',
      icon: Icons.settings_rounded,
      message: 'Settings will manage account, privacy, and app preferences.',
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfilePlaceholderScreen(
      title: 'Help & Support',
      icon: Icons.help_rounded,
      message: 'Support resources and contact options will live here.',
    );
  }
}

class ReviewHistoryScreen extends StatelessWidget {
  const ReviewHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfilePlaceholderScreen(
      title: 'My Reviews',
      icon: Icons.rate_review_rounded,
      message: 'Review history will load from the reviews API.',
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfilePlaceholderScreen(
      title: 'Notifications',
      icon: Icons.notifications_rounded,
      message: 'Notifications will show account and meeting updates.',
    );
  }
}

class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
