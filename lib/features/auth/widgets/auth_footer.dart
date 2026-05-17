import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class AuthFooter extends StatelessWidget {
  final VoidCallback onSignUpPressed;
  
  const AuthFooter({super.key, required this.onSignUpPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: onSignUpPressed,
          child: Text(
            'Sign Up',
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
