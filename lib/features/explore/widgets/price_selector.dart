import 'package:flutter/material.dart';
import 'custom_filter_chip.dart';

class PriceSelector extends StatelessWidget {
  final String selectedPrice;
  final ValueChanged<String> onPriceSelected;

  const PriceSelector({
    super.key,
    required this.selectedPrice,
    required this.onPriceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final prices = ['\$', '\$\$', '\$\$\$', '\$\$\$\$'];

    return Row(
      children: prices.map((price) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: price != prices.last ? 12.0 : 0.0),
            child: CustomFilterChip(
              label: price,
              isSelected: selectedPrice == price,
              onTap: () => onPriceSelected(price),
              expanded: true,
            ),
          ),
        );
      }).toList(),
    );
  }
}
