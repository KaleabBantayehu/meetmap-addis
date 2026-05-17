import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class SavedBookmarkButton extends StatelessWidget {
  const SavedBookmarkButton({
    super.key,
    required this.isSaved,
    required this.onPressed,
  });

  final bool isSaved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 58,
          height: 58,
          child: Icon(
            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: AppColors.primary,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class SavedRemoveButton extends StatelessWidget {
  const SavedRemoveButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.34)),
        minimumSize: const Size(108, 42),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        'Remove',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
