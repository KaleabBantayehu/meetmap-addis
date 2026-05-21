import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class SignupHeader extends StatelessWidget {
  const SignupHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on_rounded,
            size: 42,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Create Account',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join MeetMap Addis and discover great places to meet, study, and relax.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
