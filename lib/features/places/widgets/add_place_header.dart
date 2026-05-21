import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class AddPlaceHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AddPlaceHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primaryDark,
            size: 28,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
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
    );
  }
}
