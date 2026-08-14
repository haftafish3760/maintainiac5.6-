part of 'maintenance_receipt_parser.dart';

final _renewalItemDefinitions = <_ItemDefinition>[
  _ItemDefinition(
    itemName: 'Key Fob Battery',
    pattern: RegExp(
      r'\b(?:key fob battery|remote key battery|keyless remote battery)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:key fob|remote key|keyless remote) battery (?:replace|replaced|replacement|installed)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Registration',
    pattern: RegExp(
      r'\b(?:vehicle registration|registration renewal|license plate renewal)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:vehicle registration|registration|license plate) (?:renewed|renewal completed)\b',
    ),
  ),
  _ItemDefinition(
    itemName: 'Inspection',
    pattern: RegExp(
      r'\b(?:vehicle inspection|safety inspection|emissions inspection|state inspection)\b',
    ),
    servicePattern: RegExp(
      r'\b(?:vehicle|safety|emissions|state) inspection (?:passed|completed|performed)\b',
    ),
  ),
];
