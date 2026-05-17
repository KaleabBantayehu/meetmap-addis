import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/profile/widgets/profile_avatar_section.dart';
import 'package:meetmap_addis/features/profile/widgets/profile_logout_button.dart';
import 'package:meetmap_addis/features/profile/widgets/profile_reviews_section.dart';
import 'package:meetmap_addis/features/profile/widgets/profile_saved_collections.dart';
import 'package:meetmap_addis/features/profile/widgets/profile_settings_panel.dart';
import 'package:meetmap_addis/features/profile/widgets/profile_stats_section.dart';
import 'package:meetmap_addis/features/profile/widgets/profile_top_bar.dart';
import 'package:meetmap_addis/routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ProfileTopBar(
              onBackPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
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
                        name: 'Selamawit T.',
                        email: 'selam.t@email.com',
                        imageUrl: 'https://i.pravatar.cc/300?img=47',
                        onEditPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.editProfile);
                        },
                      ),
                      const SizedBox(height: 34),
                      ProfileStatsSection(
                        stats: const [
                          ProfileStatData(label: 'Reviews', value: '12'),
                          ProfileStatData(label: 'Saved', value: '24'),
                          ProfileStatData(label: 'Meetings', value: '8'),
                        ],
                        onStatSelected: (label) {
                          if (label == 'Reviews') {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.reviewHistory);
                          } else if (label == 'Saved') {
                            Navigator.of(context).pushNamed(AppRoutes.saved);
                          } else if (label == 'Meetings') {
                            Navigator.of(context).pushNamed(AppRoutes.meetings);
                          }
                        },
                      ),
                      const SizedBox(height: 38),
                      ProfileReviewsSection(
                        onViewAll: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.reviewHistory,
                          );
                        },
                      ),
                      const SizedBox(height: 42),
                      ProfileSavedCollections(
                        onSeeMore: () {
                          Navigator.of(context).pushNamed(AppRoutes.saved);
                        },
                        onCollectionTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.saved);
                        },
                      ),
                      const SizedBox(height: 40),
                      ProfileSettingsPanel(
                        onSettingsTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.settings);
                        },
                        onHelpTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.helpSupport);
                        },
                      ),
                      const SizedBox(height: 34),
                      ProfileLogoutButton(
                        onPressed: () {
                          // TODO: Connect sign out to auth service and session cleanup.
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.login,
                            (route) => false,
                          );
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
