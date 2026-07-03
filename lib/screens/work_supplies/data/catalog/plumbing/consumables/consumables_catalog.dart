part of '../../../work_supply_catalog.dart';

final plumbingConsumablesCategory = _category('Consumables', [
  _system('Sealants', [
    _type(
      'Thread Sealants',
      _variants(
        'Pipe Joint Compound',
        'tube',
        ['4 oz', '8 oz', '16 oz'],
        ['pipe dope', 'thread paste', 'thread sealant'],
      ),
    ),
    _type(
      'Thread Tape',
      _variants(
        'PTFE Thread Tape',
        'roll',
        ['1/2 in x 260 in', '3/4 in x 520 in'],
        ['teflon tape'],
      ),
    ),
    _type(
      'PVC Cement',
      _variants(
        'PVC Cement',
        'can',
        ['4 oz', '8 oz', '16 oz'],
        ['glue', 'solvent cement'],
      ),
    ),
    _type(
      'CPVC Cement',
      _variants(
        'CPVC Cement',
        'can',
        ['4 oz', '8 oz', '16 oz'],
        ['cpvc glue', 'yellow glue'],
      ),
    ),
    _type(
      'PVC Primer',
      _variants(
        'PVC Primer',
        'can',
        ['4 oz', '8 oz', '16 oz', '32 oz'],
        ['purple primer', 'pipe primer'],
      ),
    ),
    _type(
      'Plumber Putty',
      _variants(
        'Plumber Putty',
        'tub',
        ['14 oz', '32 oz', '5 lb'],
        ['putty', 'sink putty'],
      ),
    ),
    _type(
      'Silicone Sealant',
      _variants(
        'Silicone Sealant',
        'tube',
        ['2.8 oz clear', '10 oz clear', '10 oz white'],
        ['silicone caulk', 'kitchen bath silicone'],
      ),
    ),
    _type(
      'Pipe Lubricant',
      _variants(
        'Pipe Lubricant',
        'tub',
        ['1 qt', '1 gal'],
        ['pipe lube', 'gasket lubricant', 'joint lubricant'],
      ),
    ),
  ]),
]);
