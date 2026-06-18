part of '../../../work_supply_catalog.dart';

final hvacDuctworkAndAirDistributionCategory = _category(
  'Ductwork and Air Distribution',
  [
    _system('Flexible Duct', [
      _type(
        'Insulated Flex Duct',
        _variants(
          'Insulated Flex Duct',
          'box',
          ['6 in R-6', '8 in R-6', '10 in R-6', '12 in R-6', '8 in R-8'],
          ['flex duct', 'insulated duct'],
        ),
      ),
    ]),
    _system('Metal Duct Fittings', [
      _type(
        'Duct Elbows',
        _variants(
          'Duct Elbow',
          'each',
          ['6 in', '8 in', '10 in', '12 in'],
          ['sheet metal elbow'],
        ),
      ),
      _type(
        'Duct Collars',
        _variants(
          'Duct Start Collar',
          'each',
          ['6 in', '8 in', '10 in', '12 in'],
          ['takeoff collar'],
        ),
      ),
    ]),
    _system('Registers and Grilles', [
      _type(
        'Floor Registers',
        _variants(
          'Floor Register',
          'each',
          ['2 x 10', '2 x 12', '4 x 10', '4 x 12'],
          ['vent register'],
        ),
      ),
      _type(
        'Return Grilles',
        _variants(
          'Return Air Grille',
          'each',
          ['14 x 20', '16 x 20', '20 x 20', '20 x 25'],
          ['return grille'],
        ),
      ),
    ]),
  ],
);
