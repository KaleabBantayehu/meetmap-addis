import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class AuthFooterLink extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onPressed;

  const AuthFooterLink({
    super.key,
    required this.text,
    required this.linkText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(
            linkText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
