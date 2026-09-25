import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/providers/auth_provider.dart';
import 'package:meetmap_addis/features/profile/widgets/profile_avatar_section.dart';
import 'package:meetmap_addis/features/profile/widgets/profile_logout_button.dart';
import 'package:meetmap_addis/features/profile/widgets/profile_settings_panel.dart';
import 'package:meetmap_addis/features/profile/widgets/profile_top_bar.dart';
import 'package:meetmap_addis/routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ProfileTopBar(
              onBackPressed: () async {
                final navigator = Navigator.of(context, rootNavigator: true);
                if (!await navigator.maybePop()) {
                  navigator.pushNamed(AppRoutes.explore);
                }
              },
              onSettingsPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.settings);
              },
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 360
                      ? 16.0
                      : constraints.maxWidth > 700
                      ? 32.0
                      : 20.0;

                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      28,
                      horizontalPadding,
                      34,
                    ),
                    children: [
                      ProfileAvatarSection(
                        name: user?.name ?? 'MeetMap User',
                        email: user?.email ?? 'No email available',
                        imageUrl: user?.profileImageUrl ?? '',
                        onEditPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.editProfile);
                        },
                      ),
                      const SizedBox(height: 40),
                      ProfileSettingsPanel(
                        onSettingsTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.settings);
                        },
                      ),
                      const SizedBox(height: 34),
                      ProfileLogoutButton(
                        onPressed: () async {
                          await Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.login,
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
