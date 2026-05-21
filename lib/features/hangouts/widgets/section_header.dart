import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

/// Reusable section header with a title and an optional action label + callback.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final IconData? actionIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (actionIcon != null) ...[
                  const SizedBox(width: 4),
                  Icon(actionIcon, size: 16, color: AppColors.primary),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
