import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/profile/widgets/profile_section_header.dart';

class ProfileSavedCollections extends StatelessWidget {
  const ProfileSavedCollections({
    super.key,
    required this.onSeeMore,
    required this.onCollectionTap,
  });

  final VoidCallback onSeeMore;
  final VoidCallback onCollectionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileSectionHeader(
          title: 'Saved Collections',
          actionLabel: 'See More',
          onActionTap: onSeeMore,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = 18.0;
            final width = (constraints.maxWidth - gap) / 2;
            return Row(
              children: [
                SizedBox(
                  width: width,
                  child: SavedCollectionTile(
                    title: 'Co-working Cafes',
                    itemCount: 12,
                    imageUrl:
                        'https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=800&q=80',
                    onTap: onCollectionTap,
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  width: width,
                  child: SavedCollectionTile(
                    title: 'Lunch Meeting',
                    itemCount: 8,
                    imageUrl:
                        'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&w=800&q=80',
                    onTap: onCollectionTap,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class SavedCollectionTile extends StatelessWidget {
  const SavedCollectionTile({
    super.key,
    required this.title,
    required this.itemCount,
    required this.imageUrl,
    required this.onTap,
  });

  final String title;
  final int itemCount;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(color: AppColors.surfaceVariant),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(
                      Icons.collections_bookmark_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$itemCount items',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.76),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
