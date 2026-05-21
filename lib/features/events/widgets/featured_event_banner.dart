import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/models/event_model.dart';

class FeaturedEventBanner extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const FeaturedEventBanner({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Featured Today',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Text(
                'View All',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Background image
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: event.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: AppColors.surfaceVariant),
                        errorWidget: (_, _, _) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Center(
                            child: Icon(
                              Icons.event_outlined,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Gradient overlay
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.25),
                              Colors.black.withValues(alpha: 0.80),
                            ],
                            stops: const [0.2, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Featured badge
                    Positioned(top: 14, left: 14, child: _FeaturedBadge()),

                    // Attendee count badge (top right)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: _AttendeeBadge(count: event.attendeeCount),
                    ),

                    // Content overlay at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${event.date} · ${event.time}',
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 13,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    event.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _JoinButton(onTap: onTap)),
                                const SizedBox(width: 10),
                                _HostTag(host: event.host),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'FEATURED',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeeBadge extends StatelessWidget {
  final int count;
  const _AttendeeBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_rounded, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$count going',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  final VoidCallback onTap;
  const _JoinButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Join Event',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _HostTag extends StatelessWidget {
  final String host;
  const _HostTag({required this.host});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_rounded, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            host,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
