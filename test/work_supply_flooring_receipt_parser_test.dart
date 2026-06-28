import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('flooring generated pack covers receipt-realistic stock', () {
    final flooringItems = workSupplyCatalogItems
        .where((item) => item.trade == 'Flooring')
        .toList(growable: false);
    final fullPack = buildWorkSupplyTradePackOptions(
      'Flooring',
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.full);

    expect(flooringItems.length, greaterThanOrEqualTo(1000));
    expect(fullPack.itemCount, flooringItems.length);
    expect(
      flooringItems.any(
        (item) =>
            item.name ==
            'Gray Oak 6 mm Waterproof Rigid Core LVP Plank Luxury Vinyl Flooring',
      ),
      isTrue,
    );
    expect(
      flooringItems.any(
        (item) => item.name == 'Oak 94 in Stair Nose Floor Transition Trim',
      ),
      isTrue,
    );
  });

  test('flooring parser understands vinyl laminate and wood flooring', () {
    final lvp = matchReceiptLineToCatalog(
      'GRAY OAK 6MM RIGID CORE LVP PLANK',
      tradeScope: 'Flooring',
      maxCandidates: 180,
    );
    expect(lvp, isNotNull);
    expect(lvp!.item.trade, 'Flooring');
    expect(lvp.item.name, contains('Gray Oak'));
    expect(lvp.item.name, contains('6 mm'));
    expect(lvp.item.name, contains('Rigid Core LVP'));
    expect(lvp.confidenceLevel, ReceiptConfidenceLevel.good);

    final laminate = matchReceiptLineToCatalog(
      'HICKORY 10MM AC4 LAMINATE PLANK',
      tradeScope: 'Flooring',
      maxCandidates: 180,
    );
    expect(laminate, isNotNull);
    expect(laminate!.item.trade, 'Flooring');
    expect(laminate.item.name, contains('Hickory'));
    expect(laminate.item.name, contains('10 mm AC4 Laminate Plank'));

    final hardwood = matchReceiptLineToCatalog(
      'NATURAL 5IN RED OAK SOLID HARDWOOD PLANK',
      tradeScope: 'Flooring',
      maxCandidates: 180,
    );
    expect(hardwood, isNotNull);
    expect(hardwood!.item.trade, 'Flooring');
    expect(hardwood.item.name, contains('Red Oak'));
    expect(hardwood.item.name, contains('Solid Hardwood Plank'));
  });

  test('flooring parser understands carpet underlayment and floor prep', () {
    final carpet = matchReceiptLineToCatalog(
      'BEIGE 12FT BERBER CARPET ROLL',
      tradeScope: 'Flooring',
      maxCandidates: 180,
    );
    expect(carpet, isNotNull);
    expect(carpet!.item.trade, 'Flooring');
    expect(carpet.item.name, contains('Berber Carpet Roll'));

    final barrier = matchReceiptLineToCatalog(
      '200 SQ FT MOISTURE BARRIER FILM',
      tradeScope: 'Flooring',
      maxCandidates: 180,
    );
    expect(barrier, isNotNull);
    expect(barrier!.item.trade, 'Flooring');
    expect(barrier.item.name, contains('200 sq ft Moisture Barrier Film'));

    final leveler = matchReceiptLineToCatalog(
      '50LB SELF LEVELING UNDERLAYMENT',
      tradeScope: 'Flooring',
      maxCandidates: 180,
    );
    expect(leveler, isNotNull);
    expect(leveler!.item.trade, 'Flooring');
    expect(leveler.item.name, contains('50 lb Self Leveling Underlayment'));
  });

  test(
    'flooring parser understands transitions adhesives and install supplies',
    () {
      final stairNose = matchReceiptLineToCatalog(
        'OAK 94IN STAIR NOSE',
        tradeScope: 'Flooring',
        maxCandidates: 180,
      );
      expect(stairNose, isNotNull);
      expect(stairNose!.item.trade, 'Flooring');
      expect(stairNose.item.name, contains('Oak 94 in Stair Nose'));

      final adhesive = matchReceiptLineToCatalog(
        '4 GAL PRESSURE SENSITIVE FLOOR ADHESIVE',
        tradeScope: 'Flooring',
        maxCandidates: 180,
      );
      expect(adhesive, isNotNull);
      expect(adhesive!.item.trade, 'Flooring');
      expect(adhesive.item.name, contains('Pressure Sensitive Adhesive'));

      final cleats = matchReceiptLineToCatalog(
        'HARDWOOD FLOOR CLEAT 1000PK',
        tradeScope: 'Flooring',
        maxCandidates: 180,
      );
      expect(cleats, isNotNull);
      expect(cleats!.item.trade, 'Flooring');
      expect(cleats.item.name, contains('Hardwood Floor Cleat 1000 Pack'));
    },
  );
}
