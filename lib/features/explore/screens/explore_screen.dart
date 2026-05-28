import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/explore/screens/filter_screen.dart';
import 'package:meetmap_addis/features/explore/widgets/explore_place_card.dart';
import 'package:meetmap_addis/features/explore/widgets/near_me_section.dart';
import 'package:meetmap_addis/features/explore/widgets/social_discovery_section.dart';
import 'package:meetmap_addis/features/places/screens/place_detail_screen.dart';
import 'package:meetmap_addis/providers/auth_provider.dart';
import 'package:meetmap_addis/providers/location_provider.dart';
import 'package:meetmap_addis/providers/places_provider.dart';
import 'package:meetmap_addis/routes/app_routes.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:provider/provider.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int selectedCategoryIndex = 0;
  final categories = ['Cafes', 'Restaurants', 'Coworking', 'Hotels'];

  // Active filter values (updated from FilterScreen result)
  double _filterRadiusKm = 5.0;
  double _filterMinRating = 0.0; // 0 = Any
  int? _filterPriceLevel;
  List<String> _filterAmenities = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final placesProvider =
          Provider.of<PlacesProvider>(context, listen: false);
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);

      if (placesProvider.places.isEmpty) {
        placesProvider.fetchPlaces();
      }
      if (locationProvider.hasLocation) {
        _fetchNearbyPlaces(placesProvider, locationProvider);
      }
    });
  }

  void _fetchNearbyPlaces(
      PlacesProvider placesProvider, LocationProvider locationProvider) {
    placesProvider.fetchNearbyPlaces(
      userLat: locationProvider.currentLatitude!,
      userLng: locationProvider.currentLongitude!,
      radiusKm: _filterRadiusKm,
    );
  }

  /// Pushes FilterScreen and applies returned filter params.
  Future<void> _openFilters() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const FilterScreen()),
    );
    if (result == null || !mounted) return;

    // Parse rating  e.g. '3.5+' → 3.5, 'Any' → 0.0
    final ratingStr = (result['rating'] as String?) ?? 'Any';
    final minRating = ratingStr == 'Any'
        ? 0.0
        : double.tryParse(ratingStr.replaceAll('+', '')) ?? 0.0;

    // Parse radius  e.g. '10km' → 10.0
    final radiusStr = (result['radius'] as String?) ?? '5km';
    final radiusKm =
        double.tryParse(radiusStr.replaceAll('km', '')) ?? 5.0;

    setState(() {
      _filterMinRating = minRating;
      _filterRadiusKm = radiusKm;
      _filterPriceLevel = result['priceLevel'] as int?;
      _filterAmenities = (result['amenities'] as List<dynamic>?)?.cast<String>() ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PlacesProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final allPlaces = placesProvider.places;
    final isLoading = placesProvider.isLoading;

    // Category filter
    final selectedCategory = categories[selectedCategoryIndex].toLowerCase();
    List<PlaceModel> places = allPlaces.where((place) {
      if (selectedCategory == 'cafes') {
        return place.category.toLowerCase().contains('cafe') ||
            place.name.toLowerCase().contains('coffee');
      }
      return place.category.toLowerCase().contains(
            selectedCategory.substring(0, selectedCategory.length - 1),
          );
    }).toList();

    // Rating filter
    if (_filterMinRating > 0) {
      places = places.where((p) => p.rating >= _filterMinRating).toList();
    }

    // Price level filter
    if (_filterPriceLevel != null) {
      places = places.where((p) => p.normalizedPriceLevel == _filterPriceLevel).toList();
    }

    // Amenities filter (all selected amenities must match)
    if (_filterAmenities.isNotEmpty) {
      places = places.where((place) {
        return _filterAmenities.every(
          (a) => place.amenities.any(
            (pa) => pa.toLowerCase().contains(a.toLowerCase()),
          ),
        );
      }).toList();
    }

    // Radius filter (only when location is available)
    if (locationProvider.hasLocation && _filterRadiusKm > 0) {
      places = places.where((p) {
        final dist = placesProvider.getDistanceToPlace(
          userLat: locationProvider.currentLatitude!,
          userLng: locationProvider.currentLongitude!,
          place: p,
        );
        return dist <= _filterRadiusKm;
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _ExploreAppBar(onFilterTap: _openFilters),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 12, bottom: 120),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ExploreHeader(onFilterTap: _openFilters),
                  ),
                  const SizedBox(height: 24),
                  const NearMeSection(),
                  const SizedBox(height: 32),
                  const SocialDiscoverySection(),
                  const SizedBox(height: 32),
                  _CategoryRow(
                    categories: categories,
                    selectedIndex: selectedCategoryIndex,
                    onCategorySelected: (index) =>
                        setState(() => selectedCategoryIndex = index),
                  ),
                  const SizedBox(height: 28),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ...places.map((place) {
                      final distKm = locationProvider.hasLocation
                          ? placesProvider.getDistanceToPlace(
                              userLat: locationProvider.currentLatitude!,
                              userLng: locationProvider.currentLongitude!,
                              place: place,
                            )
                          : null;
                      return Padding(
                        padding: const EdgeInsets.only(
                            left: 20, right: 20, bottom: 24),
                        child: ExplorePlaceCard(
                          place: place,
                          distanceKm: distKm,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlaceDetailScreen(place: place),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addPlace),
        child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
      ),
    );
  }
}

// ── Extracted widgets ────────────────────────────────────────────────────────

class _ExploreHeader extends StatelessWidget {
  const _ExploreHeader({this.onFilterTap});
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Explore Addis',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        GestureDetector(
          onTap: onFilterTap,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.outline.withValues(alpha: 0.4)),
            ),
            child:
                const Icon(Icons.tune_rounded, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _ExploreAppBar extends StatelessWidget {
  const _ExploreAppBar({this.onFilterTap});
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final avatarUrl = currentUser?.profileImageUrl ?? '';

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu_rounded,
                size: 30, color: AppColors.primary),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'MeetMap Addis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
            ),
          ),
          // Real user avatar → navigates to own profile
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.4)),
              ),
              child: ClipOval(
                child: avatarUrl.isEmpty
                    ? Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.person_rounded,
                            color: AppColors.textSecondary, size: 22),
                      )
                    : CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.surfaceVariant),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.person_rounded,
                              color: AppColors.textSecondary, size: 22),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onCategorySelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Center(
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
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
