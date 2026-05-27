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
    final double ratingVal;
    if (selectedRating == 'Any') {
      ratingVal = 0.0;
    } else {
      ratingVal = double.tryParse(selectedRating.replaceAll('+', '')) ?? 0.0;
    }

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
              final starIndex = index + 1;
              final IconData icon;
              final Color color;
              if (ratingVal >= starIndex) {
                icon = Icons.star_rounded;
                color = AppColors.accent;
              } else if (ratingVal >= starIndex - 0.5) {
                icon = Icons.star_half_rounded;
                color = AppColors.accent;
              } else {
                icon = Icons.star_border_rounded;
                color = AppColors.outline;
              }
              return GestureDetector(
                onTap: () => onRatingSelected(options[index]),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
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
