import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/data/mock_events.dart';
import 'package:meetmap_addis/shared/models/event_model.dart';

import '../widgets/events_header.dart';
import '../widgets/event_category_chips.dart';
import '../widgets/featured_event_banner.dart';
import '../widgets/event_card.dart';
import '../widgets/event_filter_button.dart';
import '../widgets/empty_events_state.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int _selectedCategoryIndex = 0;

  static const _categories = [
    'All',
    'Networking',
    'Coffee',
    'Tech',
    'Music',
    'Startup',
    'Community',
    'Study',
  ];

  List<EventModel> get _filteredEvents {
    final selected = _categories[_selectedCategoryIndex];
    if (selected == 'All') return mockEvents;
    return mockEvents
        .where((e) => e.category.toLowerCase() == selected.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: EventFilterButton(onTap: () {}),
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar area (non-scrolling) ──────────────────────────────
            _EventsAppBar(),

            // ── Scrollable body ───────────────────────────────────────────
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Padding/header section
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: title + subtitle + filter icon
                          const EventsHeader(),

                          const SizedBox(height: 20),

                          // Featured banner
                          FeaturedEventBanner(
                            event: featuredEvent,
                            onTap: () {},
                          ),

                          const SizedBox(height: 24),

                          // Category chips
                          EventCategoryChips(
                            categories: _categories,
                            selectedIndex: _selectedCategoryIndex,
                            onCategorySelected: (index) {
                              setState(
                                  () => _selectedCategoryIndex = index);
                            },
                          ),

                          const SizedBox(height: 22),

                          // Section title
                          Row(
                            children: [
                              Text(
                                'Upcoming Events',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              const Spacer(),
                              if (filtered.isNotEmpty)
                                Text(
                                  '${filtered.length} events',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Event list or empty state ───────────────────────────
                  if (filtered.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyEventsState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final event = filtered[index];
                          return EventCard(
                            key: ValueKey(event.id),
                            event: event,
                            onTap: () {
                              // TODO: Navigate to EventDetailScreen(event)
                            },
                          );
                        },
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

class _EventsAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.menu_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'MeetMap Addis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.search_rounded,
              size: 26,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}