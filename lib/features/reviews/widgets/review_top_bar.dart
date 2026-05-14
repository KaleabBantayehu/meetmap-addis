import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class ReviewTopBar extends StatelessWidget {
  const ReviewTopBar({
    super.key,
    required this.onClose,
    required this.onPost,
  });

  final VoidCallback onClose;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary.withValues(alpha: 0.78),
              size: 34,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              'Write a Review',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onPost,
            child: Text(
              'Post',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
