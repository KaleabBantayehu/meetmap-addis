import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/routes/app_routes.dart';
import 'package:meetmap_addis/shared/widgets/app_menu_button.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.surface,
      child: Row(
        children: [
          const AppMenuButton(
            size: 32,
            color: AppColors.primary,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'MeetMap Addis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),

          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.search),
            icon: const Icon(
              Icons.search_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
