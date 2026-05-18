import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class AmenitySelector extends StatelessWidget {
  final List<String> selectedAmenities;
  final ValueChanged<String> onToggleAmenity;

  const AmenitySelector({
    super.key,
    required this.selectedAmenities,
    required this.onToggleAmenity,
  });

  @override
  Widget build(BuildContext context) {
    final amenities = [
      {'name': 'WiFi', 'icon': Icons.wifi_rounded},
      {'name': 'Parking', 'icon': Icons.local_parking_rounded},
      {'name': 'Outdoor Seating', 'icon': Icons.deck_rounded},
      {'name': 'Quiet', 'icon': Icons.volume_mute_rounded},
      {'name': 'Power Outlet', 'icon': Icons.electrical_services_rounded},
      {'name': 'Smoking Area', 'icon': Icons.smoking_rooms_rounded},
    ];
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: amenities.map((amenityData) {
        final name = amenityData['name'] as String;
        final icon = amenityData['icon'] as IconData;
        final isSelected = selectedAmenities.contains(name);

        return GestureDetector(
          onTap: () => onToggleAmenity(name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.outline,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
