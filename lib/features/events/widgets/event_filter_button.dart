import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

/// Floating action button variant for triggering event filters.
/// Positioned via the screen's [floatingActionButton] slot.
class EventFilterButton extends StatelessWidget {
  final VoidCallback onTap;

  const EventFilterButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'events_filter',
      onPressed: onTap,
      backgroundColor: AppColors.primary,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
      label: const Text(
        'Filter',
        style: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }
}
