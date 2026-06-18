part of '../../../work_supply_catalog.dart';

final plumbingWaterHeaterCategory = _category('Water Heater', [
  _system('Water Heater Connections', [
    _type(
      'Supply Connectors',
      _variants(
        'Water Heater Supply Connector',
        'each',
        ['3/4 x 12 in', '3/4 x 18 in', '3/4 x 24 in'],
        ['water heater line'],
      ),
    ),
    _type(
      'Dielectric Nipples',
      _variants(
        'Water Heater Dielectric Nipple',
        'each',
        ['3/4 x 2 in', '3/4 x 3 in', '3/4 x 4 in'],
        ['dielectric nipple', 'water heater nipple'],
      ),
    ),
    _type(
      'Relief Valves',
      _variants(
        'Temperature and Pressure Relief Valve',
        'each',
        ['3/4 in'],
        ['t&p valve', 'tpr valve'],
      ),
    ),
    _type(
      'Drain Valves',
      _variants(
        'Water Heater Drain Valve',
        'each',
        ['3/4 in plastic', '3/4 in brass'],
        ['boiler drain', 'heater drain valve'],
      ),
    ),
    _type(
      'Expansion Tanks',
      _variants(
        'Expansion Tank',
        'each',
        ['2 gal', '4.5 gal'],
        ['thermal expansion tank'],
      ),
    ),
  ]),
]);
