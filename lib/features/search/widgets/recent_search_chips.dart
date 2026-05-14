import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/search/widgets/search_section_header.dart';

class RecentSearchChips extends StatelessWidget {
  const RecentSearchChips({
    super.key,
    required this.searches,
    required this.onSelected,
    required this.onRemove,
    required this.onClearAll,
  });

  final List<String> searches;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (searches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchSectionHeader(
          title: 'Recent Searches',
          trailing: TextButton(
            onPressed: onClearAll,
            child: Text(
              'Clear all',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: searches.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final search = searches[index];
              return RecentSearchChip(
                label: search,
                onTap: () => onSelected(search),
                onRemove: () => onRemove(search),
              );
            },
          ),
        ),
      ],
    );
  }
}

class RecentSearchChip extends StatelessWidget {
  const RecentSearchChip({
    super.key,
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(left: 20, right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              InkResponse(
                onTap: onRemove,
                radius: 18,
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary.withValues(alpha: 0.62),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
