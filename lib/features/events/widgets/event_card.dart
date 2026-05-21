import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/models/event_model.dart';
import 'package:meetmap_addis/features/events/widgets/event_card_footer.dart';

class EventCard extends StatefulWidget {
  final EventModel event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isBookmarked = false;

  void _toggleBookmark() {
    setState(() => _isBookmarked = !_isBookmarked);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        highlightColor: AppColors.primary.withValues(alpha: 0.03),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              _EventCardImage(
                imageUrl: widget.event.imageUrl,
                isBookmarked: _isBookmarked,
                onBookmarkTap: _toggleBookmark,
              ),

              // Content section
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Location row
                    _MetaRow(
                      icon: Icons.location_on_rounded,
                      label: widget.event.location,
                    ),

                    const SizedBox(height: 5),

                    // Date & time row
                    _MetaRow(
                      icon: Icons.calendar_today_rounded,
                      label: '${widget.event.date} · ${widget.event.time}',
                    ),

                    const SizedBox(height: 10),

                    // Description
                    Text(
                      widget.event.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Divider
                    Divider(
                      color: AppColors.outline.withValues(alpha: 0.3),
                      height: 1,
                    ),

                    const SizedBox(height: 12),

                    // Footer
                    EventCardFooter(
                      attendeeCount: widget.event.attendeeCount,
                      category: widget.event.category,
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

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _EventCardImage extends StatelessWidget {
  final String imageUrl;
  final bool isBookmarked;
  final VoidCallback onBookmarkTap;

  const _EventCardImage({
    required this.imageUrl,
    required this.isBookmarked,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: AppColors.surfaceVariant),
              errorWidget: (_, _, _) => Container(
                color: AppColors.surfaceVariant,
                child: const Center(
                  child: Icon(
                    Icons.event_outlined,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            // Subtle top gradient for bookmark readability
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bookmark button
            Positioned(
              top: 10,
              right: 10,
              child: _BookmarkButton(
                isBookmarked: isBookmarked,
                onTap: onBookmarkTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  final bool isBookmarked;
  final VoidCallback onTap;

  const _BookmarkButton({required this.isBookmarked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isBookmarked
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          size: 18,
          color: isBookmarked ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
