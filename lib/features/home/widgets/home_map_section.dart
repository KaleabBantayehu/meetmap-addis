import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/core/services/gebeta_map_service.dart';
import 'package:meetmap_addis/core/location/geo_bounds.dart';
import 'package:meetmap_addis/features/places/screens/place_detail_screen.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

import 'map_pin.dart';
import 'place_preview_card.dart';

class HomeMapSection extends StatefulWidget {
  const HomeMapSection({
    super.key,
    required this.places,
    required this.onBoundsChanged,
  });

  final List<PlaceModel> places;
  final ValueChanged<GeoBounds> onBoundsChanged;

  @override
  State<HomeMapSection> createState() => _HomeMapSectionState();
}

class _HomeMapSectionState extends State<HomeMapSection> {
  final GebetaMapService _mapService = const GebetaMapService();
  GebetaMapController? _mapController;
  bool _isStyleReady = false;
  List<_ProjectedPlacePin> _visiblePins = [];
  Size _mapViewportSize = Size.zero;
  int _projectionGeneration = 0;
  bool _hasFittedInitialPlaces = false;
  int _selectedCategoryIndex = 0;
  int _selectedPlaceIndex = 0;

  @override
  void didUpdateWidget(covariant HomeMapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isStyleReady) {
      _reprojectPins();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlaces = _filteredPlaces();
    final previewPlace = filteredPlaces.isEmpty
        ? null
        : filteredPlaces[_selectedPlaceIndex.clamp(
            0,
            filteredPlaces.length - 1,
          )];

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = constraints.biggest;
        if (viewportSize != _mapViewportSize) {
          _mapViewportSize = viewportSize;
          WidgetsBinding.instance.addPostFrameCallback((_) => _reprojectPins());
        }
        return Stack(
          children: [
            Positioned.fill(
              child: _mapService.isConfigured
                  ? GebetaMap(
                      compassViewPosition: CompassViewPosition.topRight,
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(
                          GebetaMapService.addisLatitude,
                          GebetaMapService.addisLongitude,
                        ),
                        zoom: GebetaMapService.defaultZoom,
                      ),
                      styleString: GebetaMapService.styleAsset,
                      onMapCreated: _onMapCreated,
                      onStyleLoadedCallback: () async {
                        _isStyleReady = true;
                        await _fitInitialPlaces();
                        _reprojectPins();
                      },
                      onCameraIdle: () {
                        _reprojectPins();
                        _notifyVisibleBounds();
                      },
                      apiKey: _mapService.apiKey,
                    )
                  : const Center(
                      child: Text(
                        'Map API key is missing.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: AppColors.primary.withValues(alpha: 0.10),
                ),
              ),
            ),
            if (filteredPlaces.isEmpty)
              const Positioned(
                top: 76,
                left: 20,
                right: 20,
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      'No mapped places in this category.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ..._visiblePins.map((pin) {
              return Positioned(
                left: pin.point.x - 20,
                top: pin.point.y - 50,
                child: GestureDetector(
                  onTap: () {
                    final filteredPlaces = _filteredPlaces();
                    final index = filteredPlaces.indexWhere(
                      (p) => p.id == pin.place.id,
                    );
                    if (index >= 0) {
                      setState(() => _selectedPlaceIndex = index);
                    }
                    _animateCameraToPlace(pin.place);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlaceDetailScreen(place: pin.place),
                      ),
                    );
                  },
                  child: MapPin(
                    icon: pin.place.category.toLowerCase().contains('cafe')
                        ? Icons.coffee_rounded
                        : Icons.place_rounded,
                  ),
                ),
              );
            }),
            Positioned(
              top: 16,
              left: 20,
              right: 0,
              child: _CategoryRow(
                selectedIndex: _selectedCategoryIndex,
                onCategorySelected: (index) {
                  setState(() {
                    _selectedCategoryIndex = index;
                    _selectedPlaceIndex = 0;
                  });
                  if (_isStyleReady) {
                    _reprojectPins();
                  }
                },
              ),
            ),
            if (previewPlace != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlaceDetailScreen(place: previewPlace),
                      ),
                    );
                  },
                  child: PlacePreviewCard(place: previewPlace),
                ),
              ),
          ],
        );
      },
    );
  }

  List<PlaceModel> _filteredPlaces() {
    final categories = ['All', 'Cafe', 'Restaurant', 'Coworking', 'Park'];
    final selected = categories[_selectedCategoryIndex];
    final withCoordinates = widget.places
        .where(
          (p) =>
              p.latitude.isFinite &&
              p.longitude.isFinite &&
              p.latitude >= -90 &&
              p.latitude <= 90 &&
              p.longitude >= -180 &&
              p.longitude <= 180 &&
              (p.latitude != 0 || p.longitude != 0),
        )
        .toList();
    if (selected == 'All') {
      return withCoordinates;
    }
    return withCoordinates
        .where((p) => p.category.toLowerCase().contains(selected.toLowerCase()))
        .toList();
  }

  Future<void> _onMapCreated(GebetaMapController controller) async {
    _mapController = controller;
  }

  Future<void> _notifyVisibleBounds() async {
    final controller = _mapController;
    if (!_isStyleReady || controller == null || !mounted) return;
    try {
      final visible = await controller.getVisibleRegion();
      final bounds = GeoBounds(
        north: visible.northeast.latitude,
        south: visible.southwest.latitude,
        east: visible.northeast.longitude,
        west: visible.southwest.longitude,
      );
      if (bounds.isValid) widget.onBoundsChanged(bounds);
    } catch (error) {
      debugPrint('Unable to read Home map bounds: $error');
    }
  }

  Future<void> _animateCameraToPlace(PlaceModel place) async {
    final controller = _mapController;
    if (controller == null || !_isStyleReady) return;

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(place.latitude, place.longitude),
          16.0,
        ),
      );
    } catch (error) {
      debugPrint('Unable to move the Home map camera: $error');
    }
  }

  Future<void> _reprojectPins() async {
    final controller = _mapController;
    if (!_isStyleReady || controller == null || !mounted) return;
    final places = _filteredPlaces();
    final viewportSize = _mapViewportSize;
    if (viewportSize.isEmpty) return;
    final coordinateScale = defaultTargetPlatform == TargetPlatform.android
        ? MediaQuery.devicePixelRatioOf(context)
        : 1.0;
    final generation = ++_projectionGeneration;
    final nextPins = <_ProjectedPlacePin>[];

    try {
      for (final place in places) {
        final point = await controller.toScreenLocation(
          LatLng(place.latitude, place.longitude),
        );
        final x = point.x.toDouble() / coordinateScale;
        final y = point.y.toDouble() / coordinateScale;
        if (x < -60 ||
            y < -60 ||
            x > viewportSize.width + 60 ||
            y > viewportSize.height + 60) {
          continue;
        }
        nextPins.add(
          _ProjectedPlacePin(place: place, point: Point<double>(x, y)),
        );
      }
      if (!mounted || generation != _projectionGeneration) return;
      setState(() {
        _visiblePins = nextPins;
      });
    } catch (error) {
      debugPrint('Unable to project Home map pins: $error');
    }
  }

  Future<void> _fitInitialPlaces() async {
    final controller = _mapController;
    final places = _filteredPlaces();
    if (_hasFittedInitialPlaces || controller == null || places.isEmpty) return;
    _hasFittedInitialPlaces = true;

    try {
      if (places.length == 1) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(places.first.latitude, places.first.longitude),
            GebetaMapService.defaultZoom,
          ),
        );
        return;
      }

      final latitudes = places.map((place) => place.latitude);
      final longitudes = places.map((place) => place.longitude);
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(latitudes.reduce(min), longitudes.reduce(min)),
            northeast: LatLng(latitudes.reduce(max), longitudes.reduce(max)),
          ),
          left: 48,
          top: 96,
          right: 48,
          bottom: 280,
        ),
      );
    } catch (error) {
      debugPrint('Unable to fit Home map places: $error');
    }
  }
}

class _ProjectedPlacePin {
  const _ProjectedPlacePin({required this.place, required this.point});

  final PlaceModel place;
  final Point point;
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Cafe', 'Restaurant', 'Coworking', 'Park'];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.only(right: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onCategorySelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.outline),
              ),
              child: Center(
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
