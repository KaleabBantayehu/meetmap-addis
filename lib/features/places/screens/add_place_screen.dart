import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/widgets/custom_textfield.dart';
import 'package:meetmap_addis/shared/widgets/custom_button.dart';
import 'package:meetmap_addis/features/places/widgets/add_place_header.dart';
import 'package:meetmap_addis/features/places/widgets/image_upload_section.dart';
import 'package:meetmap_addis/features/places/widgets/category_selector.dart';
import 'package:meetmap_addis/features/places/widgets/place_purpose_selector.dart';
import 'package:meetmap_addis/features/places/widgets/amenity_selector.dart';
import 'package:meetmap_addis/features/places/widgets/price_range_input.dart';
import 'package:meetmap_addis/features/places/widgets/social_links_input.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _socialController = TextEditingController();

  String _selectedCategory = '';
  String _selectedPrice = '\$\$';
  final List<String> _selectedPurposes = [];
  final List<String> _selectedAmenities = [];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _socialController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Mock API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venue added successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AddPlaceHeader(
                title: 'Add New Venue',
                subtitle: 'Share a great spot with the community',
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Venue Name
                      Text(
                        'Venue Name',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _nameController,
                        hintText: 'e.g. Tomoca Coffee, Bole',
                        validator: (v) =>
                            v!.isEmpty ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 24),

                      // Location
                      Text(
                        'Location',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _locationController,
                        hintText: 'Search for address...',
                        prefixIcon: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.textSecondary,
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Please enter a location' : null,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.map_rounded,
                            color: AppColors.secondary,
                          ),
                          label: Text(
                            'Select on Map',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Category
                      Text(
                        'Category',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CategorySelector(
                        selectedCategory: _selectedCategory,
                        onCategorySelected: (category) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Price Range
                      Text(
                        'Price Range',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      PriceRangeInput(
                        selectedPrice: _selectedPrice,
                        onPriceSelected: (price) =>
                            setState(() => _selectedPrice = price),
                      ),
                      const SizedBox(height: 24),

                      // Place Purpose
                      Text(
                        "What's it good for?",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      PlacePurposeSelector(
                        selectedPurposes: _selectedPurposes,
                        onTogglePurpose: (purpose) {
                          setState(() {
                            if (_selectedPurposes.contains(purpose)) {
                              _selectedPurposes.remove(purpose);
                            } else {
                              _selectedPurposes.add(purpose);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Amenities
                      Text(
                        'Amenities',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AmenitySelector(
                        selectedAmenities: _selectedAmenities,
                        onToggleAmenity: (amenity) {
                          setState(() {
                            if (_selectedAmenities.contains(amenity)) {
                              _selectedAmenities.remove(amenity);
                            } else {
                              _selectedAmenities.add(amenity);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Venue Photos
                      Text(
                        'Venue Photos',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ImageUploadSection(
                        onTap: () {
                          // Mock photo picker
                        },
                      ),
                      const SizedBox(height: 20),

                      // Map Placeholder (like the UI design)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.8),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Mock grid lines
                              Opacity(
                                opacity: 0.2,
                                child: GridPaper(
                                  color: Colors.white,
                                  divisions: 2,
                                  subdivisions: 2,
                                  child: Container(),
                                ),
                              ),
                              const Icon(
                                Icons.location_on,
                                size: 48,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'Description',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Tell us a bit about this place...',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Phone Number
                      Text(
                        'Phone Number',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _phoneController,
                        hintText: '+251 9...',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),

                      // Social Links
                      Text(
                        'Social Media Link (Optional)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SocialLinksInput(controller: _socialController),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // Sticky Bottom CTA
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomButton(
                    text: 'Add Place',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'By submitting, you agree to our venue guidelines.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
