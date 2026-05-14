import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class ExperienceInputField extends StatelessWidget {
  const ExperienceInputField({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ReviewSectionLabel('SHARE YOUR EXPERIENCE'),
        const SizedBox(height: 12),
        TextField(
          minLines: 7,
          maxLines: 7,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText:
                'What did you like or dislike? How was the service, atmosphere, and value for money?',
            hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.72),
              height: 1.5,
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant.withValues(alpha: 0.72),
            contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class ReviewSectionLabel extends StatelessWidget {
  const ReviewSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
