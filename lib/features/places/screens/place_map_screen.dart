import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/core/services/gebeta_map_service.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:meetmap_addis/providers/location_provider.dart';
import 'package:meetmap_addis/providers/places_provider.dart';
import 'package:meetmap_addis/core/services/gebeta_directions_service.dart' show DirectionsResult, GebetaDirectionsService;
import 'package:meetmap_addis/core/storage/connectivity_service.dart';
import 'package:provider/provider.dart';

class PlaceMapScreen extends StatefulWidget {
  const PlaceMapScreen({super.key, required this.place});

  final PlaceModel place;

  @override
  State<PlaceMapScreen> createState() => _PlaceMapScreenState();
}

class _PlaceMapScreenState extends State<PlaceMapScreen> {
  final GebetaMapService _mapService = const GebetaMapService();
  GebetaMapController? _mapController;
  bool _isStyleReady = false;

  // Screen-projected pin offset
  Point<double> _pinPoint = const Point(0, 0);
  bool _pinVisible = false;

  DirectionsResult? _directionsResult;
  bool _isLoadingDirections = false;
  String? _directionsError;

  @override
  void initState() {
    super.initState();
    _fetchDirections();
  }

  Future<void> _fetchDirections() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
    if (!locationProvider.hasLocation) {
      setState(() {
        _directionsError = 'Location not available';
      });
      return;
    }

    setState(() {
      _isLoadingDirections = true;
      _directionsError = null;
    });

    try {
      final result = await placesProvider.getDirectionsToPlace(
        userLat: locationProvider.currentLatitude!,
        userLng: locationProvider.currentLongitude!,
        place: widget.place,
      );

      if (mounted) {
        setState(() {
          _directionsResult = result;
          if (result != null) {
            _directionsError = null;
          } else {
            _directionsError = 'Unable to load route';
          }
        });

        // Fetch raw direction data for polyline (for future visualization)
        if (result != null) {
          await _fetchRoutePolyline();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _directionsError = 'Failed to load directions';
          debugPrint('Direction error: $e');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDirections = false;
        });
      }
    }
  }

  Future<void> _fetchRoutePolyline() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    if (!locationProvider.hasLocation) return;

    try {
      final directionsService = GebetaDirectionsService();
      final rawResponse = await directionsService.getDirectionsRaw(
        originLat: locationProvider.currentLatitude!,
        originLng: locationProvider.currentLongitude!,
        destLat: widget.place.latitude,
        destLng: widget.place.longitude,
      );

      if (rawResponse != null) {
        debugPrint('Route polyline data loaded: ${rawResponse.length} points');
      }
    } catch (e) {
      debugPrint('Polyline fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCoords =
        widget.place.latitude != 0 && widget.place.longitude != 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          if (!ConnectivityService.instance.isConnected)
            Positioned.fill(
              child: Container(
                color: const Color(0xFFF0EFEA),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 72,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You are offline',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Map cannot be loaded without an internet connection.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (hasCoords && _mapService.isConfigured)
            Positioned.fill(
              child: GebetaMap(
                compassViewPosition: CompassViewPosition.topRight,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    widget.place.latitude,
                    widget.place.longitude,
                  ),
                  zoom: 15.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _scheduleRouteIfAvailable();
                },
                onStyleLoadedCallback: () {
                  _isStyleReady = true;
                  _reprojectPin();
                },
                onCameraIdle: _reprojectPin,
                apiKey: _mapService.apiKey,
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: const Color(0xFFF4F0C9),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 72,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        hasCoords
                            ? 'Map API key is missing'
                            : 'No coordinates available',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Destination pin overlay ──────────────────────────────────────
          if (_pinVisible)
            Positioned(
              left: _pinPoint.x - 20,
              top: _pinPoint.y - 50,
              child: _DestinationPin(label: widget.place.name),
            ),

          // ── Top bar ──────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    // Back
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      elevation: 4,
                      shadowColor: Colors.black26,
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
                    const SizedBox(width: 12),
                    // Place title chip
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.place_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.place.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
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
            ),
          ),

          // ── Bottom info card ─────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _PlaceInfoCard(
                  place: widget.place,
                  onCenterTap: _centerOnPlace,
                  directions: _directionsResult,
                  isLoading: _isLoadingDirections,
                  error: _directionsError,
                  onStartNavigation: _startNavigation,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reprojectPin() async {
    final controller = _mapController;
    if (!_isStyleReady || controller == null || !mounted) return;
    if (widget.place.latitude == 0 && widget.place.longitude == 0) return;

    try {
      final point = await controller.toScreenLocation(
        LatLng(widget.place.latitude, widget.place.longitude),
      );
      if (!mounted) return;
      setState(() {
        _pinPoint = Point(point.x.toDouble(), point.y.toDouble());
        _pinVisible = true;
      });
    } catch (_) {}
  }

  Future<void> _centerOnPlace() async {
    final controller = _mapController;
    if (controller == null || !_isStyleReady) return;
    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(widget.place.latitude, widget.place.longitude),
          16.0,
        ),
      );
    } catch (_) {}
  }

  void _startNavigation() {
    if (_directionsResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route information not available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final message = '${widget.place.name} - ${_directionsResult!.distanceDisplay}, ${_directionsResult!.durationDisplay}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to: $message'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            // Fallback: show place details with directions
            debugPrint('Navigation initiated to ${widget.place.name}');
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Optionally animate to user position then to destination if available.
  void _scheduleRouteIfAvailable() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      final controller = _mapController;
      if (controller == null) return;
      try {
        if (locationProvider.hasLocation &&
            widget.place.latitude != 0 &&
            widget.place.longitude != 0) {
          // Fit bounds between user and destination
          final userLat = locationProvider.currentLatitude!;
          final userLng = locationProvider.currentLongitude!;
          final placeLat = widget.place.latitude;
          final placeLng = widget.place.longitude;

          final minLat = min(userLat, placeLat);
          final maxLat = max(userLat, placeLat);
          final minLng = min(userLng, placeLng);
          final maxLng = max(userLng, placeLng);

          await controller.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(minLat, minLng),
                northeast: LatLng(maxLat, maxLng),
              ),
              left: 60,
              top: 100,
              right: 60,
              bottom: 160,
            ),
          );
        } else {
          await _centerOnPlace();
        }
      } catch (_) {
        await _centerOnPlace();
      }
    });
  }
}

class _DestinationPin extends StatelessWidget {
  const _DestinationPin({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        // Pin icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.place_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }
}

class _PlaceInfoCard extends StatelessWidget {
  const _PlaceInfoCard({
    required this.place,
    required this.onCenterTap,
    this.directions,
    this.isLoading = false,
    this.error,
    this.onStartNavigation,
  });

  final PlaceModel place;
  final VoidCallback onCenterTap;
  final DirectionsResult? directions;
  final bool isLoading;
  final String? error;
  final VoidCallback? onStartNavigation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${place.location}, Addis Ababa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Centre button
              GestureDetector(
                onTap: onCenterTap,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          if (isLoading || directions != null || error != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.outline),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              )
            else if (error != null)
              Center(
                child: Text(
                  error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else if (directions != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _InfoItem(
                    icon: Icons.navigation_rounded,
                    label: 'Distance',
                    value: directions!.distanceDisplay,
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.outline,
                  ),
                  _InfoItem(
                    icon: Icons.access_time_rounded,
                    label: 'Duration',
                    value: directions!.durationDisplay,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onStartNavigation,
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('Start Navigation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }
}
