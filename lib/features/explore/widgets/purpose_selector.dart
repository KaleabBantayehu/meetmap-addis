import 'package:flutter/material.dart';
import 'custom_filter_chip.dart';

class PurposeSelector extends StatelessWidget {
  final List<String> selectedPurposes;
  final ValueChanged<String> onTogglePurpose;

  const PurposeSelector({
    super.key,
    required this.selectedPurposes,
    required this.onTogglePurpose,
  });

  @override
  Widget build(BuildContext context) {
    final purposes = ['Study', 'Meeting', 'Date', 'Quiet', 'Fast WiFi', 'Outdoor'];
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: purposes.map((purpose) {
        return CustomFilterChip(
          label: purpose,
          isSelected: selectedPurposes.contains(purpose),
          showCheckmark: true,
          onTap: () => onTogglePurpose(purpose),
        );
      }).toList(),
    );
  }
}
