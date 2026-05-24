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
    return Row(
      children: PlaceModel.priceLevels.map((level) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: level != PlaceModel.priceLevels.last ? 12.0 : 0.0,
            ),
            child: CustomFilterChip(
              label: PlaceModel.priceLabelFor(level),
              isSelected: selectedPriceLevel == level,
              onTap: () => onPriceSelected(level),
              expanded: true,
            ),
          ),
        );
      }).toList(),
    );
  }
}
