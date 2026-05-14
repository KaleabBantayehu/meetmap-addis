import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/explore/widgets/explore_place_card.dart';
import 'package:meetmap_addis/features/places/screens/place_detail_screen.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int selectedCategoryIndex = 0;

  final categories = ['Cafés', 'Restaurants', 'Coworking', 'Hotels'];

  // 1. Fully populated list so the map function actually has items to render!
  final List<PlaceModel> places = [
    PlaceModel(
      id: '1',
      name: 'Tomoca Coffee',
      imageUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb',
      category: 'Cafe',
      location: 'Bole',
      rating: 4.8,
      isOpen: true,
      latitude: 9.03,
      longitude: 38.74,
      priceRange: '\$\$',
      reviewCount: 1200,
      tags: ['Study', 'History', 'Iconic'],
    ),
    PlaceModel(
      id: '2',
      name: 'Garden of Coffee',
      imageUrl: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085',
      category: 'Cafe',
      location: 'Kazanchis',
      rating: 4.9,
      isOpen: true,
      latitude: 9.02,
      longitude: 38.76,
      priceRange: '\$\$\$',
      reviewCount: 980,
      tags: ['Meeting', 'Date', 'Premium'],
    ),
    PlaceModel(
      id: '3',
      name: 'Work-at-Bole',
      imageUrl: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f',
      category: 'Coworking',
      location: 'Bole',
      rating: 4.5,
      isOpen: true,
      latitude: 9.01,
      longitude: 38.75,
      priceRange: '\$\$',
      reviewCount: 540,
      tags: ['Fast Wifi', 'Quiet', 'Networking'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _ExploreAppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 120,
                ),
                children: [
                  const _ExploreHeader(),

                  const SizedBox(height: 22),

                  _CategoryRow(
                    categories: categories,
                    selectedIndex: selectedCategoryIndex,
                    onCategorySelected: (index) {
                      setState(() {
                        selectedCategoryIndex = index;
                      });
                    },
                  ),

                  const SizedBox(height: 28),

                  // 2. The spread operator maps over the places and renders your new cards
                  ...places.map(
                    (place) => Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ExplorePlaceCard(
                        place: place,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlaceDetailScreen(place: place),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {},
        child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
      ),
    );
  }
}

// --- EXTRACTED WIDGET CLASSES ---

class _ExploreHeader extends StatelessWidget {
  const _ExploreHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Explore Addis',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _ExploreAppBar extends StatelessWidget {
  const _ExploreAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'MeetMap Addis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.4),
              ),
            ),
            child: ClipOval(
              child: Image.network(
                'https://i.pravatar.cc/150?img=12',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  const _CategoryRow({
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onCategorySelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Center(
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
