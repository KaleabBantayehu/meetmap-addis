import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

enum AuthMethod { email, phone }

class AuthMethodSelector extends StatelessWidget {
  final AuthMethod selectedMethod;
  final ValueChanged<AuthMethod> onChanged;

  const AuthMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: () => onChanged(AuthMethod.email),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              'Email',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
