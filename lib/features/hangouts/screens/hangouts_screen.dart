import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/data/mock_hangouts.dart';
import 'package:meetmap_addis/routes/app_routes.dart';
import '../widgets/hangouts_header.dart';
import '../widgets/hangout_category_chips.dart';
import '../widgets/section_header.dart';
import '../widgets/active_hangout_card.dart';
import '../widgets/quick_hangout_card.dart';
import '../widgets/top_pick_venue_card.dart';
import '../widgets/recent_activity_section.dart';

void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Coming soon!'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ),
  );
}

class HangoutsScreen extends StatefulWidget {
  const HangoutsScreen({super.key});

  @override
  State<HangoutsScreen> createState() => _HangoutsScreenState();
}

class _HangoutsScreenState extends State<HangoutsScreen> {
  int _selectedCategoryIndex = 0;

  static const _categories = [
    'All',
    'Study',
    'Coffee',
    'Date',
    'Business',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showComingSoon(context),
        backgroundColor: AppColors.primaryDark,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 32,
        ),
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
                        const HangoutsHeader(onlineCount: 12),
                        
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
                        SectionHeader(
                          title: 'Active Now',
                          actionLabel: 'View Map',
                          actionIcon: Icons.map_outlined,
                          onActionTap: () => _showComingSoon(context),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        ActiveHangoutCard(
                          hangout: activeHangout,
                          onTap: () => _showComingSoon(context),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        ...quickHangouts.map(
                          (hangout) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: QuickHangoutCard(
                              hangout: hangout,
                              onTap: () => _showComingSoon(context),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Top Pick Venues Section
                        SectionHeader(
                          title: 'Top Pick Venues',
                          actionLabel: 'Explore all',
                          onActionTap: () => _showComingSoon(context),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          height: 210, // Fixed height for horizontal list
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: topPickVenues.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              return TopPickVenueCard(
                                venue: topPickVenues[index],
                                onTap: () => _showComingSoon(context),
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Recent Activity Section
                        const SectionHeader(
                          title: 'Recent Activity',
                        ),
                        
                        const SizedBox(height: 16),
                        
                        RecentActivitySection(activities: recentActivities),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.explore_outlined,
              size: 24,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
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
