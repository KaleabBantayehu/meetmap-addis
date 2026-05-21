import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/models/hangout_model.dart';
import 'recent_activity_tile.dart';

class RecentActivitySection extends StatelessWidget {
  final List<ActivityModel> activities;

  const RecentActivitySection({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: activities.length,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(left: 36, top: 16, bottom: 16),
          child: Divider(
            color: AppColors.outline.withValues(alpha: 0.3),
            height: 1,
          ),
        ),
        itemBuilder: (context, index) {
          return RecentActivityTile(
            activity: activities[index],
            isFirst: index == 0,
          );
        },
      ),
    );
  }
}
