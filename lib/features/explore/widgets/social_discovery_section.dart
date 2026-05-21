import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/features/hangouts/screens/hangouts_screen.dart';
import 'package:meetmap_addis/routes/app_routes.dart';

import 'social_entry_card.dart';

class SocialDiscoverySection extends StatelessWidget {
  const SocialDiscoverySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meet & Connect',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Discover people, conversations, and communities',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Cards List
        SizedBox(
          height: 104,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            clipBehavior: Clip.none,
            children: [
              SocialEntryCard(
                title: 'Hangouts',
                description:
                    'Join coffee chats, study sessions, and local meetups',
                icon: Icons.coffee_rounded,
                iconColor: const Color(0xFFE65100),
                iconBackgroundColor: const Color(
                  0xFFE65100,
                ).withValues(alpha: 0.1),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HangoutsScreen()),
                  );
                },
              ),

              const SizedBox(width: 16),

              SocialEntryCard(
                title: 'Networking',
                description: 'Connect with professionals and local communities',
                icon: Icons.business_center_rounded,
                iconColor: const Color(0xFF1565C0),
                iconBackgroundColor: const Color(
                  0xFF1565C0,
                ).withValues(alpha: 0.1),
                onTap: () {
                  // Using named route for better consistency with project architecture
                  Navigator.pushNamed(context, AppRoutes.network);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
