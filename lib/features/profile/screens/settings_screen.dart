import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/providers/auth_provider.dart';
import 'package:meetmap_addis/routes/app_routes.dart';
import 'package:provider/provider.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_group_card.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_logout_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isResetLoading = false;
  bool _isDeletingAccount = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            SettingsHeader(
              name: user?.name ?? 'MeetMap User',
              imageUrl: user?.profileImageUrl ?? '',
              username: user?.username,
              email: user?.email,
              bio: user?.bio,
              onViewProfile: () {
                Navigator.of(context).pop();
              },
            ),

            SettingsGroupCard(
              title: 'ACCOUNT',
              children: [
                SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.editProfile),
                ),
                const Divider(height: 1, indent: 56),
                SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  onTap: _isResetLoading ? null : _sendResetEmail,
                ),
                const Divider(height: 1, indent: 56),
                SettingsTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete Account',
                  onTap: _isDeletingAccount ? null : _confirmDeleteAccount,
                ),
              ],
            ),

            SettingsGroupCard(
              title: 'PERSONAL',
              children: [
                SettingsTile(
                  icon: Icons.bookmark_outline_rounded,
                  title: 'Saved Places',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.saved),
                ),
              ],
            ),

            SettingsGroupCard(
              title: 'SUPPORT',
              children: [
                SettingsTile(
                  icon: Icons.policy_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Privacy Policy'),
                        content: const SingleChildScrollView(
                          child: Text(
                            'MeetMap Addis is committed to protecting your privacy. We collect location metrics, user reviews, and hangout coordinates exclusively to render local maps, calculate coordinate distance metrics, and personalize discovery within Addis Ababa.\n\nAll personal data, review history, and social network logs are secured within encrypted Firestore schemas, and we never sell user data to third parties.\n\nEffective Date: May 2026.',
                            style: TextStyle(height: 1.5),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            SettingsGroupCard(
              title: 'APP INFO',
              children: [
                const SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  subtitle: '1.0.0',
                  trailing: SizedBox.shrink(),
                ),
              ],
            ),

            SettingsLogoutButton(
              onPressed: () async {
                await context.read<AuthProvider>().signOut();
                if (!context.mounted) return;
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    final email = context.read<AuthProvider>().currentUser?.email?.trim() ?? '';
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email found for this account.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isResetLoading = true);
    final error = await context.read<AuthProvider>().resetPassword(email);
    if (!mounted) return;
    setState(() => _isResetLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Password reset email sent.'),
        backgroundColor: error == null ? AppColors.primary : AppColors.error,
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'Your account and private data will be permanently deleted. '
          'Public contributions may be retained without your identity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
    final authProvider = context.read<AuthProvider>();
    final deleted = await authProvider.deleteAccount();
    if (!mounted) return;
    setState(() => _isDeletingAccount = false);

    if (deleted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage ?? 'Unable to delete account.'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
