import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class PriceRangeInput extends StatelessWidget {
  final String selectedPrice;
  final ValueChanged<String> onPriceSelected;

  const PriceRangeInput({
    super.key,
    required this.selectedPrice,
    required this.onPriceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final prices = ['\$', '\$\$', '\$\$\$', '\$\$\$\$'];
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: prices.map((price) {
          final isSelected = selectedPrice == price;
          return Expanded(
            child: GestureDetector(
              onTap: () => onPriceSelected(price),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    price,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
