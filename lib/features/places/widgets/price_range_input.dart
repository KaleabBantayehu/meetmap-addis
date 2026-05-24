import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class PriceRangeInput extends StatelessWidget {
  final int selectedPriceLevel;
  final ValueChanged<int> onPriceSelected;

  const PriceRangeInput({
    super.key,
    required this.selectedPriceLevel,
    required this.onPriceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: PlaceModel.priceLevels.map((level) {
        final isSelected = selectedPriceLevel == level;
        return Padding(
          padding: EdgeInsets.only(
            bottom: level == PlaceModel.priceLevels.last ? 0 : 10,
          ),
          child: GestureDetector(
            onTap: () => onPriceSelected(level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.surface
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.outline,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      PlaceModel.priceLabelFor(level),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    PlaceModel.priceDisplayFor(level),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
