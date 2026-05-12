import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class PlaceCard extends StatelessWidget {
  final PlaceModel place;

  const PlaceCard({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final cardWidth = screenWidth > 600
        ? 340.0
        : (screenWidth - 40) * 0.9;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.05),
        onTap: () {},
        child: Container(
          width: cardWidth,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _PlaceCardImage(
                        imageUrl: place.imageUrl,
                      ),
                    ),

                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _OpenStatusBadge(
                        isOpen: place.isOpen,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${place.category} • ${place.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.accent,
                          size: 18,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          place.rating.toStringAsFixed(1),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),

                        const SizedBox(width: 6),

                        Text(
                          '(${place.reviewCount} reviews)',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),

                        const Spacer(),

                        Text(
                          place.priceRange,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                        ),
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

class _PlaceCardImage extends StatelessWidget {
  final String imageUrl;

  const _PlaceCardImage({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,

      placeholder: (context, url) {
        return Shimmer.fromColors(
          baseColor: AppColors.surfaceVariant,
          highlightColor: AppColors.surface,
          child: Container(
            color: AppColors.surfaceVariant,
          ),
        );
      },

      errorWidget: (context, url, error) {
        return Container(
          color: AppColors.surfaceVariant,
          child: const Center(
            child: Icon(
              Icons.photo_outlined,
              size: 36,
              color: AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

class _OpenStatusBadge extends StatelessWidget {
  final bool isOpen;

  const _OpenStatusBadge({
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withValues(alpha: 0.92)
            : Colors.red.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'OPEN NOW' : 'CLOSED',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}