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
    const options = ['Any', '3.0+', '3.5+', '4.0+', '4.5+'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map(
                  (option) => CustomFilterChip(
                    label: option,
                    isSelected: selectedRating == option,
                    onTap: () => onRatingSelected(option),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
