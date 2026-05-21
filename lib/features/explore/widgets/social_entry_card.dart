import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class SocialEntryCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final VoidCallback onTap;

  const SocialEntryCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        splashColor: iconColor.withValues(alpha: 0.1),
        highlightColor: iconColor.withValues(alpha: 0.05),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
