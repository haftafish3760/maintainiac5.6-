part of '../../../work_supply_catalog.dart';

final hvacTapeAndSealantsCategory = _category('Tape and Sealants', [
  _system('Duct Seal', [
    _type(
      'Foil Tape',
      _variants(
        'Foil HVAC Tape',
        'roll',
        ['2 in x 50 yd', '3 in x 50 yd'],
        ['metal tape'],
      ),
    ),
    _type(
      'Mastic',
      _variants('Duct Mastic', 'bucket', ['1 gal', '2 gal'], ['duct sealant']),
    ),
  ]),
]);
