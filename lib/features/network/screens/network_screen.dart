import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/network_provider.dart';
import '../widgets/network_search_bar.dart';
import '../widgets/suggestion_card.dart';
import '../widgets/trending_reviewer_card.dart';

void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Coming soon!'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ),
  );
}

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NetworkProvider>(context, listen: false);
      if (provider.suggestedUsers.isEmpty &&
          provider.trendingReviewers.isEmpty) {
        provider.fetchNetworkData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final networkProvider = Provider.of<NetworkProvider>(context);
    final suggested = networkProvider.suggestedUsers;
    final trending = networkProvider.trendingReviewers;
    final isLoading = networkProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _showComingSoon(context),
        ),
        title: const Text('Network'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () => _showComingSoon(context),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=me'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const NetworkSearchBar(),
            const SizedBox(height: 24),
            _buildSectionHeader('Suggested for you', onSeeAll: () {}),
            const SizedBox(height: 16),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (suggested.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No suggestions yet — check back soon.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              SizedBox(
                height: 230,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggested.length,
                  clipBehavior: Clip.none,
                  itemBuilder: (context, index) {
                    return SuggestionCard(
                      user: suggested[index],
                      onFollow: () {},
                    );
                  },
                ),
              ),
            const SizedBox(height: 32),
            const Text(
              'Trending Reviewers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trending.length,
                itemBuilder: (context, index) {
                  return TrendingReviewerCard(
                    user: trending[index],
                    onFollow: () {},
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text(
            'View All',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
