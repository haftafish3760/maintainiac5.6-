import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_privacy_event_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'receipt_privacy_event_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('queues only privacy-safe parser event payloads', () async {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
PRIVATE CUSTOMER PART 42.88
WIRE NUTS 4.98
Total 47.86
''');
    final store = await PrivacySafeReceiptEventStore.create();

    final record = await store.enqueue(
      PrivacySafeReceiptEvent.fromParseResult(
        result: parsed,
        featureArea: 'materials inventory',
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 23, 14, 30),
    );

    expect(record.payload['featureArea'], 'materials_inventory');
    expect(
      record.payload['parserReviewCause'],
      'inventory_catalog_match_weak',
    );
    expect(record.payload['fieldReviewKeys'], contains('lineitems'));
    expect(store.records, hasLength(1));
    expect(store.pendingUploadPayloads(), hasLength(1));

    final encoded = store.pendingUploadPayloads().toString().toLowerCase();
    expect(encoded, contains('eventid'));
    expect(encoded, contains('queuedatutc'));
    expect(encoded, isNot(contains('lowe')));
    expect(encoded, isNot(contains('private customer')));
    expect(encoded, isNot(contains('wire nuts')));
    expect(encoded, isNot(contains('42.88')));
    expect(encoded, isNot(contains('47.86')));
  });

  test('rejects unsafe diagnostic strings before storage', () {
    expect(
      () => ReceiptPrivacyEventPolicy.sanitizeMap({
        'event': PrivacySafeReceiptEventType.receiptParserReview.name,
        'featureArea': 'expenses',
        'parseQuality': 'PRIVATE STORE 99.99',
      }),
      throwsArgumentError,
    );
    expect(
      () => ReceiptPrivacyEventPolicy.sanitizeMap({
        'event': PrivacySafeReceiptEventType.receiptParserReview.name,
        'featureArea': 'expenses',
        'detectedLineCount': -1,
      }),
      throwsArgumentError,
    );
  });

  test('marks uploaded events and clears only uploaded records', () async {
    final store = await PrivacySafeReceiptEventStore.create();
    final first = await store.enqueue(
      const PrivacySafeReceiptEvent(
        type: PrivacySafeReceiptEventType.receiptParserGood,
        featureArea: 'expenses',
        detectedLineCount: 2,
        reconciled: true,
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 23, 14),
    );
    await store.enqueue(
      const PrivacySafeReceiptEvent(
        type: PrivacySafeReceiptEventType.receiptOcrReview,
        featureArea: 'materials',
        ocrSeverity: 'review',
        attachmentsRead: 1,
        rawLineCount: 8,
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 23, 15),
    );

    await store.markUploaded([first.id], nowUtc: DateTime.utc(2026, 6, 23, 16));

    expect(store.records, hasLength(2));
    expect(
      store.pendingUploadRecords.map((record) => record.id),
      isNot(contains(first.id)),
    );

    await store.clearUploaded();

    expect(store.records, hasLength(1));
    expect(store.records.single.uploadedAtUtc, isNull);
  });

  test(
    'builds command center health snapshot without raw event details',
    () async {
      final parsed = parseExpenseReceiptText('''
PRIVATE SUPPLY HOUSE
06/12/2026
SECRET JOB MATERIAL 12.34
Total 99.99
''');
      final store = await PrivacySafeReceiptEventStore.create();
      await store.enqueue(
        const PrivacySafeReceiptEvent(
          type: PrivacySafeReceiptEventType.receiptOcrReview,
          featureArea: 'expenses',
          capabilityTier: 'light',
          parserDepth: 'lineItems',
          ocrSeverity: 'review',
          warningKinds: ['duplicateText', 'pdfPageLimit'],
          attachmentsRead: 2,
          rawLineCount: 10,
          parserLineCount: 8,
          pdfPagesRequested: 2,
          hadDuplicateOrOverlapText: true,
        ),
        queuedAtUtc: DateTime.utc(2026, 6, 23, 14),
      );
      final parseRecord = await store.enqueue(
        PrivacySafeReceiptEvent.fromParseResult(
          result: parsed,
          featureArea: 'materials_inventory',
        ),
        queuedAtUtc: DateTime.utc(2026, 6, 23, 15),
      );
      await store.markUploaded([
        parseRecord.id,
      ], nowUtc: DateTime.utc(2026, 6, 23, 16));

      final snapshot = store.buildHealthSnapshot(
        nowUtc: DateTime.utc(2026, 6, 23, 17),
      );
      final map = snapshot.toCommandCenterMap();

      expect(map['schema'], 'receipt_privacy_health_v1');
      expect(map['totalEventCount'], 2);
      expect(map['pendingUploadCount'], 1);
      expect(map['uploadedEventCount'], 1);
      expect(map['healthLabel'], isNot('healthy'));
      expect(snapshot.needsAttention, isTrue);
      expect(snapshot.duplicateOrOverlapCount, 1);
      expect(snapshot.pdfPagesRequested, 2);
      expect(snapshot.heavyReviewCount, 1);
      expect(snapshot.taxMathMismatchCount, 0);
      expect(
        snapshot.eventCounts[PrivacySafeReceiptEventType.receiptOcrReview.name],
        1,
      );
      expect(snapshot.featureAreaCounts['materials_inventory'], 1);
      expect(snapshot.warningKindCounts['duplicateText'], 1);
      expect(snapshot.parserTrustCounts, isNotEmpty);
      expect(snapshot.totalsMathStatusCounts, isNotEmpty);
      expect(snapshot.parserReviewCauseCounts, isNotEmpty);
      expect(snapshot.fieldReviewKeyCounts, isNotEmpty);
      expect(snapshot.ocrAttemptCount, 1);
      expect(snapshot.ocrReadableRate, 1);
      expect(snapshot.ocrFailRate, 0);
      expect(snapshot.parserAttemptCount, 1);
      expect(snapshot.parserSuccessRate, 0);
      expect(snapshot.parserProblemRate, 1);
      expect(map['heavyReviewCount'], 1);
      expect(map['taxMathMismatchCount'], 0);
      expect(map['ocrReadableRate'], 1);
      expect(map['parserProblemRate'], 1);
      expect(map['parserReviewCauseCounts'], isNotEmpty);
      expect(map['fieldReviewKeyCounts'], isNotEmpty);

      final encoded = map.toString().toLowerCase();
      expect(encoded, isNot(contains(parseRecord.id.toLowerCase())));
      expect(encoded, isNot(contains('private supply')));
      expect(encoded, isNot(contains('secret job')));
      expect(encoded, isNot(contains('12.34')));
      expect(encoded, isNot(contains('99.99')));
    },
  );

  test('health snapshot counts tax math mismatches without amounts', () async {
    final parsed = parseExpenseReceiptText('''
PRIVATE SUPPLY HOUSE
06/12/2026
SECRET JOB MATERIAL 10.00
Subtotal 10.00
Tax 0.80
Total 12.80
''');
    final store = await PrivacySafeReceiptEventStore.create();
    await store.enqueue(
      PrivacySafeReceiptEvent.fromParseResult(
        result: parsed,
        featureArea: 'materials_inventory',
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 23, 15),
    );

    final snapshot = store.buildHealthSnapshot(
      nowUtc: DateTime.utc(2026, 6, 23, 17),
    );
    final map = snapshot.toCommandCenterMap();
    final encoded = map.toString().toLowerCase();

    expect(snapshot.taxMathMismatchCount, 1);
    expect(snapshot.heavyReviewCount, 1);
    expect(snapshot.healthLabel, 'needs_attention');
    expect(snapshot.parserTrustCounts['needs_receipt_math_review'], 1);
    expect(snapshot.totalsMathStatusCounts['mismatch'], 1);
    expect(
      snapshot.parserReviewCauseCounts['receipt_subtotal_tax_total_mismatch'],
      1,
    );
    expect(snapshot.fieldReviewKeyCounts['receiptmath'], 1);
    expect(encoded, isNot(contains('private supply')));
    expect(encoded, isNot(contains('secret job')));
    expect(encoded, isNot(contains('12.80')));
    expect(encoded, isNot(contains('10.00')));
    expect(encoded, isNot(contains('0.80')));
  });

  test(
    'health snapshot summarizes capture diagnostics without photos',
    () async {
      final store = await PrivacySafeReceiptEventStore.create();
      await store.enqueue(
        const PrivacySafeReceiptEvent(
          type: PrivacySafeReceiptEventType.receiptCaptureCompleted,
          featureArea: 'expenses',
          capabilityTier: 'medium',
          captureMode: 'assisted_auto',
          captureOutcome: 'completed',
          focusBucket: 'sharp',
          readabilityBucket: 'high',
          photoSectionCount: 2,
          retakeCount: 1,
          captureDurationMs: 3200,
        ),
        queuedAtUtc: DateTime.utc(2026, 6, 23, 13),
      );
      await store.enqueue(
        const PrivacySafeReceiptEvent(
          type: PrivacySafeReceiptEventType.receiptCaptureFailed,
          featureArea: 'expenses',
          capabilityTier: 'light',
          captureMode: 'manual',
          captureOutcome: 'failed',
          focusBucket: 'soft',
          readabilityBucket: 'poor',
          errorKind: 'camera_error',
        ),
        queuedAtUtc: DateTime.utc(2026, 6, 23, 14),
      );

      final snapshot = store.buildHealthSnapshot(
        nowUtc: DateTime.utc(2026, 6, 23, 17),
      );
      final map = snapshot.toCommandCenterMap();
      final encoded = map.toString().toLowerCase();

      expect(snapshot.captureCompletedCount, 1);
      expect(snapshot.captureFailedCount, 1);
      expect(snapshot.captureSuccessRate, .5);
      expect(snapshot.averageCaptureDurationMs, 3200);
      expect(snapshot.photoSectionCount, 2);
      expect(snapshot.retakeCount, 1);
      expect(snapshot.captureModeCounts['assisted_auto'], 1);
      expect(snapshot.captureOutcomeCounts['failed'], 1);
      expect(snapshot.focusBucketCounts['soft'], 1);
      expect(snapshot.readabilityBucketCounts['high'], 1);
      expect(snapshot.errorKindCounts['camera_error'], 1);
      expect(map['captureSuccessRate'], .5);
      expect(map['captureFailedCount'], 1);
      expect(encoded, isNot(contains('/tmp')));
      expect(encoded, isNot(contains('.jpg')));
      expect(encoded, isNot(contains('receipt text')));
    },
  );

  test('empty command center health snapshot is explicit no-data', () async {
    final store = await PrivacySafeReceiptEventStore.create();
    final snapshot = store.buildHealthSnapshot(
      nowUtc: DateTime.utc(2026, 6, 23, 17),
    );

    expect(snapshot.hasEvents, isFalse);
    expect(snapshot.needsAttention, isFalse);
    expect(snapshot.healthLabel, 'no_data');
    expect(snapshot.toCommandCenterMap()['totalEventCount'], 0);
  });
}
