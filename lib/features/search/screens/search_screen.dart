import 'dart:async';
import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/core/storage/connectivity_service.dart';
import 'package:meetmap_addis/features/places/screens/place_detail_screen.dart';
import 'package:meetmap_addis/features/search/widgets/browse_category_grid.dart';
import 'package:meetmap_addis/features/search/widgets/recent_search_chips.dart';
import 'package:meetmap_addis/features/search/widgets/search_empty_state.dart';
import 'package:meetmap_addis/features/search/widgets/search_result_card.dart';
import 'package:meetmap_addis/features/search/widgets/search_screen_header.dart';
import 'package:meetmap_addis/features/search/widgets/search_section_header.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:provider/provider.dart';
import 'package:meetmap_addis/providers/places_provider.dart';
import 'package:meetmap_addis/providers/saved_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  String selectedCategory = '';
  String query = '';
  Timer? _debounce;

  static const List<String> defaultSuggestionIds = ['2', '4', '1', '5'];

  List<PlaceModel> getFilteredPlaces(List<PlaceModel> places) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedCategory = selectedCategory.toLowerCase();

    final sourcePlaces = normalizedQuery.isEmpty && normalizedCategory.isEmpty
        ? defaultSuggestionIds
              .map((id) {
                final found = places.where((place) => place.id == id);
                return found.isNotEmpty ? found.first : null;
              })
              .whereType<PlaceModel>()
              .toList()
        : places;

    return sourcePlaces.where((place) {
      final searchableText = [
        place.name,
        place.category,
        place.location,
        ...place.tags,
      ].join(' ').toLowerCase();

      final matchesQuery =
          normalizedQuery.isEmpty || searchableText.contains(normalizedQuery);
      final matchesCategory =
          normalizedCategory.isEmpty ||
          searchableText.contains(normalizedCategory) ||
          (normalizedCategory == 'cafes' &&
              searchableText.contains('coffee')) ||
          (normalizedCategory == 'dining' &&
              (searchableText.contains('dining') ||
                  searchableText.contains('international')));

      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PlacesProvider>(context, listen: false);
      if (provider.places.isEmpty) {
        provider.fetchPlaces();
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PlacesProvider>(context);
    final savedProvider = Provider.of<SavedProvider>(context);
    
    // Determine the list of places to display:
    final List<PlaceModel> results;
    if (query.trim().isEmpty) {
      results = defaultSuggestionIds
          .map((id) {
            final found = placesProvider.places.where((place) => place.id == id);
            return found.isNotEmpty ? found.first : null;
          })
          .whereType<PlaceModel>()
          .toList();
    } else if (ConnectivityService.instance.isConnected) {
      results = placesProvider.searchResults;
    } else {
      results = getFilteredPlaces(placesProvider.places);
    }

    final isLoading = placesProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SearchScreenHeader(
              controller: searchController,
              isTyping: query.isNotEmpty,
              onBack: () => Navigator.of(context).pop(),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
                
                // Debounce the remote search request
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  if (mounted && value.isNotEmpty && ConnectivityService.instance.isConnected) {
                    placesProvider.searchPlaces(value);
                  }
                });
              },
              onClear: clearSearch,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  placesProvider.addRecentSearch(value);
                  if (ConnectivityService.instance.isConnected) {
                    placesProvider.searchPlaces(value);
                  }
                }
              },
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 34, 20, 32),
                children: [
                  RecentSearchChips(
                    searches: placesProvider.recentSearches,
                    onSelected: useRecentSearch,
                    onRemove: (value) => placesProvider.removeRecentSearch(value),
                    onClearAll: () => placesProvider.clearRecentSearches(),
                  ),
                  const SizedBox(height: 38),
                  const SearchSectionHeader(title: 'Suggested Places'),
                  const SizedBox(height: 20),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (results.isEmpty)
                    SearchEmptyState(query: query)
                  else
                    ...results.map(
                      (place) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SearchResultCard(
                          place: place,
                          distanceLabel: distanceLabelFor(place.id),
                          isSaved: savedProvider.isSaved(place.id),
                          onTap: () {
                            if (query.isNotEmpty) {
                              placesProvider.addRecentSearch(query);
                            } else {
                              placesProvider.addRecentSearch(place.name);
                            }
                            openPlaceDetails(place);
                          },
                          onSaveToggle: () => savedProvider.toggleSaved(place),
                        ),
                      ),
                    ),
                  const SizedBox(height: 34),
                  BrowseCategoryGrid(
                    selectedCategory: selectedCategory,
                    onCategorySelected: selectCategory,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void clearSearch() {
    searchController.clear();
    setState(() => query = '');
  }

  void useRecentSearch(String value) {
    searchController.text = value;
    setState(() => query = value);
    
    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
    placesProvider.addRecentSearch(value);
    
    if (ConnectivityService.instance.isConnected) {
      placesProvider.searchPlaces(value);
    }
  }

  void selectCategory(String category) {
    final nextCategory = selectedCategory == category ? '' : category;
    setState(() {
      selectedCategory = nextCategory;
    });
    
    if (ConnectivityService.instance.isConnected) {
      final activeQuery = nextCategory.isNotEmpty ? nextCategory : query;
      if (activeQuery.isNotEmpty) {
        Provider.of<PlacesProvider>(context, listen: false).searchPlaces(activeQuery);
      }
    }
  }

  void openPlaceDetails(PlaceModel place) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)));
  }

  String distanceLabelFor(String placeId) {
    switch (placeId) {
      case '1':
        return '2.4 km';
      case '2':
        return '1.2 km';
      case '4':
        return '0.8 km';
      case '5':
        return '3.1 km';
      default:
        return '1.8 km';
    }
  }
}
