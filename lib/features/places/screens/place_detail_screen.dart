import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/places/widgets/place_action_buttons.dart';
import 'package:meetmap_addis/features/places/widgets/place_description.dart';
import 'package:meetmap_addis/features/places/widgets/place_header.dart';
import 'package:meetmap_addis/features/places/widgets/place_info_section.dart';
import 'package:meetmap_addis/features/places/widgets/place_location_map.dart';
import 'package:meetmap_addis/features/places/widgets/place_reviews_section.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({super.key, this.place});

  final PlaceModel? place;

  static const PlaceModel _demoPlace = PlaceModel(
    id: '1',
    name: 'Tomoca Coffee',
    imageUrl:
        'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=1200&q=80',
    category: 'Cafe',
    location: 'Bole',
    rating: 4.8,
    priceRange: r'$$',
    isOpen: true,
    latitude: 9.03,
    longitude: 38.74,
    tags: ['Study', 'History', 'Iconic'],
    reviewCount: 1200,
  );

  @override
  Widget build(BuildContext context) {
    final currentPlace = place ?? _demoPlace;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PlaceHeader(place: currentPlace),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                PlaceInfoSection(place: currentPlace),
                const SizedBox(height: 18),
                PlaceActionButtons(place: currentPlace),
                const SizedBox(height: 24),
                PlaceDescription(place: currentPlace),
                const SizedBox(height: 24),
                PlaceLocationMap(place: currentPlace),
                const SizedBox(height: 24),
                PlaceReviewsSection(place: currentPlace),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
