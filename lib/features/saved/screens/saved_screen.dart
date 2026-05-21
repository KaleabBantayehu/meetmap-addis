import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/places/screens/place_detail_screen.dart';
import 'package:meetmap_addis/features/saved/widgets/saved_category_chips.dart';
import 'package:meetmap_addis/features/saved/widgets/saved_empty_state.dart';
import 'package:meetmap_addis/features/saved/widgets/saved_place_card.dart';
import 'package:meetmap_addis/features/saved/widgets/saved_screen_header.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:provider/provider.dart';
import 'package:meetmap_addis/providers/saved_provider.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  int selectedCategoryIndex = 0;

  static const List<String> categories = [
    'All Places',
    'Cafes',
    'Hotels',
    'Parks',
  ];

  List<PlaceModel> getVisiblePlaces(List<PlaceModel> savedPlaces) {
    if (selectedCategoryIndex == 0) {
      return savedPlaces;
    }

    final selectedCategory = categories[selectedCategoryIndex].toLowerCase();
    return savedPlaces.where((place) {
      final category = place.category.toLowerCase();
      if (selectedCategory == 'cafes') {
        return category.contains('cafe') ||
            place.name.toLowerCase().contains('coffee') ||
            place.tags.any((tag) => tag.toLowerCase().contains('coffee'));
      }

      return category.contains(
        selectedCategory.substring(0, selectedCategory.length - 1),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SavedProvider>(context, listen: false);
      if (provider.savedPlaces.isEmpty) {
        provider.fetchSavedPlaces();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final savedProvider = Provider.of<SavedProvider>(context);
    final places = getVisiblePlaces(savedProvider.savedPlaces);
    final isLoading = savedProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SavedScreenHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
                children: [
                  SavedCategoryChips(
                    categories: categories,
                    selectedIndex: selectedCategoryIndex,
                    onSelected: (value) {
                      setState(() => selectedCategoryIndex = value);
                    },
                  ),
                  const SizedBox(height: 28),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (places.isEmpty)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.48,
                      ),
                      child: const SavedEmptyState(),
                    )
                  else
                    ...places.map(
                      (place) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: SavedPlaceCard(
                          place: place,
                          distanceLabel: distanceLabelFor(place.id),
                          statusLabel: statusLabelFor(place),
                          isSaved: savedProvider.isSaved(place.id),
                          onTap: () => openPlaceDetails(place),
                          onSaveToggle: () => savedProvider.toggleSaved(place),
                          onRemove: () => savedProvider.removeSaved(place.id),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void openPlaceDetails(PlaceModel place) {
    // TODO: Replace direct mock navigation with backend-backed place lookup.
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)));
  }

  String distanceLabelFor(String placeId) {
    switch (placeId) {
      case '1':
        return '1.2 km';
      case '2':
        return '0.5 km';
      case '3':
        return '3.8 km';
      default:
        return 'Nearby';
    }
  }

  String statusLabelFor(PlaceModel place) {
    if (place.id == '3') {
      return 'Closing Soon';
    }
    return place.isOpen ? 'Open Now' : 'Closed';
  }
}
