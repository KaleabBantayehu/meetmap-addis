import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () {},
                child: const Icon(
                  Icons.search_rounded,
                  size: 28,
                  color: AppColors.textSecondary,
                ),
              ),
        
              const SizedBox(width: 12),
        
              Expanded(
                child: Text(
                  'Search venues in Addis...',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                ),
              ),
        
              Container(width: 1, height: 30, color: AppColors.outline),
        
              const SizedBox(width: 12),
        
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () {},
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
