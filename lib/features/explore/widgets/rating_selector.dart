import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'custom_filter_chip.dart';

class RatingSelector extends StatelessWidget {
  final String selectedRating;
  final ValueChanged<String> onRatingSelected;

  const RatingSelector({
    super.key,
    required this.selectedRating,
    required this.onRatingSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Row(
            children: List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(
                  Icons.star_rounded,
                  size: 24,
                  color: index < 4 ? AppColors.accent : AppColors.outline,
                ),
              );
            }),
          ),
          const Spacer(),
          CustomFilterChip(
            label: '4.0+',
            isSelected: selectedRating == '4.0+',
            onTap: () => onRatingSelected('4.0+'),
          ),
          const SizedBox(width: 8),
          CustomFilterChip(
            label: '4.5+',
            isSelected: selectedRating == '4.5+',
            onTap: () => onRatingSelected('4.5+'),
          ),
        ],
      ),
    );
  }
}
