import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/places/screens/place_map_screen.dart';
import 'package:meetmap_addis/shared/models/hangout_model.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class HangoutDetailScreen extends StatefulWidget {
  final HangoutModel hangout;

  const HangoutDetailScreen({super.key, required this.hangout});

  @override
  State<HangoutDetailScreen> createState() => _HangoutDetailScreenState();
}

class _HangoutDetailScreenState extends State<HangoutDetailScreen> {
  bool _isJoined = false;
  late int _attendeeCount;

  @override
  void initState() {
    super.initState();
    _attendeeCount = widget.hangout.attendeeCount;
  }

  void _toggleJoin() {
    setState(() {
      _isJoined = !_isJoined;
      _attendeeCount += _isJoined ? 1 : -1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isJoined
              ? 'Joined "${widget.hangout.title}"!'
              : 'Left "${widget.hangout.title}".',
        ),
        backgroundColor:
            _isJoined ? AppColors.primary : AppColors.textSecondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Returns a PlaceModel only when coordinates are available (for map & directions).
  PlaceModel? _toPlaceModel() {
    final lat = widget.hangout.latitude;
    final lng = widget.hangout.longitude;
    if (lat == null || lng == null) return null;
    return PlaceModel(
      id: widget.hangout.id,
      name: widget.hangout.title,
      imageUrl: widget.hangout.imageUrl,
      category: widget.hangout.category,
      location: widget.hangout.location,
      rating: 5.0,
      priceRange: 'Free',
      isOpen: true,
      latitude: lat,
      longitude: lng,
      tags: [widget.hangout.category],
      reviewCount: 0,
      description: widget.hangout.description,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final placeModel = _toPlaceModel();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable content ───────────────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero image banner
                Stack(
                  children: [
                    Container(
                      height: size.height * 0.38,
                      width: double.infinity,
                      color: AppColors.surface,
                      child: widget.hangout.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.hangout.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: AppColors.surfaceVariant),
                              errorWidget: (context, url, error) => const Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.image_rounded,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                            ),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.45),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Live badge
                    if (widget.hangout.isLive)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 54,
                        left: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Live Now',
                                style: TextStyle(
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

                // Info content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category tag + attendee count
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.hangout.category.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.people_alt_rounded,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_attendeeCount attending',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        widget.hangout.title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Host (only when createdBy is available)
                      if (widget.hangout.createdBy != null &&
                          widget.hangout.createdBy!.isNotEmpty) ...[
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.15),
                              radius: 18,
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hosted by',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  widget.hangout.createdBy!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Date / Time block
                      _InfoBlock(
                        icon: Icons.access_time_rounded,
                        child: Text(
                          widget.hangout.time,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Location block
                      _InfoBlock(
                        icon: Icons.place_rounded,
                        child: Text(
                          widget.hangout.location,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'About this Hangout',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.hangout.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),

                      // Map preview (only when coordinates exist)
                      if (placeModel != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Location',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _HangoutMapPreview(placeModel: placeModel),
                      ],

                      const SizedBox(height: 120), // spacer for bottom panel
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Back button ─────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              elevation: 4,
              shadowColor: Colors.black38,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom action panel ─────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleJoin,
                      icon: Icon(
                        _isJoined
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isJoined ? 'Joined' : 'Join Hangout',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isJoined
                            ? AppColors.textSecondary
                            : AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                    ),
                  ),
                  if (placeModel != null) ...[
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlaceMapScreen(place: placeModel),
                        ),
                      ),
                      icon: const Icon(
                        Icons.directions_rounded,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _InfoBlock({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _HangoutMapPreview extends StatelessWidget {
  final PlaceModel placeModel;

  const _HangoutMapPreview({required this.placeModel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlaceMapScreen(place: placeModel)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 2.18,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF4F0C9), Color(0xFFEAE5B4)],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 170,
                      color: Colors.white.withValues(alpha: 0.58),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.place_rounded,
                        color: Colors.white,
                        size: 29,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_full_rounded, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Open Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
}
