import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/providers/location_provider.dart';
import 'package:meetmap_addis/providers/places_provider.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/custom_button.dart';
import '../widgets/amenity_checkbox_card.dart';
import '../widgets/filter_section_title.dart';
import '../widgets/price_selector.dart';
import '../widgets/purpose_selector.dart';
import '../widgets/radius_selector_card.dart';
import '../widgets/rating_selector.dart';

/// Available radius options shown in the picker sheet.
const _kRadiusOptions = ['1km', '2km', '5km', '10km', '25km'];

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  int? _selectedPriceLevel = 1;
  List<String> _selectedPurposes = ['Study', 'Date'];
  String _selectedRating = 'Any';
  List<String> _selectedAmenities = ['Power Outlets', 'AC'];
  String _radius = '5km';

  void _togglePurpose(String purpose) {
    setState(() {
      if (_selectedPurposes.contains(purpose)) {
        _selectedPurposes.remove(purpose);
      } else {
        _selectedPurposes.add(purpose);
      }
    });
  }

  void _toggleAmenity(String amenity) {
    setState(() {
      if (_selectedAmenities.contains(amenity)) {
        _selectedAmenities.remove(amenity);
      } else {
        _selectedAmenities.add(amenity);
      }
    });
  }

  void _resetAll() {
    setState(() {
      _selectedPriceLevel = null;
      _selectedPurposes = [];
      _selectedRating = 'Any';
      _selectedAmenities = [];
      _radius = '5km';
    });
  }

  /// Opens a bottom sheet to pick a radius value.
  void _pickRadius() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Radius',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 16),
                ..._kRadiusOptions.map((option) {
                  final isSelected = option == _radius;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _radius = option);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.outline.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Within $option',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Counts how many places match the current filters.
  int _computeResultCount(
      PlacesProvider placesProvider, LocationProvider locationProvider) {
    final places = placesProvider.places;
    if (places.isEmpty) return 0;

    final minRating = _selectedRating == 'Any'
        ? 0.0
        : double.tryParse(_selectedRating.replaceAll('+', '')) ?? 0.0;
    final radiusKm = double.tryParse(_radius.replaceAll('km', '')) ?? 5.0;

    return places.where((place) {
      // Rating gate
      if (minRating > 0 && place.rating < minRating) return false;

      // Price gate
      if (_selectedPriceLevel != null &&
          place.normalizedPriceLevel != _selectedPriceLevel) return false;

      // Radius gate (only if we have location)
      if (locationProvider.hasLocation) {
        final dist = placesProvider.getDistanceToPlace(
          userLat: locationProvider.currentLatitude!,
          userLng: locationProvider.currentLongitude!,
          place: place,
        );
        if (dist > radiusKm) return false;
      }

      // Amenity gate
      if (_selectedAmenities.isNotEmpty) {
        final matchesAll = _selectedAmenities.every(
          (a) => place.amenities.any(
            (pa) => pa.toLowerCase().contains(a.toLowerCase()),
          ),
        );
        if (!matchesAll) return false;
      }

      return true;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placesProvider = context.watch<PlacesProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final resultCount =
        _computeResultCount(placesProvider, locationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Filters',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _resetAll,
            child: Text(
              'Reset',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price Range
                    const FilterSectionTitle(title: 'Price Range'),
                    const SizedBox(height: 16),
                    PriceSelector(
                      selectedPriceLevel: _selectedPriceLevel,
                      onPriceSelected: (val) =>
                          setState(() => _selectedPriceLevel = val),
                    ),

                    const SizedBox(height: 32),

                    // Purpose
                    const FilterSectionTitle(
                      title: 'Purpose',
                      subtitle: 'Select multiple',
                    ),
                    const SizedBox(height: 16),
                    PurposeSelector(
                      selectedPurposes: _selectedPurposes,
                      onTogglePurpose: _togglePurpose,
                    ),

                    const SizedBox(height: 32),

                    // Minimum Rating
                    const FilterSectionTitle(title: 'Minimum Rating'),
                    const SizedBox(height: 16),
                    RatingSelector(
                      selectedRating: _selectedRating,
                      onRatingSelected: (val) =>
                          setState(() => _selectedRating = val),
                    ),

                    const SizedBox(height: 32),

                    // Amenities
                    const FilterSectionTitle(title: 'Amenities'),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final w = (constraints.maxWidth - 16) / 2;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: w,
                              child: AmenityCheckboxCard(
                                title: 'Power Outlets',
                                subtitle: 'Available at tables',
                                isChecked: _selectedAmenities
                                    .contains('Power Outlets'),
                                onTap: () =>
                                    _toggleAmenity('Power Outlets'),
                              ),
                            ),
                            SizedBox(
                              width: w,
                              child: AmenityCheckboxCard(
                                title: 'Parking',
                                subtitle: 'On-site space',
                                isChecked:
                                    _selectedAmenities.contains('Parking'),
                                onTap: () => _toggleAmenity('Parking'),
                              ),
                            ),
                            SizedBox(
                              width: w,
                              child: AmenityCheckboxCard(
                                title: 'AC',
                                subtitle: 'Climate control',
                                isChecked:
                                    _selectedAmenities.contains('AC'),
                                onTap: () => _toggleAmenity('AC'),
                              ),
                            ),
                            SizedBox(
                              width: w,
                              child: AmenityCheckboxCard(
                                title: 'Accessibility',
                                subtitle: 'Ramps available',
                                isChecked: _selectedAmenities
                                    .contains('Accessibility'),
                                onTap: () =>
                                    _toggleAmenity('Accessibility'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Radius — tapping opens picker sheet
                    RadiusSelectorCard(
                      currentRadius: _radius,
                      onTap: _pickRadius,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom bar
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.outline, width: 0.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _resetAll,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Reset All',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: CustomButton(
                        text: resultCount > 0
                            ? 'Show $resultCount Results'
                            : 'No Results',
                        onPressed: () {
                          Navigator.pop(context, {
                            'priceLevel': _selectedPriceLevel,
                            'purposes': _selectedPurposes,
                            'rating': _selectedRating,
                            'amenities': _selectedAmenities,
                            'radius': _radius,
                          });
                        },
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
