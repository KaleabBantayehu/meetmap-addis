import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({super.key, required this.place});

  final PlaceModel place;

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  int _rating = 4;
  final Set<String> _selectedTags = {'Great Wi-Fi', 'Good Seating'};

  static const List<_ReviewPhoto> _photos = [
    _ReviewPhoto(
      url:
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=400&q=80',
    ),
    _ReviewPhoto(
      url:
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=400&q=80',
    ),
    _ReviewPhoto(
      url:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  static const List<_ReviewTag> _tags = [
    _ReviewTag(label: 'Great Wi-Fi', icon: Icons.wifi_rounded),
    _ReviewTag(label: 'Good Seating', icon: Icons.chair_rounded),
    _ReviewTag(label: 'Affordable', icon: Icons.payments_rounded),
    _ReviewTag(label: 'Excellent Staff', icon: Icons.volunteer_activism),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _ReviewTopBar(
              onClose: () => Navigator.of(context).pop(),
              onPost: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _ratingSection(placeName: widget.place.name)),
                    const SizedBox(height: 56),
                    const _SectionLabel('SHARE YOUR EXPERIENCE'),
                    const SizedBox(height: 12),
                    const _ExperienceField(),
                    const SizedBox(height: 40),
                    const _PhotoHeader(),
                    const SizedBox(height: 18),
                    const _PhotoStrip(photos: _photos),
                    const SizedBox(height: 42),
                    const _SectionLabel('QUICK TAGGING'),
                    const SizedBox(height: 18),
                    _QuickTags(
                      tags: _tags,
                      selectedTags: _selectedTags,
                      onTagSelected: _toggleTag,
                    ),
                    const SizedBox(height: 56),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: AppColors.primary.withValues(alpha: 0.22),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Submit Review',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingSection({required String placeName}) {
    return Column(
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
                return GestureDetector(
                  onTap: () => setState(() => _rating = starValue),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      Icons.star_rounded,
                      size: starSize,
                      color: starValue <= _rating
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }
}

class _ReviewTopBar extends StatelessWidget {
  const _ReviewTopBar({required this.onClose, required this.onPost});

  final VoidCallback onClose;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary.withValues(alpha: 0.78),
              size: 34,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              'Write a Review',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onPost,
            child: Text(
              'Post',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ExperienceField extends StatelessWidget {
  const _ExperienceField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      minLines: 7,
      maxLines: 7,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText:
            'What did you like or dislike? How was the service, atmosphere, and value for money?',
        hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.textSecondary.withValues(alpha: 0.72),
          height: 1.5,
        ),
        filled: true,
        fillColor: AppColors.surfaceVariant.withValues(alpha: 0.72),
        contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _SectionLabel('ADD PHOTOS')),
        Text(
          'Up to 10 photos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.photos});

  final List<_ReviewPhoto> photos;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _UploadPhotoTile();
          }

          return _PhotoTile(photo: photos[index - 1]);
        },
      ),
    );
  }
}

class _UploadPhotoTile extends StatelessWidget {
  const _UploadPhotoTile();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        width: 116,
        height: 116,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(10),
        ),
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
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo});

  final _ReviewPhoto photo;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            photo.url,
            width: 116,
            height: 116,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _QuickTags extends StatelessWidget {
  const _QuickTags({
    required this.tags,
    required this.selectedTags,
    required this.onTagSelected,
  });

  final List<_ReviewTag> tags;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tags.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.35,
      ),
      itemBuilder: (context, index) {
        final tag = tags[index];
        final isSelected = selectedTags.contains(tag.label);

        return Material(
          color: isSelected
              ? AppColors.primaryLight.withValues(alpha: 0.22)
              : AppColors.surfaceVariant.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onTagSelected(tag.label),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(tag.icon, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tag.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
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

class _ReviewPhoto {
  const _ReviewPhoto({required this.url});

  final String url;
}

class _ReviewTag {
  const _ReviewTag({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
