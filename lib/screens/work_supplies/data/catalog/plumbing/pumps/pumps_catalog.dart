part of '../../../work_supply_catalog.dart';

final plumbingPumpsCategory = _category('Pumps', [
  _system('Sump and Condensate', [
    _type(
      'Sump Pumps',
      _variants(
        'Sump Pump',
        'each',
        ['1/4 hp', '1/3 hp', '1/2 hp', '3/4 hp'],
        ['submersible pump'],
      ),
    ),
    _type(
      'Condensate Pumps',
      _variants(
        'Condensate Pump',
        'each',
        ['115V', '230V'],
        ['condensate removal pump'],
      ),
    ),
    _type(
      'Pump Check Valves',
      _variants(
        'Pump Check Valve',
        'each',
        ['1-1/4 in', '1-1/2 in', '2 in'],
        ['sump check valve'],
      ),
    ),
    _type(
      'Pump Discharge Hose Kits',
      _variants(
        'Pump Discharge Hose Kit',
        'kit',
        ['1-1/4 in x 24 ft', '1-1/2 in x 24 ft', '2 in x 24 ft'],
        ['sump pump hose', 'discharge hose'],
      ),
    ),
    _type(
      'Condensate Pump Tubing',
      _variants(
        'Condensate Pump Tubing',
        'roll',
        ['3/8 in x 20 ft', '3/8 in x 50 ft', '1/2 in x 20 ft'],
        ['condensate tubing', 'vinyl tubing'],
      ),
    ),
    _type(
      'Pump Float Switches',
      _variants(
        'Pump Float Switch',
        'each',
        ['tethered', 'vertical', 'piggyback'],
        ['sump float', 'float switch'],
      ),
    ),
  ]),
]);
