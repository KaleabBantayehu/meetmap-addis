import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/home/widgets/home_search_bar.dart';
import 'package:meetmap_addis/features/home/widgets/map_pin.dart';
import 'package:meetmap_addis/features/home/widgets/place_preview_card.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class HomeMapSection extends StatefulWidget {
  final PlaceModel place;

  const HomeMapSection({super.key, required this.place});

  @override
  State<HomeMapSection> createState() => _HomeMapSectionState();
}

class _HomeMapSectionState extends State<HomeMapSection> {
  int selectedCategoryIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
             'assets/images/placeholder_map.jpg',
            fit: BoxFit.cover,
          ),
        ),

        Positioned.fill(
          child: Container(color: AppColors.primary.withValues(alpha: 0.30)),
        ),

        const Positioned(top: 24, left: 20, right: 20, child: HomeSearchBar()),

        Positioned(
          top: 95,
          left: 20,
          right: 0,
          child: _CategoryRow(
            selectedIndex: selectedCategoryIndex,
            onCategorySelected: (index) {
              setState(() {
                selectedCategoryIndex = index;
              });
            },
          ),
        ),

        const Positioned(
          top: 250,
          left: 120,
          child: MapPin(icon: Icons.coffee_rounded),
        ),

        const Positioned(
          top: 170,
          right: 90,
          child: MapPin(icon: Icons.restaurant_rounded),
        ),

        const Positioned(
          bottom: 290,
          left: 230,
          child: MapPin(icon: Icons.restaurant_rounded),
        ),

        Positioned(
          left: 16,
          right: 16,
          bottom: 0,
          child: PlacePreviewCard(place: widget.place),
        ),

        Positioned(
          right: 20,
          bottom: 320,
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  const _CategoryRow({
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ['Cafes', 'Restaurants', 'Coworking', 'Parks'];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.only(right: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onCategorySelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.outline),
              ),
              child: Center(
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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
