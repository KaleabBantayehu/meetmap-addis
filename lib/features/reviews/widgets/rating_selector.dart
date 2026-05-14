import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class RatingSelector extends StatelessWidget {
  const RatingSelector({
    super.key,
    required this.placeName,
    required this.rating,
    required this.onRatingChanged,
  });

  final String placeName;
  final int rating;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Overall Rating',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'How would you rate your experience at $placeName?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.74),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 38),
          LayoutBuilder(
            builder: (context, constraints) {
              final starSize = (constraints.maxWidth / 6)
                  .clamp(48.0, 68.0)
                  .toDouble();

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  final isSelected = starValue <= rating;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(starSize / 2),
                      onTap: () => onRatingChanged(starValue),
                      child: AnimatedScale(
                        scale: isSelected ? 1.0 : 0.92,
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOut,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            child: Icon(
                              Icons.star_rounded,
                              key: ValueKey<bool>(isSelected),
                              size: starSize,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
