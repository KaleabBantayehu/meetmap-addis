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
import '../../../providers/reviews_provider.dart';

class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({super.key, this.place});

  final PlaceModel? place;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  String? _requestedReviewsPlaceId;

  void _fetchReviews(String placeId) {
    if (_requestedReviewsPlaceId == placeId) return;
    _requestedReviewsPlaceId = placeId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReviewsProvider>().fetchReviews(placeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final placesProvider = context.watch<PlacesProvider>();
    PlaceModel? providerPlace;
    if (widget.place != null) {
      for (final candidate in placesProvider.places) {
        if (candidate.id == widget.place!.id) {
          providerPlace = candidate;
          break;
        }
      }
    }
    final resolvedPlace =
        providerPlace ??
        widget.place ??
        (placesProvider.places.isNotEmpty ? placesProvider.places.first : null);

    if (resolvedPlace == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: placesProvider.isLoading
              ? const CircularProgressIndicator()
              : const Text(
                  'Place details are unavailable.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
        ),
      );
    }

    _fetchReviews(resolvedPlace.id);

    final reviewsProvider = context.watch<ReviewsProvider>();
    final reviews = reviewsProvider.getReviews(resolvedPlace.id);
    final reviewsAreComplete =
        reviewsProvider.hasLoaded(resolvedPlace.id) &&
        !reviewsProvider.hasMore(resolvedPlace.id);
    final displayedPlace = reviews.isEmpty || !reviewsAreComplete
        ? resolvedPlace
        : resolvedPlace.copyWith(
            rating:
                reviews.fold<double>(0, (sum, review) => sum + review.rating) /
                reviews.length,
            reviewCount: reviews.length,
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PlaceHeader(place: displayedPlace),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              18,
              20,
              32 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                PlaceInfoSection(place: displayedPlace),
                const SizedBox(height: 18),
                PlaceActionButtons(place: displayedPlace),
                const SizedBox(height: 24),
                PlaceDescription(place: displayedPlace),
                const SizedBox(height: 24),
                PlaceLocationMap(place: displayedPlace),
                const SizedBox(height: 24),
                PlaceReviewsSection(place: displayedPlace),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
