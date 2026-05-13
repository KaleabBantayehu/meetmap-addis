import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class PlacePreviewCard extends StatelessWidget {
  final PlaceModel place;

  const PlacePreviewCard({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA7F3D0),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'OPEN NOW',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Text(
                            '0.4 km away',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        place.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.accent,
                            size: 20,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            place.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Text(
                            '(1.2k)',
                            style: TextStyle(
                              color:
                                  AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(width: 18),

                          Text(
                            place.priceRange,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(width: 18),

                          Text(place.category),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CachedNetworkImage(
                    imageUrl: place.imageUrl,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.directions_rounded,
                      size: 28,
                    ),
                    label: const Text('Directions'),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              _ActionButton(
                icon: Icons.bookmark_rounded,
                onTap: () {
                  debugPrint('Bookmark tapped');
                },
              ),

              const SizedBox(width: 14),

              _ActionButton(
                icon: Icons.share_rounded,
                onTap: () {
                  debugPrint('Share tapped');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.outline,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}