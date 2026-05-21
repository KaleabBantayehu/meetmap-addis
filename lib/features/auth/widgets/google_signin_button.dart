import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoogleSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Image.asset(
          'assets/images/google_logo.png',
          width: 24,
          height: 24,
        ),
        label: Text(
          'Continue with Google',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
