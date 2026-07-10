import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('es-US fastener overlay respects trade-scoped screw families', () {
    final hvacZipScrew = matchReceiptLineToCatalog(
      'HD #8 X 1/2 TORNILLO LAMINA 100PK',
      localePackId: 'es-US',
      tradeScope: 'HVAC',
      maxCandidates: 320,
    );
    expect(hvacZipScrew, isNotNull);
    expect(hvacZipScrew!.item.trade, 'HVAC');
    expect(hvacZipScrew.item.name.toLowerCase(), contains('screw'));
    expect(hvacZipScrew.confidenceLevel, ReceiptConfidenceLevel.good);

    final drywallScrew = matchReceiptLineToCatalog(
      'LOWES TORNILLO TABLAROCA #6 X 1-5/8 COARSE',
      localePackId: 'es-US',
      tradeScope: 'Drywall',
      maxCandidates: 320,
    );
    expect(drywallScrew, isNotNull);
    expect(drywallScrew!.item.trade, 'Drywall');
    expect(drywallScrew.item.name.toLowerCase(), contains('screw'));
    expect(drywallScrew.confidenceLevel, ReceiptConfidenceLevel.good);

    final deckScrew = matchReceiptLineToCatalog(
      'ACE 2-1/2 TORNILLO DECK EXTERIOR',
      localePackId: 'es-US',
      tradeScope: 'Carpentry',
      maxCandidates: 320,
    );
    expect(deckScrew, isNotNull);
    expect(deckScrew!.item.trade, 'Carpentry');
    expect(deckScrew.item.name.toLowerCase(), contains('deck screw'));
    expect(deckScrew.confidenceLevel, ReceiptConfidenceLevel.good);
  });
}
