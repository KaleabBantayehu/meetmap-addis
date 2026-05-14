import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/places/screens/place_detail_screen.dart';
import 'package:meetmap_addis/features/search/widgets/browse_category_grid.dart';
import 'package:meetmap_addis/features/search/widgets/recent_search_chips.dart';
import 'package:meetmap_addis/features/search/widgets/search_empty_state.dart';
import 'package:meetmap_addis/features/search/widgets/search_result_card.dart';
import 'package:meetmap_addis/features/search/widgets/search_screen_header.dart';
import 'package:meetmap_addis/features/search/widgets/search_section_header.dart';
import 'package:meetmap_addis/shared/data/mock_places.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  final Set<String> savedPlaceIds = {'1', '2'};
  final List<String> recentSearches = ['Tomoca Coffee', 'Bole Road', 'Co-work'];
  String selectedCategory = '';
  String query = '';

  static const List<String> defaultSuggestionIds = ['2', '4', '1', '5'];

  List<PlaceModel> get filteredPlaces {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedCategory = selectedCategory.toLowerCase();

    final sourcePlaces = normalizedQuery.isEmpty && normalizedCategory.isEmpty
        ? defaultSuggestionIds
            .map((id) => mockPlaces.where((place) => place.id == id).first)
            .toList()
        : mockPlaces;

    return sourcePlaces.where((place) {
      final searchableText = [
        place.name,
        place.category,
        place.location,
        ...place.tags,
      ].join(' ').toLowerCase();

      final matchesQuery =
          normalizedQuery.isEmpty || searchableText.contains(normalizedQuery);
      final matchesCategory = normalizedCategory.isEmpty ||
          searchableText.contains(normalizedCategory) ||
          (normalizedCategory == 'cafes' && searchableText.contains('coffee')) ||
          (normalizedCategory == 'dining' &&
              (searchableText.contains('dining') ||
                  searchableText.contains('international')));

      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = filteredPlaces;

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
                // TODO: Debounce and forward search text to backend search API.
                setState(() => query = value);
              },
              onClear: clearSearch,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 34, 20, 32),
                children: [
                  RecentSearchChips(
                    searches: recentSearches,
                    onSelected: useRecentSearch,
                    onRemove: removeRecentSearch,
                    onClearAll: clearRecentSearches,
                  ),
                  const SizedBox(height: 38),
                  const SearchSectionHeader(title: 'Suggested Places'),
                  const SizedBox(height: 20),
                  if (results.isEmpty)
                    SearchEmptyState(query: query)
                  else
                    ...results.map(
                      (place) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SearchResultCard(
                          place: place,
                          distanceLabel: distanceLabelFor(place.id),
                          isSaved: savedPlaceIds.contains(place.id),
                          onTap: () => openPlaceDetails(place),
                          onSaveToggle: () => toggleSaved(place.id),
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
  }

  void removeRecentSearch(String value) {
    // TODO: Persist recent search removals for the signed-in user.
    setState(() => recentSearches.remove(value));
  }

  void clearRecentSearches() {
    // TODO: Clear recent searches through user search history API.
    setState(recentSearches.clear);
  }

  void selectCategory(String category) {
    // TODO: Send category filter to backend search endpoint.
    setState(() {
      selectedCategory = selectedCategory == category ? '' : category;
    });
  }

  void toggleSaved(String placeId) {
    // TODO: Persist saved state to backend profile service.
    setState(() {
      if (savedPlaceIds.contains(placeId)) {
        savedPlaceIds.remove(placeId);
      } else {
        savedPlaceIds.add(placeId);
      }
    });
  }

  void openPlaceDetails(PlaceModel place) {
    // TODO: Replace mock model navigation with API-backed place lookup.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
    );
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
