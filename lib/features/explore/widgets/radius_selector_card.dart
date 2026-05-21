import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class RadiusSelectorCard extends StatelessWidget {
  final String currentRadius;
  final VoidCallback onTap;

  const RadiusSelectorCard({
    super.key,
    required this.currentRadius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.navigation_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Radius',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Currently within $currentRadius',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
