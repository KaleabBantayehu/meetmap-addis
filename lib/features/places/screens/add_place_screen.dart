import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/core/services/cloudinary_service.dart';
import 'package:meetmap_addis/core/services/gebeta_geocoding_service.dart';
import 'package:meetmap_addis/core/services/gebeta_map_service.dart';
import 'package:meetmap_addis/core/storage/connectivity_service.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:meetmap_addis/providers/places_provider.dart';
import 'package:meetmap_addis/shared/widgets/custom_textfield.dart';
import 'package:meetmap_addis/shared/widgets/custom_button.dart';
import 'package:meetmap_addis/features/places/widgets/add_place_header.dart';
import 'package:meetmap_addis/features/places/widgets/image_upload_section.dart';
import 'package:meetmap_addis/features/home/widgets/map_pin.dart';
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
  int _selectedPriceLevel = 2;
  final List<String> _selectedPurposes = [];
  final List<String> _selectedAmenities = [];
  File? _selectedImage;

  final CloudinaryService _cloudinaryService = CloudinaryService();
  final GebetaGeocodingService _geocodingService = GebetaGeocodingService();
  final GebetaMapService _mapService = const GebetaMapService();
  double? _selectedLatitude;
  double? _selectedLongitude;
  bool _isSettingLocationProgrammatically = false;
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _locationController.addListener(_onLocationInputChanged);
  }

  @override
  void dispose() {
    _locationController.removeListener(_onLocationInputChanged);
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _socialController.dispose();
    super.dispose();
  }

  void _onLocationInputChanged() {
    if (_isSettingLocationProgrammatically) return;
    if (_selectedLatitude != null || _selectedLongitude != null) {
      _selectedLatitude = null;
      _selectedLongitude = null;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_isUploading || _isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one image'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Description must be at least 20 characters'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!ConnectivityService.instance.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Internet connection required to publish a place.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final locationInput = _locationController.text.trim();
    if (locationInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a location'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _isSubmitting = true;
    });

    final placeProvider = context.read<PlacesProvider>();
    try {
      final geocoded =
          (_selectedLatitude != null && _selectedLongitude != null)
          ? GeocodingResult(
              latitude: _selectedLatitude!,
              longitude: _selectedLongitude!,
              formattedAddress: _locationController.text.trim(),
            )
          : await _geocodingService.forwardGeocode(locationInput);
      final imageUrl = await _cloudinaryService.uploadImage(
        _selectedImage!,
        'meetmap/places',
      );
      if (!mounted) return;

      setState(() => _isUploading = false);

      final newPlace = PlaceModel(
        id: '',
        name: _nameController.text.trim(),
        imageUrl: imageUrl,
        category: _selectedCategory,
        location: geocoded.formattedAddress,
        rating: 0,
        priceRange: '',
        isOpen: true,
        latitude: geocoded.latitude,
        longitude: geocoded.longitude,
        tags: List<String>.from(_selectedPurposes),
        reviewCount: 0,
        description: _descriptionController.text.trim(),
        priceLevel: _selectedPriceLevel,
        imageUrls: [imageUrl],
        amenities: List<String>.from(_selectedAmenities),
      );

      final success = await placeProvider.addPlace(newPlace);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Place published successfully.'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(placeProvider.errorMessage ?? 'Failed to add place'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isEmpty ? 'Unable to upload image' : message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _openMapPicker() async {
    final picked = await Navigator.of(context).push<GeocodingResult>(
      MaterialPageRoute(
        builder: (_) => _MapLocationPickerScreen(
          initialLat: _selectedLatitude,
          initialLng: _selectedLongitude,
          initialLocationText: _locationController.text.trim(),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    _isSettingLocationProgrammatically = true;
    setState(() {
      _selectedLatitude = picked.latitude;
      _selectedLongitude = picked.longitude;
      _locationController.text = picked.formattedAddress;
    });
    _isSettingLocationProgrammatically = false;
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
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.isEmpty) return 'Please enter a name';
                          if (name.length < 3) {
                            return 'Name must be at least 3 characters';
                          }
                          return null;
                        },
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
                          onPressed: _openMapPicker,
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
                        selectedPriceLevel: _selectedPriceLevel,
                        onPriceSelected: (price) =>
                            setState(() => _selectedPriceLevel = price),
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
                        onTap: _isUploading || _isSubmitting
                            ? null
                            : _pickImage,
                        selectedImage: _selectedImage,
                        isUploading: _isUploading,
                      ),
                      const SizedBox(height: 20),

                      // Map Placeholder (like the UI design)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 140,
                          width: double.infinity,
                          child: (_mapService.isConfigured &&
                                  _selectedLatitude != null &&
                                  _selectedLongitude != null)
                              ? Stack(
                                  children: [
                                    GebetaMap(
                                      initialCameraPosition: const CameraPosition(
                                        target: LatLng(
                                          GebetaMapService.addisLatitude,
                                          GebetaMapService.addisLongitude,
                                        ),
                                        zoom: GebetaMapService.defaultZoom,
                                      ),
                                      onMapCreated: (controller) async {
                                        await controller.moveCamera(
                                          CameraUpdate.newLatLngZoom(
                                            LatLng(
                                              _selectedLatitude!,
                                              _selectedLongitude!,
                                            ),
                                            14.0,
                                          ),
                                        );
                                      },
                                      apiKey: _mapService.apiKey,
                                    ),
                                    const Center(
                                      child: IgnorePointer(
                                        child: MapPin(icon: Icons.place_rounded),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  color: AppColors.surfaceVariant,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.map_outlined,
                                    color: AppColors.textSecondary,
                                  ),
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          if (value.trim().length < 20) {
                            return 'Description must be at least 20 characters';
                          }
                          return null;
                        },
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
                    text: _isUploading ? 'Uploading Image' : 'Add Place',
                    isLoading: _isUploading || _isSubmitting,
                    onPressed: _isUploading || _isSubmitting ? null : _submit,
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

class _MapLocationPickerScreen extends StatefulWidget {
  const _MapLocationPickerScreen({
    this.initialLat,
    this.initialLng,
    this.initialLocationText,
  });

  final double? initialLat;
  final double? initialLng;
  final String? initialLocationText;

  @override
  State<_MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<_MapLocationPickerScreen> {
  final GebetaMapService _mapService = const GebetaMapService();
  final GebetaGeocodingService _geocodingService = GebetaGeocodingService();
  GebetaMapController? _controller;
  LatLng? _selectedLatLng;
  String _resolvedAddress = '';
  bool _isResolvingAddress = false;
  bool _isStyleReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLatLng = LatLng(widget.initialLat!, widget.initialLng!);
    }
    _resolvedAddress = widget.initialLocationText?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
      ),
      body: Stack(
        children: [
          GebetaMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLatLng ??
                  const LatLng(
                    GebetaMapService.addisLatitude,
                    GebetaMapService.addisLongitude,
                  ),
              zoom: _selectedLatLng == null ? GebetaMapService.defaultZoom : 14,
            ),
            apiKey: _mapService.apiKey,
            onMapCreated: (controller) {
              _controller = controller;
            },
            onStyleLoadedCallback: () async {
              _isStyleReady = true;
              if (_selectedLatLng != null) {
                setState(() {});
              }
            },
            onMapClick: (point, latLng) async {
              await _showPinAt(latLng);
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: _selectedLatLng == null ? 0 : 1,
                child: const Center(
                  child: MapPin(icon: Icons.place_rounded),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedLatLng == null
                        ? 'Tap map to drop a pin.'
                        : (_isResolvingAddress
                              ? 'Resolving address...'
                              : (_resolvedAddress.isEmpty
                                    ? 'Address unavailable'
                                    : _resolvedAddress)),
                    style: const TextStyle(color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (_selectedLatLng != null)
                    Text(
                      'Lat: ${_selectedLatLng!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLatLng!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedLatLng == null
                          ? null
                          : () {
                              Navigator.of(context).pop(
                                GeocodingResult(
                                  latitude: _selectedLatLng!.latitude,
                                  longitude: _selectedLatLng!.longitude,
                                  formattedAddress: _resolvedAddress.isEmpty
                                      ? '${_selectedLatLng!.latitude.toStringAsFixed(6)}, ${_selectedLatLng!.longitude.toStringAsFixed(6)}'
                                      : _resolvedAddress,
                                ),
                              );
                            },
                      child: const Text('Use This Location'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPinAt(LatLng latLng) async {
    _selectedLatLng = latLng;
    final controller = _controller;
    if (controller == null || !_isStyleReady) return;
    await controller.moveCamera(CameraUpdate.newLatLng(latLng));
    setState(() {
      _isResolvingAddress = true;
    });
    try {
      final reversed = await _geocodingService.reverseGeocode(
        latLng.latitude,
        latLng.longitude,
      );
      if (!mounted) return;
      setState(() {
        _resolvedAddress = reversed.formattedAddress;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resolvedAddress = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingAddress = false;
        });
      }
    }
  }
}
