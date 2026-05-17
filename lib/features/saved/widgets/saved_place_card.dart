import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/saved/widgets/saved_place_actions.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class SavedPlaceCard extends StatelessWidget {
  const SavedPlaceCard({
    super.key,
    required this.place,
    required this.distanceLabel,
    required this.statusLabel,
    required this.isSaved,
    required this.onTap,
    required this.onSaveToggle,
    required this.onRemove,
  });

  final PlaceModel place;
  final String distanceLabel;
  final String statusLabel;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSaveToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SavedPlaceImage(
                imageUrl: place.imageUrl,
                statusLabel: statusLabel,
                isSaved: isSaved,
                onSaveToggle: onSaveToggle,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  height: 1.05,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SavedRatingPill(rating: place.rating),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${place.location}, Addis Ababa - $distanceLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${place.priceRange} - ${place.category}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SavedRemoveButton(onPressed: onRemove),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavedPlaceImage extends StatelessWidget {
  const SavedPlaceImage({
    super.key,
    required this.imageUrl,
    required this.statusLabel,
    required this.isSaved,
    required this.onSaveToggle,
  });

  final String imageUrl;
  final String statusLabel;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 8.8,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: AppColors.surfaceVariant),
            errorWidget: (_, _, _) => Container(
              color: AppColors.surfaceVariant,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: SavedStatusBadge(label: statusLabel),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: SavedBookmarkButton(
              isSaved: isSaved,
              onPressed: onSaveToggle,
            ),
          ),
        ],
      ),
    );
  }
}

class SavedStatusBadge extends StatelessWidget {
  const SavedStatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isOpen = label == 'Open Now';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.primary.withValues(alpha: 0.9)
            : AppColors.surfaceVariant.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isOpen ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class SavedRatingPill extends StatelessWidget {
  const SavedRatingPill({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
