import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/places/screens/place_map_screen.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class PlaceLocationMap extends StatelessWidget {
  const PlaceLocationMap({super.key, required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tappable map preview — opens in-app Gebeta map
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlaceMapScreen(place: place),
              ),
            ),
            child: Stack(
              children: [
                _StaticMapPreview(place: place),
                // Tap hint overlay
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_full_rounded,
                            color: Colors.white, size: 13),
                        SizedBox(width: 4),
                        Text(
                          'Open Map',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.map_rounded,
                  color: Color(0xFF76817C),
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '${place.location}, Addis Ababa, Ethiopia\n${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticMapPreview extends StatelessWidget {
  const _StaticMapPreview({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.18,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4F0C9), Color(0xFFEAE5B4)],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 170,
              color: Colors.white.withValues(alpha: 0.58),
            ),
            Positioned(
              left: 34,
              right: 34,
              bottom: 26,
              child: Container(
                height: 2,
                color: Colors.white.withValues(alpha: 0.48),
              ),
            ),
            Semantics(
              label: '${place.name} location preview',
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
