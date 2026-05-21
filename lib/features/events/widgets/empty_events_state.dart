import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

/// Shown when the events list is empty (e.g., no results for selected filter).
class EmptyEventsState extends StatelessWidget {
  const EmptyEventsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'No events found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text(
              'Try a different category or\ncheck back again later.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
