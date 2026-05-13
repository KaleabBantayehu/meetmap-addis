import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class MapPin extends StatelessWidget {
  final IconData icon;

  const MapPin({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),

        Container(width: 5, height: 10, color: AppColors.primary),
      ],
    );
  }
}
