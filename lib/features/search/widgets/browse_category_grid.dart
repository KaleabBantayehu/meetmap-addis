import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/search/widgets/search_section_header.dart';

class BrowseCategoryGrid extends StatelessWidget {
  const BrowseCategoryGrid({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  static const List<SearchBrowseCategory> categories = [
    SearchBrowseCategory(
      title: 'Cafes',
      icon: Icons.coffee_rounded,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.primaryLight,
    ),
    SearchBrowseCategory(
      title: 'Dining',
      icon: Icons.restaurant_rounded,
      backgroundColor: Color(0xFFA6ECE4),
      foregroundColor: AppColors.primary,
    ),
    SearchBrowseCategory(
      title: 'Nightlife & Bars',
      icon: Icons.nightlife_rounded,
      backgroundColor: Color(0xFFFFDAB0),
      foregroundColor: Color(0xFF6F3D00),
      isWide: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SearchSectionHeader(title: 'Browse by Category'),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = constraints.maxWidth >= 520 ? 18.0 : 16.0;
            final tileWidth = (constraints.maxWidth - gap) / 2;

            return Wrap(
              spacing: gap,
              runSpacing: 18,
              children: categories.map((category) {
                final width =
                    category.isWide ? constraints.maxWidth : tileWidth;
                return SizedBox(
                  width: width,
                  child: SearchCategoryTile(
                    category: category,
                    isSelected: selectedCategory == category.title,
                    onTap: () => onCategorySelected(category.title),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class SearchCategoryTile extends StatelessWidget {
  const SearchCategoryTile({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final SearchBrowseCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: category.backgroundColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 132,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: isSelected
                ? Border.all(color: AppColors.primaryDark, width: 2)
                : null,
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Icon(
                  category.icon,
                  color: category.foregroundColor,
                  size: 34,
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  category.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: category.foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                right: -24,
                bottom: -34,
                child: Icon(
                  category.icon,
                  color: category.foregroundColor.withValues(alpha: 0.2),
                  size: 98,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchBrowseCategory {
  const SearchBrowseCategory({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.isWide = false,
  });

  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isWide;
}
