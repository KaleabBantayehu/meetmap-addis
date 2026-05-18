import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class SocialLinksInput extends StatelessWidget {
  final TextEditingController controller;

  const SocialLinksInput({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'https://instagram.com/...',
        prefixIcon: const Icon(Icons.link_rounded),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: TextInputType.url,
    );
  }
}
