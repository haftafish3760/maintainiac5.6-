part of 'maintenance_receipt_parser.dart';

final _wheelBalancingItemDefinitions = <_ItemDefinition>[
  _ItemDefinition(
    itemName: 'Wheel Balancing',
    pattern: RegExp(
      r'\b(?:wheel balanc(?:e|ing)|tire balanc(?:e|ing)|road force balanc(?:e|ing))\b',
    ),
    servicePattern: RegExp(
      r'\b(?:wheel balanc(?:e|ing)|tire balanc(?:e|ing)|road force balanc(?:e|ing)|wheels? balanced|tires? balanced)\b',
    ),
    detailA: _wheelBalancingType,
  ),
];
