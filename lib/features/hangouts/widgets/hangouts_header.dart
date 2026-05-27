import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

/// Hero header: "CONNECT & CHILL" label + large Hangouts title.
class HangoutsHeader extends StatelessWidget {
  const HangoutsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Small eyebrow label
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'CONNECT & CHILL',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Large heading
        Text(
          'Hangouts',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
