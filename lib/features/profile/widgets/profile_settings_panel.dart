import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class ProfileSettingsPanel extends StatelessWidget {
  const ProfileSettingsPanel({
    super.key,
    required this.onSettingsTap,
    required this.onHelpTap,
  });

  final VoidCallback onSettingsTap;
  final VoidCallback onHelpTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileMenuRow(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: onSettingsTap,
          ),
          Divider(height: 1, color: AppColors.surfaceVariant),
          ProfileMenuRow(
            icon: Icons.help_rounded,
            label: 'Help & Support',
            onTap: onHelpTap,
          ),
        ],
      ),
    );
  }
}

class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 30),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.75),
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
