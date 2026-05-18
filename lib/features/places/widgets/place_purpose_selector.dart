import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class PlacePurposeSelector extends StatelessWidget {
  final List<String> selectedPurposes;
  final ValueChanged<String> onTogglePurpose;

  const PlacePurposeSelector({
    super.key,
    required this.selectedPurposes,
    required this.onTogglePurpose,
  });

  @override
  Widget build(BuildContext context) {
    final purposes = ['Study', 'Meeting', 'Date', 'Quiet', 'Outdoor'];
    final theme = Theme.of(context);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: purposes.map((purpose) {
        final isSelected = selectedPurposes.contains(purpose);
        return GestureDetector(
          onTap: () => onTogglePurpose(purpose),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryDark : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primaryDark : AppColors.outline,
              ),
            ),
            child: Text(
              purpose,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
