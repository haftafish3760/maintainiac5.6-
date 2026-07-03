part of '../../../work_supply_catalog.dart';

final hvacCondensateCategory = _category('Condensate', [
  _system('Drainage', [
    _type(
      'Condensate Pipe',
      _variants(
        'Condensate PVC Pipe',
        'stick',
        ['3/4 in', '1 in'],
        ['condensate line'],
      ),
    ),
    _type(
      'Condensate Fittings',
      _variants(
        'Condensate PVC Coupling',
        'each',
        ['3/4 in', '1 in'],
        ['condensate coupling', 'pvc drain coupling', 'pvc drain cplg'],
      ),
    ),
    _type(
      'Condensate Pumps',
      _variants('Condensate Pump', 'each', ['115V', '230V'], ['little pump']),
    ),
    _type(
      'Drain Treatment',
      _variants(
        'Condensate Drain Tablets',
        'pack',
        ['standard pack'],
        ['pan tabs'],
      ),
    ),
  ]),
]);
