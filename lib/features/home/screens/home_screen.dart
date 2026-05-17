import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/home/widgets/home_app_bar.dart';
import 'package:meetmap_addis/features/home/widgets/home_map_section.dart';
import 'package:meetmap_addis/shared/data/mock_places.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final place = mockPlaces.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const HomeAppBar(),

            Expanded(
              child: HomeMapSection(place: place),
            ),
          ],
        ),
      ),
    );
  }
}
