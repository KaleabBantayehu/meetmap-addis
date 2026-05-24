import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

import '../../../shared/widgets/custom_button.dart';
import '../widgets/amenity_checkbox_card.dart';
import '../widgets/filter_section_title.dart';
import '../widgets/price_selector.dart';
import '../widgets/purpose_selector.dart';
import '../widgets/radius_selector_card.dart';
import '../widgets/rating_selector.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  int? _selectedPriceLevel = 1;
  List<String> _selectedPurposes = ['Study', 'Date'];
  String _selectedRating = '4.5+';
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
      _selectedRating = '';
      _selectedAmenities = [];
      _radius = '5km';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  horizontal: 24,
                  vertical: 16,
                ),
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
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: (constraints.maxWidth - 16) / 2,
                              child: AmenityCheckboxCard(
                                title: 'Power Outlets',
                                subtitle: 'Available at tables',
                                isChecked: _selectedAmenities.contains(
                                  'Power Outlets',
                                ),
                                onTap: () => _toggleAmenity('Power Outlets'),
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 16) / 2,
                              child: AmenityCheckboxCard(
                                title: 'Parking',
                                subtitle: 'On-site space',
                                isChecked: _selectedAmenities.contains(
                                  'Parking',
                                ),
                                onTap: () => _toggleAmenity('Parking'),
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 16) / 2,
                              child: AmenityCheckboxCard(
                                title: 'AC',
                                subtitle: 'Climate control',
                                isChecked: _selectedAmenities.contains('AC'),
                                onTap: () => _toggleAmenity('AC'),
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 16) / 2,
                              child: AmenityCheckboxCard(
                                title: 'Accessibility',
                                subtitle: 'Ramps available',
                                isChecked: _selectedAmenities.contains(
                                  'Accessibility',
                                ),
                                onTap: () => _toggleAmenity('Accessibility'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Radius
                    RadiusSelectorCard(
                      currentRadius: _radius,
                      onTap: () {
                        // TODO: Open radius selection bottom sheet or slider
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                            side: const BorderSide(color: AppColors.outline),
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
                        text: 'Show 142 Results',
                        onPressed: () {
                          // TODO: Apply filters and query API/Firestore
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
