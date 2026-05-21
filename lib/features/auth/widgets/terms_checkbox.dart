import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              children: [
                const TextSpan(text: 'I agree to '),
                TextSpan(
                  text: 'Terms of Service',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: Navigate to Terms
                    },
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: Navigate to Privacy Policy
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
