import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/providers/auth_provider.dart';
import 'package:meetmap_addis/routes/app_routes.dart';
import 'package:provider/provider.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_group_card.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_toggle_tile.dart';
import '../widgets/settings_logout_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushNotifications = true;
  bool emailAlerts = false;
  bool smsUpdates = false;
  bool darkMode = false;
  bool _isResetLoading = false;

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
                  icon: Icons.link_rounded,
                  title: 'Linked Accounts',
                  onTap: () {},
                ),
              ],
            ),

            SettingsGroupCard(
              title: 'PRIVACY & SECURITY',
              children: [
                SettingsTile(
                  icon: Icons.visibility_outlined,
                  title: 'Profile Visibility',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                SettingsTile(
                  icon: Icons.block_flipped,
                  title: 'Blocked Users',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                SettingsTile(
                  icon: Icons.share_outlined,
                  title: 'Data Sharing',
                  onTap: () {},
                ),
              ],
            ),

            SettingsGroupCard(
              title: 'NOTIFICATIONS',
              children: [
                SettingsToggleTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Push Notifications',
                  value: pushNotifications,
                  onChanged: (val) => setState(() => pushNotifications = val),
                ),
                const Divider(height: 1, indent: 56),
                SettingsToggleTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email Alerts',
                  value: emailAlerts,
                  onChanged: (val) => setState(() => emailAlerts = val),
                ),
                const Divider(height: 1, indent: 56),
                SettingsToggleTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'SMS Updates',
                  value: smsUpdates,
                  onChanged: (val) => setState(() => smsUpdates = val),
                ),
              ],
            ),

            SettingsGroupCard(
              title: 'APPEARANCE',
              children: [
                SettingsToggleTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  value: darkMode,
                  onChanged: (val) => setState(() => darkMode = val),
                ),
                const Divider(height: 1, indent: 56),
                SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'App Theme',
                  subtitle: 'DeepGreen',
                  onTap: () {},
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
                  icon: Icons.help_outline_rounded,
                  title: 'Help Center',
                  trailing: const Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: AppColors.outline,
                  ),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                SettingsTile(
                  icon: Icons.contact_support_outlined,
                  title: 'Contact Us',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                SettingsTile(
                  icon: Icons.policy_outlined,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
              ],
            ),

            SettingsGroupCard(
              title: 'APP INFO',
              children: [
                const SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  subtitle: '2.4.0',
                  trailing: SizedBox.shrink(),
                ),
                const Divider(height: 1, indent: 56),
                SettingsTile(
                  icon: Icons.star_outline_rounded,
                  title: 'Rate App',
                  onTap: () {},
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
}
