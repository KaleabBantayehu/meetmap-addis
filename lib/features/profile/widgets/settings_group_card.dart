import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class SettingsGroupCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsGroupCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 24),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
