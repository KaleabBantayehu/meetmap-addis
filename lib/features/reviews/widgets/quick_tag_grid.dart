import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/reviews/models/review_ui_models.dart';
import 'package:meetmap_addis/features/reviews/widgets/experience_input_field.dart';

class QuickTagGrid extends StatelessWidget {
  const QuickTagGrid({
    super.key,
    required this.tags,
    required this.selectedTags,
    required this.onTagSelected,
  });

  final List<ReviewTag> tags;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ReviewSectionLabel('QUICK TAGGING'),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tags.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3.35,
          ),
          itemBuilder: (context, index) {
            final tag = tags[index];
            final isSelected = selectedTags.contains(tag.label);

            return Material(
              color: isSelected
                  ? AppColors.primaryLight.withValues(alpha: 0.22)
                  : AppColors.surfaceVariant.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onTagSelected(tag.label),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(tag.icon, color: AppColors.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tag.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
