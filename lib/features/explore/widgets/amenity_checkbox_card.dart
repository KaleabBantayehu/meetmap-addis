import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class AmenityCheckboxCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isChecked;
  final VoidCallback onTap;

  const AmenityCheckboxCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked ? AppColors.primary : AppColors.outline,
            width: isChecked ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isChecked,
                onChanged: (val) => onTap(),
                activeColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  color: isChecked ? Colors.transparent : AppColors.outline,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
