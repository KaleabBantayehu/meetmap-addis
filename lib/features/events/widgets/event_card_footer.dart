import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

/// Footer row for an event card — shows attendee count and category badge.
class EventCardFooter extends StatelessWidget {
  final int attendeeCount;
  final String category;

  const EventCardFooter({
    super.key,
    required this.attendeeCount,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar stack placeholder
        _AttendeeAvatarStack(count: attendeeCount),

        const SizedBox(width: 8),

        Text(
          '+$attendeeCount going',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),

        const Spacer(),

        // Category badge
        _CategoryBadge(category: category),
      ],
    );
  }
}

class _AttendeeAvatarStack extends StatelessWidget {
  final int count;

  const _AttendeeAvatarStack({required this.count});

  static const _avatarColors = [
    Color(0xFF004D40),
    Color(0xFF136964),
    Color(0xFFF09E34),
  ];

  @override
  Widget build(BuildContext context) {
    const size = 26.0;
    const overlap = 8.0;
    const displayCount = 3;

    return SizedBox(
      width: size + (displayCount - 1) * (size - overlap),
      height: size,
      child: Stack(
        children: List.generate(displayCount, (index) {
          return Positioned(
            left: index * (size - overlap),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _avatarColors[index % _avatarColors.length],
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  Color _badgeColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'networking':
        return const Color(0xFF1565C0);
      case 'coffee':
        return const Color(0xFF5D4037);
      case 'music':
        return const Color(0xFF6A1B9A);
      case 'tech':
        return const Color(0xFF00695C);
      case 'startup':
        return const Color(0xFFE65100);
      case 'community':
        return const Color(0xFF2E7D32);
      case 'study':
        return const Color(0xFF37474F);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
