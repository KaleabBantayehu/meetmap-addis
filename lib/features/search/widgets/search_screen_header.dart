import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

class SearchScreenHeader extends StatelessWidget {
  const SearchScreenHeader({
    super.key,
    required this.controller,
    required this.isTyping,
    required this.onBack,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isTyping;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SearchInputField(
              controller: controller,
              isTyping: isTyping,
              onChanged: onChanged,
              onClear: onClear,
            ),
          ),
        ],
      ),
    );
  }
}

class SearchInputField extends StatelessWidget {
  const SearchInputField({
    super.key,
    required this.controller,
    required this.isTyping,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isTyping;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search for cafes, restaurants...',
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondary.withValues(alpha: 0.45),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: isTyping ? AppColors.primary : AppColors.textSecondary,
          size: 30,
        ),
        suffixIcon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: isTyping
              ? IconButton(
                  key: const ValueKey('clear-search'),
                  onPressed: onClear,
                  icon: Icon(
                    Icons.cancel_rounded,
                    color: AppColors.textSecondary.withValues(alpha: 0.72),
                    size: 30,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty-clear')),
        ),
        filled: true,
        fillColor: AppColors.surfaceVariant.withValues(alpha: 0.72),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
