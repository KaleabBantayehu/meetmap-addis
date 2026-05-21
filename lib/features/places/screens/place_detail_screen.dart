import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/places/widgets/place_action_buttons.dart';
import 'package:meetmap_addis/features/places/widgets/place_description.dart';
import 'package:meetmap_addis/features/places/widgets/place_header.dart';
import 'package:meetmap_addis/features/places/widgets/place_info_section.dart';
import 'package:meetmap_addis/features/places/widgets/place_location_map.dart';
import 'package:meetmap_addis/features/places/widgets/place_reviews_section.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'package:provider/provider.dart';
import '../../../providers/places_provider.dart';

class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({super.key, this.place});

  final PlaceModel? place;

  @override
  Widget build(BuildContext context) {
    final resolvedPlace =
        place ??
        (Provider.of<PlacesProvider>(context, listen: false).places.isNotEmpty
            ? Provider.of<PlacesProvider>(context, listen: false).places.first
            : null);

    if (resolvedPlace == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PlaceHeader(place: resolvedPlace),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                PlaceInfoSection(place: resolvedPlace),
                const SizedBox(height: 18),
                PlaceActionButtons(place: resolvedPlace),
                const SizedBox(height: 24),
                PlaceDescription(place: resolvedPlace),
                const SizedBox(height: 24),
                PlaceLocationMap(place: resolvedPlace),
                const SizedBox(height: 24),
                PlaceReviewsSection(place: resolvedPlace),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
