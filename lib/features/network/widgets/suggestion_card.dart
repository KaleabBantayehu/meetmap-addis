import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/models/user_model.dart';

class SuggestionCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onFollow;

  const SuggestionCard({super.key, required this.user, this.onFollow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12, bottom: 10, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          CircleAvatar(
            radius: 34, // Slightly smaller to prevent overflow
            backgroundImage: NetworkImage(user.profileImageUrl),
            backgroundColor: AppColors.imagePlaceholder,
          ),
          const SizedBox(height: 10),
          Text(
            user.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            user.title ?? '',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(), // Pushes the button to the bottom
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'FOLLOW',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
