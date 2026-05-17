import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class PlaceInfoSection extends StatelessWidget {
  const PlaceInfoSection({super.key, required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final reviewLabel = place.reviewCount >= 1000
        ? '${(place.reviewCount / 1000).toStringAsFixed(1)}k reviews'
        : '${place.reviewCount} reviews';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _OpenStatusBadge(place: place),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _RatingMeta(place: place, reviewLabel: reviewLabel),
              _MetaDivider(),
              _TextMeta(value: place.priceRange),
              _MetaDivider(),
              _TextMeta(value: place.category),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: place.tags.map((tag) => _TrustChip(label: tag)).toList(),
          ),
        ],
      ),
    );
  }
}

class _OpenStatusBadge extends StatelessWidget {
  const _OpenStatusBadge({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: place.isOpen
            ? AppColors.primaryLight.withValues(alpha: 0.36)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        place.isOpen ? 'OPEN NOW' : 'CLOSED',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: place.isOpen ? AppColors.primaryDark : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _RatingMeta extends StatelessWidget {
  const _RatingMeta({required this.place, required this.reviewLabel});

  final PlaceModel place;
  final String reviewLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: AppColors.accent, size: 22),
        const SizedBox(width: 5),
        Text(
          place.rating.toStringAsFixed(1),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 5),
        Text(
          '($reviewLabel)',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _TextMeta extends StatelessWidget {
  const _TextMeta({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.primaryLight,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _MetaDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: AppColors.outline,
        shape: BoxShape.circle,
      ),
    );
  }
}
