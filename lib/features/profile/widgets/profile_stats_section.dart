import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class ProfileStatsSection extends StatelessWidget {
  const ProfileStatsSection({
    super.key,
    required this.stats,
    required this.onStatSelected,
  });

  final List<ProfileStatData> stats;
  final ValueChanged<String> onStatSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int index = 0; index < stats.length; index++) ...[
            Expanded(
              child: ProfileStatTile(
                data: stats[index],
                onTap: () => onStatSelected(stats[index].label),
              ),
            ),
            if (index != stats.length - 1)
              Container(
                width: 1,
                height: 50,
                color: AppColors.surfaceVariant.withValues(alpha: 0.7),
              ),
          ],
        ],
      ),
    );
  }
}

class ProfileStatTile extends StatelessWidget {
  const ProfileStatTile({super.key, required this.data, required this.onTap});

  final ProfileStatData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileStatData {
  const ProfileStatData({required this.label, required this.value});

  final String label;
  final String value;
}
