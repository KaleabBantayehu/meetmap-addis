import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/places/screens/place_map_screen.dart';
import 'package:meetmap_addis/features/reviews/screens/add_review_screen.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class PlaceActionButtons extends StatelessWidget {
  const PlaceActionButtons({super.key, required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PlaceActionButton(
            icon: Icons.call_rounded,
            label: 'Call',
            semanticLabel: 'Copy phone number for ${place.name}',
            onTap: () {
              final phone = place.phone;
              if (phone != null && phone.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: phone));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Phone number copied: $phone'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No phone number available'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PlaceActionButton(
            icon: Icons.directions_rounded,
            label: 'Directions',
            semanticLabel: 'Get directions to ${place.name}',
            isPrimary: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaceMapScreen(place: place),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PlaceActionButton(
            icon: Icons.language_rounded,
            label: 'Website',
            semanticLabel: 'Open ${place.name} website',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PlaceActionButton(
            icon: Icons.rate_review_rounded,
            label: 'Review',
            semanticLabel: 'Review ${place.name}',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddReviewScreen(place: place),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlaceActionButton extends StatelessWidget {
  const _PlaceActionButton({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isPrimary ? Colors.white : AppColors.primary;
    final backgroundColor = isPrimary ? AppColors.primary : AppColors.surface;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isPrimary
                  ? null
                  : Border.all(
                      color: AppColors.outline.withValues(alpha: 0.55),
                    ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foregroundColor, size: 24),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
