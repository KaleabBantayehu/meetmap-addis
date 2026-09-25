import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/routes/app_routes.dart';
import 'package:meetmap_addis/shared/widgets/app_menu_button.dart';
import 'package:provider/provider.dart';
import '../../../providers/hangouts_provider.dart';
import '../screens/add_hangout_screen.dart';
import '../screens/hangout_detail_screen.dart';
import '../widgets/hangouts_header.dart';
import '../widgets/hangout_category_chips.dart';
import '../widgets/section_header.dart';
import '../widgets/active_hangout_card.dart';
import '../widgets/quick_hangout_card.dart';
import '../widgets/top_pick_venue_card.dart';
import '../widgets/recent_activity_section.dart';

class HangoutsScreen extends StatefulWidget {
  const HangoutsScreen({super.key});

  @override
  State<HangoutsScreen> createState() => _HangoutsScreenState();
}

class _HangoutsScreenState extends State<HangoutsScreen> {
  int _selectedCategoryIndex = 0;

  static const _categories = ['All', 'Study', 'Coffee', 'Date', 'Business'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<HangoutsProvider>(context, listen: false);
      if (provider.quickHangouts.isEmpty && provider.activeHangout == null) {
        provider.fetchHangouts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hangoutsProvider = Provider.of<HangoutsProvider>(context);
    final activeHangout = hangoutsProvider.activeHangout;
    final quickHangouts = hangoutsProvider.quickHangouts;
    final topPickVenues = hangoutsProvider.topPickVenues;
    final recentActivities = hangoutsProvider.recentActivities;
    final isLoading = hangoutsProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        heroTag: 'hangouts_add_hangout',
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddHangoutScreen())),
        backgroundColor: AppColors.primaryDark,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header Bar ──────────────────────────────────────────────
            _TopAppBar(),

            // ── Scrollable Body ───────────────────────────────────────────
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Hero section
                        const HangoutsHeader(),

                        const SizedBox(height: 24),

                        // Category chips
                        HangoutCategoryChips(
                          categories: _categories,
                          selectedIndex: _selectedCategoryIndex,
                          onSelected: (index) {
                            setState(() => _selectedCategoryIndex = index);
                          },
                        ),

                        const SizedBox(height: 32),

                        // Active Now Section
                        const SectionHeader(title: 'Active Now'),

                        const SizedBox(height: 16),

                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (hangoutsProvider.errorMessage != null &&
                            activeHangout == null &&
                            quickHangouts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 40,
                              horizontal: 20,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.error,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  hangoutsProvider.errorMessage!,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      hangoutsProvider.fetchHangouts(),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          if (activeHangout == null &&
                              quickHangouts.isEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 32,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.outline.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.people_outline_rounded,
                                      size: 32,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No active hangouts',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Be the first to start a hangout by tapping the add button!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ] else ...[
                            if (activeHangout != null) ...[
                              ActiveHangoutCard(
                                hangout: activeHangout,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => HangoutDetailScreen(
                                      hangout: activeHangout,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            ...quickHangouts.map(
                              (hangout) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: QuickHangoutCard(
                                  hangout: hangout,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          HangoutDetailScreen(hangout: hangout),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Top Pick Venues Section
                          SectionHeader(title: 'Top Pick Venues'),

                          const SizedBox(height: 16),

                          if (topPickVenues.isEmpty) ...[
                            Container(
                              height: 120,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.outline.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                              child: Text(
                                'No top venues available right now.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ] else
                            SizedBox(
                              height: 210, // Fixed height for horizontal list
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.none,
                                itemCount: topPickVenues.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 16),
                                itemBuilder: (context, index) {
                                  return TopPickVenueCard(
                                    venue: topPickVenues[index],
                                  );
                                },
                              ),
                            ),

                          if (recentActivities.isNotEmpty) ...[
                            const SizedBox(height: 32),

                            // Recent Activity Section
                            const SectionHeader(title: 'Recent Activity'),

                            const SizedBox(height: 16),

                            RecentActivitySection(activities: recentActivities),
                          ],
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App bar ────────────────────────────────────────────────────────────────

class _TopAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const AppMenuButton(
            color: AppColors.textPrimary,
            size: 26,
            activeDestination: 'Hangouts',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'MeetMap Addis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.search),
            icon: const Icon(
              Icons.search_rounded,
              size: 26,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
