import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class SettingsLogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SettingsLogoutButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 32, bottom: 40),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFEBEE), // Light red
          foregroundColor: AppColors.error,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
