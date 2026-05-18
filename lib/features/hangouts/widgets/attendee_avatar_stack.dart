import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

/// Overlapping circular avatar stack used in the hero and cards.
/// Renders up to [maxDisplay] colored initials circles, then a "+N" overflow.
class AttendeeAvatarStack extends StatelessWidget {
  final int totalCount;
  final int maxDisplay;
  final double size;

  const AttendeeAvatarStack({
    super.key,
    required this.totalCount,
    this.maxDisplay = 3,
    this.size = 32,
  });

  static const _palette = [
    Color(0xFF004D40), // primary green
    Color(0xFF136964), // secondary teal
    Color(0xFFF09E34), // accent amber
    Color(0xFF5D4037), // coffee brown
    Color(0xFF37474F), // slate
  ];

  static const _initials = ['A', 'B', 'C', 'D', 'E'];

  @override
  Widget build(BuildContext context) {
    final display = totalCount.clamp(0, maxDisplay);
    final overflow = totalCount > maxDisplay ? totalCount - maxDisplay : 0;
    final totalSlots = display + (overflow > 0 ? 1 : 0);
    final overlap = size * 0.32;
    final totalWidth = size + (totalSlots - 1) * (size - overlap);

    return SizedBox(
      width: totalWidth.clamp(size, double.infinity),
      height: size,
      child: Stack(
        children: [
          // Initials circles
          for (int i = 0; i < display; i++)
            Positioned(
              left: i * (size - overlap),
              child: _AvatarCircle(
                size: size,
                color: _palette[i % _palette.length],
                label: _initials[i % _initials.length],
              ),
            ),
          // Overflow badge
          if (overflow > 0)
            Positioned(
              left: display * (size - overlap),
              child: _AvatarCircle(
                size: size,
                color: AppColors.surfaceVariant,
                label: '+$overflow',
                textColor: AppColors.textPrimary,
                fontSize: size * 0.28,
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final double size;
  final Color color;
  final String label;
  final Color textColor;
  final double? fontSize;

  const _AvatarCircle({
    required this.size,
    required this.color,
    required this.label,
    this.textColor = Colors.white,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: fontSize ?? size * 0.34,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
