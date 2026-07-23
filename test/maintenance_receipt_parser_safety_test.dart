import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';

void main() {
  test('unrelated receipt returns no maintenance evidence', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
CORNER MARKET
07/22/2026
MILK 4.99
BREAD 3.49
TOTAL 8.48
''',
      ),
    );

    expect(result.kind, MaintenanceReceiptKind.unknown);
    expect(result.candidates, isEmpty);
    expect(
      result.reviewStatus,
      MaintenanceReceiptReviewStatus.noMaintenanceEvidence,
    );
  });

  test('invalid metadata date does not hide a later valid receipt date', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
NAPA AUTO PARTS
SYSTEM DATE 99/99/9999
RECEIPT DATE 07/23/2026
OIL FILTER 12.99
TOTAL 12.99
''',
      ),
    );

    expect(result.receiptDate, DateTime(2026, 7, 23));
  });

  test('ambiguous US date is locale-interpreted and requires review', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        locale: 'en-US',
        sourceText:
            'SERVICE PERFORMED\n03/04/2026\nODOMETER 40000\nOIL CHANGE 49.99',
      ),
    );

    expect(result.receiptDate, DateTime(2026, 3, 4));
    expect(
      result.warnings,
      contains(
        'Ambiguous numeric receipt date was interpreted using en-US; confirm the date.',
      ),
    );
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('ambiguous day-first date follows supported locale', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        locale: 'en-GB',
        sourceText:
            'SERVICE PERFORMED\n03/04/2026\nODOMETER 40000\nOIL CHANGE 49.99',
      ),
    );

    expect(result.receiptDate, DateTime(2026, 4, 3));
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('ambiguous unsupported locale does not guess the service date', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        locale: 'fr-FR',
        sourceText:
            'SERVICE PERFORMED\n03/04/2026\nODOMETER 40000\nOIL CHANGE 49.99',
      ),
    );

    expect(result.receiptDate, isNull);
    expect(
      result.warnings,
      contains(
        'The receipt date locale is unsupported; enter the service date manually.',
      ),
    );
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('named month service date is parsed without numeric ambiguity', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText:
            'JIFFY LUBE\nJUL 23, 2026\nODOMETER 40000\nSERVICE PERFORMED\nOIL CHANGE 49.99',
      ),
    );

    expect(result.receiptDate, DateTime(2026, 7, 23));
    expect(
      result.warnings,
      isNot(contains(contains('Ambiguous numeric receipt date'))),
    );
  });

  test('service odometer prefers mileage out and accepts commas', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
SERVICE PERFORMED
07/23/2026
MILEAGE IN 100,000
MILEAGE OUT 100,010
OIL CHANGE 49.99
''',
      ),
    );

    expect(result.candidates.single.serviceOdometer, 100010);
  });

  test('evidence redacts VIN-like identifiers', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
SERVICE PERFORMED
VIN 1HGCM82633A004352
ENGINE OIL CHANGE 5W-20 49.99
''',
      ),
    );

    final evidence = result.candidates
        .expand((candidate) => candidate.evidence)
        .map((item) => item.safeSnippet)
        .join(' ');
    expect(evidence, isNot(contains('1HGCM82633A004352')));
  });

  test('evidence redacts formatted contact, payment, and address data', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
SERVICE PERFORMED
OIL CHANGE 5W-30 PHONE 555-123-4567
OIL FILTER CARD 4111 1111 1111 1111
ENGINE OIL DELIVERY 123 MAIN STREET
''',
      ),
    );

    final evidence = result.candidates
        .expand((candidate) => candidate.evidence)
        .map((item) => item.safeSnippet)
        .join(' ');
    expect(evidence, contains('[PHONE REDACTED]'));
    expect(evidence, contains('[PAYMENT NUMBER REDACTED]'));
    expect(evidence, contains('[ADDRESS REDACTED]'));
    expect(evidence, isNot(contains('555-123-4567')));
    expect(evidence, isNot(contains('4111 1111 1111 1111')));
    expect(evidence, isNot(contains('123 MAIN STREET')));
  });

  test('declined recommendation never becomes completed service', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 991
ENGINE OIL CHANGE RECOMMENDED - CUSTOMER DECLINED
TOTAL 0.00
''',
      ),
    );

    final oil = result.candidates.single;
    expect(oil.action, MaintenanceReceiptAction.manualReview);
    expect(oil.completedServiceIndicated, isFalse);
    expect(oil.notCompletedIndicated, isTrue);
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('estimate without completion proof never becomes service history', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
PEP BOYS SERVICE ESTIMATE
07/23/2026
OIL CHANGE 79.99
FRONT BRAKE PADS 249.99
ESTIMATED TOTAL 329.98
''',
      ),
    );

    expect(result.merchantName, 'Pep Boys');
    expect(
      result.candidates,
      everyElement(
        isA<MaintenanceReceiptCandidate>()
            .having(
              (candidate) => candidate.completedServiceIndicated,
              'completed',
              isFalse,
            )
            .having(
              (candidate) => candidate.action,
              'action',
              MaintenanceReceiptAction.manualReview,
            ),
      ),
    );
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test(
    'returned part requires manual review and is not a purchase suggestion',
    () {
      final result = parseMaintenanceReceipt(
        const MaintenanceReceiptParserInput(
          activeVehicleId: 'vehicle_1',
          sourceText: '''
AUTOZONE
07/23/2026
RETURN FRONT BRAKE PADS -49.99
REFUND TO CARD 49.99
''',
        ),
      );

      final brakes = result.candidates.single;
      expect(brakes.returnOrExchangeIndicated, isTrue);
      expect(brakes.productPurchased, isFalse);
      expect(brakes.completedServiceIndicated, isFalse);
      expect(brakes.action, MaintenanceReceiptAction.manualReview);
      expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
    },
  );

  test('separate declined heading scopes only the following service', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 991
SERVICE PERFORMED
ENGINE OIL CHANGE 49.99
DECLINED SERVICES
FRONT BRAKE PADS 249.99
''',
      ),
    );

    final candidates = {
      for (final candidate in result.candidates) candidate.itemName: candidate,
    };
    expect(candidates.keys, {'Engine Oil', 'Brake Pads'});
    expect(
      candidates['Engine Oil']!.action,
      MaintenanceReceiptAction.reviewCompletedService,
    );
    expect(candidates['Engine Oil']!.completedServiceIndicated, isTrue);
    expect(candidates['Engine Oil']!.notCompletedIndicated, isFalse);
    expect(
      candidates['Brake Pads']!.action,
      MaintenanceReceiptAction.manualReview,
    );
    expect(candidates['Brake Pads']!.completedServiceIndicated, isFalse);
    expect(candidates['Brake Pads']!.notCompletedIndicated, isTrue);
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('separate return heading cannot create purchase setup', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
AUTOZONE
07/23/2026
RETURN
OIL FILTER 12.99
REFUND TO CARD 12.99
''',
      ),
    );

    final filter = result.candidates.single;
    expect(filter.productPurchased, isFalse);
    expect(filter.returnOrExchangeIndicated, isTrue);
    expect(filter.action, MaintenanceReceiptAction.manualReview);
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test(
    'normalized source fingerprint is deterministic and content-sensitive',
    () {
      const base = MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: 'AUTOZONE\nOIL FILTER 12.99',
      );
      const spacing = MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '  autozone  \r\nOIL   FILTER   12.99  ',
      );
      const changed = MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: 'AUTOZONE\nOIL FILTER 13.99',
      );
      const damaged = MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: 'AUT0ZONE\n0IL FILTER 12.99',
      );

      final first = parseMaintenanceReceipt(base);
      expect(
        parseMaintenanceReceipt(spacing).sourceFingerprintSha256,
        first.sourceFingerprintSha256,
      );
      expect(
        parseMaintenanceReceipt(damaged).sourceFingerprintSha256,
        first.sourceFingerprintSha256,
      );
      expect(
        parseMaintenanceReceipt(changed).sourceFingerprintSha256,
        isNot(first.sourceFingerprintSha256),
      );
      expect(first.sourceFingerprintSha256, hasLength(64));
      expect(first.toJson()['schemaVersion'], 1);
    },
  );

  test('parts-store oil change kit is not mistaken for performed service', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
AUTOZONE
07/23/2026
FULL SYNTHETIC OIL CHANGE KIT 5W-30 39.99
OIL FILTER INCLUDED
TOTAL 39.99
''',
      ),
    );

    expect(result.kind, MaintenanceReceiptKind.mixed);
    expect(
      result.candidates,
      everyElement(
        isA<MaintenanceReceiptCandidate>().having(
          (candidate) => candidate.completedServiceIndicated,
          'completed',
          isFalse,
        ),
      ),
    );
    expect(
      result.candidates
          .singleWhere((candidate) => candidate.itemName == 'Engine Oil')
          .action,
      MaintenanceReceiptAction.reviewTrackingSetup,
    );
    expect(
      result.candidates
          .singleWhere((candidate) => candidate.itemName == 'Oil Filter')
          .action,
      isNot(MaintenanceReceiptAction.reviewCompletedService),
    );
  });

  test('comparison normalization preserves original evidence text', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText:
            'AUT0ZONE\n07/23/2026\nFULL SYNTHETIC 0IL 5W—30 34.99\nTOTAL 34.99',
      ),
    );

    expect(result.merchantName, 'AutoZone');
    final oil = result.candidates.single;
    expect(oil.itemName, 'Engine Oil');
    expect(oil.detailB, '5W-30');
    expect(oil.evidence.single.safeSnippet, contains('0IL'));
    expect(oil.evidence.single.safeSnippet, contains('5W—30'));
  });

  test('oversized receipt corpus is bounded and forced to manual review', () {
    final source = [
      'NAPA AUTO PARTS',
      '07/23/2026',
      'OIL FILTER 12.99',
      for (var index = 0; index < 5100; index++) 'NON-MAINTENANCE ITEM $index',
      'TOTAL 12.99',
    ].join('\n');

    final result = parseMaintenanceReceipt(
      MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: source,
      ),
    );

    expect(
      result.candidates.map((candidate) => candidate.itemName),
      contains('Oil Filter'),
    );
    expect(
      result.warnings,
      contains(
        'Receipt text exceeded local parser limits and was truncated; review the source manually.',
      ),
    );
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });
}
