import 'package:flutter/material.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';
import 'custom_filter_chip.dart';

class PriceSelector extends StatelessWidget {
  final int? selectedPriceLevel;
  final ValueChanged<int> onPriceSelected;

  const PriceSelector({
    super.key,
    required this.selectedPriceLevel,
    required this.onPriceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: PlaceModel.priceLevels.map((level) {
        return CustomFilterChip(
          label: PlaceModel.priceLabelFor(level),
          isSelected: selectedPriceLevel == level,
          onTap: () => onPriceSelected(level),
        );
      }).toList(),
    );
  }
}
