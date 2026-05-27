import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/home/widgets/home_app_bar.dart';
import 'package:meetmap_addis/features/home/widgets/home_map_section.dart';
import 'package:provider/provider.dart';
import '../../../providers/places_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PlacesProvider>(context);
    final places = placesProvider.places;
    final isLoading = placesProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const HomeAppBar(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : places.isEmpty
                  ? const Center(
                      child: Text(
                        'No places found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : HomeMapSection(places: places),
            ),
          ],
        ),
      ),
    );
  }
}
