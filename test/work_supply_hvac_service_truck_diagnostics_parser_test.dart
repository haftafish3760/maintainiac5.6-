import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test(
    'hvac diagnostics parser understands gauges recovery and vacuum stock',
    () {
      final manifold = matchReceiptLineToCatalog(
        'DIGITAL MANIFOLD GAUGE SET',
        tradeScope: 'HVAC',
        maxCandidates: 120,
      );
      expect(manifold, isNotNull);
      expect(manifold!.item.trade, 'HVAC');
      expect(manifold.item.name, contains('Digital Manifold Gauge Set'));

      final scale = matchReceiptLineToCatalog(
        'REFRIGERANT CHARGING SCALE 220LB',
        tradeScope: 'HVAC',
        maxCandidates: 120,
      );
      expect(scale, isNotNull);
      expect(scale!.item.trade, 'HVAC');
      expect(scale.item.name, contains('Refrigerant Charging Scale'));

      final coreTool = matchReceiptLineToCatalog(
        'CORE REMOVAL TOOL 5/16IN',
        tradeScope: 'HVAC',
        maxCandidates: 120,
      );
      expect(coreTool, isNotNull);
      expect(coreTool!.item.trade, 'HVAC');
      expect(coreTool.item.name, contains('Core Removal Tool 5/16'));
    },
  );

  test('hvac diagnostics parser understands meters and probes', () {
    final manometer = matchReceiptLineToCatalog(
      'DUAL PORT MANOMETER',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(manometer, isNotNull);
    expect(manometer!.item.trade, 'HVAC');
    expect(manometer.item.name, contains('Dual Port Manometer'));

    final clamp = matchReceiptLineToCatalog(
      'TEMP CLAMP PROBE PAIR',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(clamp, isNotNull);
    expect(clamp!.item.trade, 'HVAC');
    expect(clamp.item.name, contains('Temperature Clamp Probe Pair'));
  });

  test('hvac diagnostics parser understands leak detection stock', () {
    final detector = matchReceiptLineToCatalog(
      'ELECTRONIC REFRIGERANT LEAK DETECTOR',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(detector, isNotNull);
    expect(detector!.item.trade, 'HVAC');
    expect(
      detector.item.name,
      contains('Electronic Refrigerant Leak Detector'),
    );

    final dye = matchReceiptLineToCatalog(
      'UV LEAK DYE CARTRIDGE',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(dye, isNotNull);
    expect(dye!.item.trade, 'HVAC');
    expect(dye.item.name, contains('UV Leak Detection Dye Cartridge'));
  });

  test('hvac diagnostics parser understands coil and drain cleaning stock', () {
    final coil = matchReceiptLineToCatalog(
      '32OZ FOAMING EVAP COIL CLEANER',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(coil, isNotNull);
    expect(coil!.item.trade, 'HVAC');
    expect(coil.item.name, contains('Foaming Evaporator Coil Cleaner'));

    final pan = matchReceiptLineToCatalog(
      'CONDENSATE PAN TABLET BOTTLE',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(pan, isNotNull);
    expect(pan!.item.trade, 'HVAC');
    expect(pan.item.name, contains('Condensate Pan Tablet Bottle'));
  });
}
