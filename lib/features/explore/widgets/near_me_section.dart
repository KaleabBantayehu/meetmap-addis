import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../providers/location_provider.dart';
import '../../../../providers/places_provider.dart';
import '../../../../shared/models/place_model.dart';
import '../../places/screens/place_detail_screen.dart';

class NearMeSection extends StatefulWidget {
  const NearMeSection({super.key});

  @override
  State<NearMeSection> createState() => _NearMeSectionState();
}

class _NearMeSectionState extends State<NearMeSection> {
  late final LocationProvider _locationProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationProvider = Provider.of<LocationProvider>(context, listen: false);
      _initializeLocation();
    });
  }

  Future<void> _initializeLocation() async {
    if (!_isInitialized) {
      await _locationProvider.getCurrentLocation();
      if (_locationProvider.hasLocation && mounted) {
        await Provider.of<PlacesProvider>(context, listen: false)
            .fetchNearbyPlaces(
              userLat: _locationProvider.currentLatitude!,
              userLng: _locationProvider.currentLongitude!,
            );
      }
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, _) {
        if (!locationProvider.hasLocation) {
          return GestureDetector(
            onTap: _initializeLocation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enable Location',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Discover places near you',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Consumer<PlacesProvider>(
          builder: (context, placesProvider, _) {
            final categories = [
              ('Near Me', null),
              ('Nearby Cafes', 'cafe'),
              ('Nearby Restaurants', 'restaurant'),
              ('Nearby Study', 'coworking'),
            ];

            return ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Text(
                    'Around You',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ...categories.map((cat) {
                  final categoryName = cat.$1;
                  final categoryFilter = cat.$2;

                  List<PlaceModel> nearbyPlaces;
                  if (categoryFilter == null) {
                    nearbyPlaces = placesProvider.nearbyPlaces;
                  } else {
                    nearbyPlaces =
                        placesProvider.getNearbyPlacesByCategory(
                          userLat: locationProvider.currentLatitude!,
                          userLng: locationProvider.currentLongitude!,
                          category: categoryFilter,
                          radiusKm: 5.0,
                        );
                  }

                  if (nearbyPlaces.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            categoryName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: nearbyPlaces.length.clamp(0, 3),
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final place = nearbyPlaces[index];
                              final distance = placesProvider.getDistanceToPlace(
                                userLat: locationProvider.currentLatitude!,
                                userLng: locationProvider.currentLongitude!,
                                place: place,
                              );

                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PlaceDetailScreen(place: place),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 160,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.outline
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(11),
                                            ),
                                        child: Image.network(
                                          place.imageUrl,
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              Container(
                                                height: 100,
                                                color: AppColors
                                                    .outline
                                                    .withValues(
                                                          alpha: 0.2),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.image_outlined,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              place.name,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: AppColors
                                                        .textPrimary,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${distance.toStringAsFixed(1)} km away',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: AppColors
                                                        .textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}
