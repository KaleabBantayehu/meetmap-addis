import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/models/event_model.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:meetmap_addis/features/places/screens/place_map_screen.dart';
import 'package:meetmap_addis/providers/location_provider.dart';
import 'package:meetmap_addis/providers/places_provider.dart';
import 'package:meetmap_addis/core/services/gebeta_directions_service.dart'
    show DirectionsResult;
import 'package:provider/provider.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  DirectionsResult? _directionsResult;
  bool _isLoadingDirections = false;

  @override
  void initState() {
    super.initState();
    _fetchDirections();
  }

  bool get _hasValidCoordinates {
    final latitude = widget.event.latitude;
    final longitude = widget.event.longitude;
    return latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        (latitude != 0 || longitude != 0);
  }

  Future<void> _fetchDirections() async {
    if (!_hasValidCoordinates) return;
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
    if (!locationProvider.hasLocation) return;

    setState(() {
      _isLoadingDirections = true;
    });

    try {
      final placeModel = _mapToPlaceModel();
      final result = await placesProvider.getDirectionsToPlace(
        userLat: locationProvider.currentLatitude!,
        userLng: locationProvider.currentLongitude!,
        place: placeModel,
      );
      if (mounted) {
        setState(() {
          _directionsResult = result;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDirections = false;
        });
      }
    }
  }

  PlaceModel _mapToPlaceModel() {
    return PlaceModel(
      id: widget.event.id,
      name: widget.event.title,
      imageUrl: widget.event.imageUrl,
      category: widget.event.category,
      location: widget.event.location,
      rating: 5.0,
      priceRange: 'Free',
      isOpen: true,
      latitude: widget.event.latitude!,
      longitude: widget.event.longitude!,
      tags: [widget.event.category],
      reviewCount: 0,
      description: widget.event.description,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Scrollable details content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image Banner
                Stack(
                  children: [
                    Hero(
                      tag: 'event_image_${widget.event.id}',
                      child: Container(
                        height: size.height * 0.38,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                        ),
                        child: widget.event.imageUrl.isNotEmpty
                            ? Image.network(
                                widget.event.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) => const Center(
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
                    ),
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
                  ],
                ),

                // Event info card / content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tag & Attendee count
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
                              widget.event.category.toUpperCase(),
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
                            '${widget.event.attendeeCount} attending',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Event Title
                      Text(
                        widget.event.title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Host Indicator
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.15,
                            ),
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
                                widget.event.host,
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

                      // Date & Time block
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.event.date,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.event.time,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.place_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Venue / Address',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.event.location,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Live routing block if location is enabled
                      if (_isLoadingDirections ||
                          _directionsResult != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: _isLoadingDirections
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _RouteIndicator(
                                      icon: Icons.navigation_rounded,
                                      label: 'Distance',
                                      value: _directionsResult!.distanceDisplay,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 28,
                                      color: AppColors.outline,
                                    ),
                                    _RouteIndicator(
                                      icon: Icons.access_time_rounded,
                                      label: 'Duration',
                                      value: _directionsResult!.durationDisplay,
                                    ),
                                  ],
                                ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'About Event',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.event.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 120), // Bottom spacer for buttons
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Top floating back button
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

          // Bottom Action Panel: Join and Directions
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
              child: ElevatedButton.icon(
                onPressed: !_hasValidCoordinates
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PlaceMapScreen(place: _mapToPlaceModel()),
                          ),
                        );
                      },
                icon: const Icon(Icons.directions_rounded),
                label: Text(
                  _hasValidCoordinates ? 'Directions' : 'Location unavailable',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RouteIndicator({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
