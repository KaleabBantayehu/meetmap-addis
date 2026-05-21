import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/widgets/dashed_border_painter.dart';

class ImageUploadSection extends StatelessWidget {
  final VoidCallback onTap;

  const ImageUploadSection({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: CustomPaint(
          painter: DashedBorderPainter(color: AppColors.outline, radius: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_a_photo_rounded,
                size: 40,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Tap or drag to upload',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'High quality photos attract more visits',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
