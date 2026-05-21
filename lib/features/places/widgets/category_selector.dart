import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ['Cafe', 'Restaurant', 'Coworking', 'Lounge'];
    final theme = Theme.of(context);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((category) {
        final isSelected = selectedCategory == category;
        return GestureDetector(
          onTap: () => onCategorySelected(category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  category,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
