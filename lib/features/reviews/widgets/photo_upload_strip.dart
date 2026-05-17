import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/reviews/models/review_ui_models.dart';
import 'package:meetmap_addis/features/reviews/widgets/experience_input_field.dart';

class PhotoUploadStrip extends StatelessWidget {
  const PhotoUploadStrip({
    super.key,
    required this.photos,
    this.onUploadTap,
    this.onRemovePhoto,
  });

  final List<ReviewPhoto> photos;
  final VoidCallback? onUploadTap;
  final ValueChanged<ReviewPhoto>? onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: ReviewSectionLabel('ADD PHOTOS')),
            Text(
              'Up to 10 photos',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              if (index == 0) {
                return UploadPhotoTile(onTap: onUploadTap);
              }

              final photo = photos[index - 1];
              return ReviewPhotoTile(
                photo: photo,
                onRemove: onRemovePhoto == null
                    ? null
                    : () => onRemovePhoto?.call(photo),
              );
            },
          ),
        ),
      ],
    );
  }
}

class UploadPhotoTile extends StatelessWidget {
  const UploadPhotoTile({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: DashedBorderPainter(),
      child: Material(
        color: AppColors.surfaceVariant.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 116,
            height: 116,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_a_photo_rounded,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  size: 30,
                ),
                const SizedBox(height: 10),
                Text(
                  'Upload',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.78),
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

class ReviewPhotoTile extends StatelessWidget {
  const ReviewPhotoTile({super.key, required this.photo, this.onRemove});

  final ReviewPhoto photo;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: photo.url,
            width: 116,
            height: 116,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(
              width: 116,
              height: 116,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 116,
              height: 116,
              color: AppColors.surfaceVariant,
              child: const Icon(Icons.error_outline, color: AppColors.error),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.black.withValues(alpha: 0.72),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onRemove,
              child: const SizedBox(
                width: 30,
                height: 30,
                child: Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(10),
        ),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + 7;
        final end = next > metric.length ? metric.length : next;
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = next + 6;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
