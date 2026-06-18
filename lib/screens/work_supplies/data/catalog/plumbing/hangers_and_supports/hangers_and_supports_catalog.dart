part of '../../../work_supply_catalog.dart';

final plumbingHangersAndSupportsCategory = _category('Hangers and Supports', [
  _system('Pipe Supports', [
    _type(
      'Pipe Straps',
      _variants('Pipe Strap', 'each', _pipeSizes, [
        'pipe strap',
        'one hole strap',
        'two hole strap',
      ]),
    ),
    _type(
      'Riser Clamps',
      _variants('Riser Clamp', 'each', _pipeSizes, ['pipe clamp']),
    ),
    _type(
      'Split Ring Hangers',
      _variants('Split Ring Hanger', 'each', _pipeSizes, [
        'pipe hanger',
        'split ring',
      ]),
    ),
    _type(
      'J-Hooks',
      _variants('Pipe J-Hook', 'each', _supplySizes, [
        'pex j hook',
        'pipe hook',
      ]),
    ),
    _type(
      'Bell Hangers',
      _variants('Bell Hanger', 'each', _supplySizes, [
        'copper bell hanger',
        'pipe bell hanger',
      ]),
    ),
    _type(
      'Stud Guards',
      _variants(
        'Stud Guard Plate',
        'each',
        ['1-1/2 x 3 in', '1-1/2 x 5 in', '3 x 5 in'],
        ['nail plate', 'stud plate', 'protection plate'],
      ),
    ),
    _type(
      'Pipe Insulation',
      _variants(
        'Pipe Insulation',
        'stick',
        ['1/2 in x 6 ft', '3/4 in x 6 ft', '1 in x 6 ft'],
        ['foam pipe wrap', 'pipe sleeve'],
      ),
    ),
  ]),
]);
