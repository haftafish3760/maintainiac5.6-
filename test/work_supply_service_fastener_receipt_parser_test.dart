import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test(
    'plumbing parser understands threaded rod and concrete screw wording',
    () {
      final allThread = matchReceiptLineToCatalog(
        'FERG 3/8 ALL THREAD ROD 36 IN',
        tradeScope: 'Plumbing',
        maxCandidates: 280,
      );
      expect(allThread, isNotNull);
      expect(allThread!.item.trade, 'Plumbing');
      expect(allThread.item.name.toLowerCase(), contains('threaded rod'));
      expect(allThread.confidenceLevel, ReceiptConfidenceLevel.good);

      final tapcon = matchReceiptLineToCatalog(
        'LOWES 1/4 X 2-1/4 TAPCON MASONRY SCREW',
        tradeScope: 'Plumbing',
        maxCandidates: 280,
      );
      expect(tapcon, isNotNull);
      expect(tapcon!.item.trade, 'Plumbing');
      expect(tapcon.item.name.toLowerCase(), contains('concrete screw'));
      expect(tapcon.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test('hvac parser understands sheet metal screw receipt shorthand', () {
    final zipScrew = matchReceiptLineToCatalog(
      'HD #8 X 1/2 ZIP SCREW SHEET METAL 100PK',
      tradeScope: 'HVAC',
      maxCandidates: 280,
    );
    expect(zipScrew, isNotNull);
    expect(zipScrew!.item.trade, 'HVAC');
    expect(zipScrew.item.name.toLowerCase(), contains('screw'));
    expect(zipScrew.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('electrical and garage fasteners use trade scope without stealing', () {
    final electricalAnchor = matchReceiptLineToCatalog(
      'ACE 1/4 MASONRY SCREW WALL ANCHOR 25PK',
      tradeScope: 'Electrical',
      maxCandidates: 280,
    );
    expect(electricalAnchor, isNotNull);
    expect(electricalAnchor!.item.trade, 'Electrical');

    final garageBolt = matchReceiptLineToCatalog(
      'MENARDS GARAGE TRACK BOLT FLANGE NUT PACK',
      tradeScope: 'Garage Doors and Openers',
      maxCandidates: 280,
    );
    expect(garageBolt, isNotNull);
    expect(garageBolt!.item.trade, 'Garage Doors and Openers');
    expect(garageBolt.item.name.toLowerCase(), contains('track bolt'));
  });
}
