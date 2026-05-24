import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/providers/saved_provider.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:provider/provider.dart';

class PlacePreviewCard extends StatelessWidget {
  final PlaceModel place;

  const PlacePreviewCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final imageUrl = place.imageUrl.isNotEmpty
        ? place.imageUrl
        : (place.imageUrls.isNotEmpty ? place.imageUrls.first : '');
    final reviewLabel = place.reviewCount >= 1000
        ? '${(place.reviewCount / 1000).toStringAsFixed(1)}k'
        : place.reviewCount.toString();

    return Container(
      // REMOVED fixed height to allow dynamic sizing across different screen aspect ratios
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false, // Ensures padding respects device bottom navigation bars/notches safely
        child: Column(
          mainAxisSize: MainAxisSize.min, // Forces the sheet to cleanly hug its content
          children: [
            // Bottom Sheet Drag Handle Bar
            Container(
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.outline.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 20),

            // Main Details Row Block
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text Metadata Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status & Distance
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: place.isOpen
                                  ? const Color(0xFFA7F3D0)
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              place.isOpen ? 'OPEN NOW' : 'CLOSED',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              '0.4 km away',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Venue Name (Protected against extreme multi-line expansions)
                      Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                      ),

                      const SizedBox(height: 10),

                      // Stars, Rating, Price, and Category Row (Wrapped defensively)
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.accent,
                            size: 18,
                          ),
                          Text(
                            place.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '($reviewLabel)',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '•',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          Text(
                            place.priceRange,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '•',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          Text(
                            place.category,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Venue Preview Image (Kept uniform but flexible)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 95,
                    height: 95,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      width: 95,
                      height: 95,
                      color: AppColors.surfaceVariant,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Bottom Action Buttons Call to Action Row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.directions_rounded, size: 24),
                      label: const Text(
                        'Directions',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: context.watch<SavedProvider>().isSaved(place.id)
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  onTap: () => context.read<SavedProvider>().toggleSaved(place),
                ),
                const SizedBox(width: 12),
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
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
}