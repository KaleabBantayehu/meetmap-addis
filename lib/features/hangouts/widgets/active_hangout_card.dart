import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/models/hangout_model.dart';
import 'attendee_avatar_stack.dart';

class ActiveHangoutCard extends StatelessWidget {
  final HangoutModel hangout;
  final VoidCallback onTap;

  const ActiveHangoutCard({
    super.key,
    required this.hangout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: hangout.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: AppColors.surfaceVariant),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (hangout.isLive)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Vibrant',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hangout.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${hangout.time} · ${hangout.attendeeCount} attending',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        AttendeeAvatarStack(
                          totalCount: hangout.attendeeCount,
                          maxDisplay: 2,
                          size: 32,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hangout.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
