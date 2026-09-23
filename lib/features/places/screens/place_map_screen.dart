import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/core/services/gebeta_map_service.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:meetmap_addis/providers/location_provider.dart';
import 'package:meetmap_addis/providers/places_provider.dart';
import 'package:meetmap_addis/core/services/gebeta_directions_service.dart'
    show DirectionsException, DirectionsFailureType, DirectionsResult;
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
  Point<double> _originPoint = const Point(0, 0);
  bool _originVisible = false;
  bool _routeDrawn = false;

  DirectionsResult? _directionsResult;
  bool _isLoadingDirections = false;
  String? _directionsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDirections());
  }

  Future<void> _fetchDirections() async {
    if (_isLoadingDirections) return;
    if (!_hasValidCoordinates(widget.place.latitude, widget.place.longitude)) {
      setState(
        () => _directionsError = 'The route destination is not available.',
      );
      return;
    }

    setState(() {
      _isLoadingDirections = true;
      _directionsError = null;
    });

    try {
      if (!ConnectivityService.instance.isConnected) {
        throw const DirectionsException(DirectionsFailureType.network);
      }
      final locationProvider = context.read<LocationProvider>();
      if (!locationProvider.hasLocation) {
        final located = await locationProvider.getCurrentLocation();
        if (!mounted) return;
        if (!located) {
          setState(() {
            _directionsError = locationProvider.permissionDenied
                ? 'Location permission is required for directions.'
                : 'Your current location could not be obtained.';
          });
          return;
        }
      }

      final placesProvider = context.read<PlacesProvider>();
      final result = await placesProvider.getDirectionsToPlace(
        userLat: locationProvider.currentLatitude!,
        userLng: locationProvider.currentLongitude!,
        place: widget.place,
      );

      if (!mounted) return;
      setState(() {
        _directionsResult = result;
        _directionsError = null;
        _routeDrawn = false;
      });
      await _drawRouteIfReady();
    } on DirectionsException catch (error) {
      if (mounted) {
        setState(() => _directionsError = error.userMessage);
      }
    } catch (error) {
      debugPrint('Unexpected Directions error: $error');
      if (mounted) {
        setState(() {
          _directionsError =
              'The route could not be loaded. Check your connection and retry.';
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

  @override
  Widget build(BuildContext context) {
    final hasCoords = _hasValidCoordinates(
      widget.place.latitude,
      widget.place.longitude,
    );

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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
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
                  target: LatLng(widget.place.latitude, widget.place.longitude),
                  zoom: 15.0,
                ),
                styleString: GebetaMapService.styleAsset,
                myLocationEnabled: context
                    .watch<LocationProvider>()
                    .hasLocation,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                onStyleLoadedCallback: () async {
                  _isStyleReady = true;
                  _reprojectPin();
                  await _drawRouteIfReady();
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
          if (_originVisible)
            Positioned(
              left: _originPoint.x - 10,
              top: _originPoint.y - 10,
              child: const _OriginPin(),
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
                  onRetry: _fetchDirections,
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
    if (!_hasValidCoordinates(widget.place.latitude, widget.place.longitude)) {
      return;
    }

    try {
      final locationProvider = context.read<LocationProvider>();
      final scale = defaultTargetPlatform == TargetPlatform.android
          ? MediaQuery.devicePixelRatioOf(context)
          : 1.0;
      final destinationPoint = await controller.toScreenLocation(
        LatLng(widget.place.latitude, widget.place.longitude),
      );
      final originPoint = locationProvider.hasLocation
          ? await controller.toScreenLocation(
              LatLng(
                locationProvider.currentLatitude!,
                locationProvider.currentLongitude!,
              ),
            )
          : null;
      if (!mounted) return;
      setState(() {
        _pinPoint = Point(
          destinationPoint.x.toDouble() / scale,
          destinationPoint.y.toDouble() / scale,
        );
        _pinVisible = true;
        if (originPoint != null) {
          _originPoint = Point(
            originPoint.x.toDouble() / scale,
            originPoint.y.toDouble() / scale,
          );
          _originVisible = true;
        }
      });
    } catch (error) {
      debugPrint('Unable to project Directions markers: $error');
    }
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
    } catch (error) {
      debugPrint('Unable to center Directions map: $error');
    }
  }

  Future<void> _drawRouteIfReady() async {
    final controller = _mapController;
    final result = _directionsResult;
    if (!_isStyleReady || controller == null || result == null || _routeDrawn) {
      return;
    }

    try {
      await controller.clearLines();
      await controller.addLine(
        LineOptions(
          geometry: result.route
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(growable: false),
          lineColor: '#006B57',
          lineWidth: 5,
          lineOpacity: 0.9,
        ),
      );
      _routeDrawn = true;

      final latitudes = result.route.map((point) => point.latitude);
      final longitudes = result.route.map((point) => point.longitude);
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(latitudes.reduce(min), longitudes.reduce(min)),
            northeast: LatLng(latitudes.reduce(max), longitudes.reduce(max)),
          ),
          left: 48,
          top: 100,
          right: 48,
          bottom: 250,
        ),
      );
      await _reprojectPin();
    } catch (error) {
      _routeDrawn = false;
      debugPrint('Unable to draw Directions route: $error');
      if (mounted) {
        setState(() {
          _directionsError = 'The route could not be displayed. Please retry.';
        });
      }
    }
  }

  bool _hasValidCoordinates(double latitude, double longitude) {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        (latitude != 0 || longitude != 0);
  }
}

class _OriginPin extends StatelessWidget {
  const _OriginPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
      ),
    );
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
          child: const Icon(Icons.place_rounded, color: Colors.white, size: 24),
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
    required this.onRetry,
  });

  final PlaceModel place;
  final VoidCallback onCenterTap;
  final DirectionsResult? directions;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Finding route...'),
                    ],
                  ),
                ),
              )
            else if (error != null)
              Center(
                child: Column(
                  children: [
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
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
                  Container(width: 1, height: 28, color: AppColors.outline),
                  _InfoItem(
                    icon: Icons.access_time_rounded,
                    label: 'Duration',
                    value: directions!.durationDisplay,
                  ),
                ],
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
