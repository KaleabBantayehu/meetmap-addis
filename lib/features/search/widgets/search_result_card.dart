import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.place,
    required this.distanceLabel,
    required this.isSaved,
    required this.onTap,
    required this.onSaveToggle,
  });

  final PlaceModel place;
  final String distanceLabel;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSaveToggle;

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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SearchResultImage(imageUrl: place.imageUrl),
                const SizedBox(width: 18),
                Expanded(
                  child: SearchResultInfo(place: place),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 92,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        distanceLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SearchSaveButton(
                        isSaved: isSaved,
                        onPressed: onSaveToggle,
                      ),
                    ],
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

class SearchResultImage extends StatelessWidget {
  const SearchResultImage({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 92,
        height: 92,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          width: 92,
          height: 92,
          color: AppColors.surfaceVariant,
        ),
        errorWidget: (_, _, _) => Container(
          width: 92,
          height: 92,
          color: AppColors.surfaceVariant,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class SearchResultInfo extends StatelessWidget {
  const SearchResultInfo({super.key, required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFF7A3F00), size: 20),
            const SizedBox(width: 4),
            Text(
              place.rating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '-',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.outline,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              place.priceRange,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${place.category} - ${place.location}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.82),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class SearchSaveButton extends StatelessWidget {
  const SearchSaveButton({
    super.key,
    required this.isSaved,
    required this.onPressed,
  });

  final bool isSaved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant.withValues(alpha: 0.72),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
      ),
    );
  }
}
