import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_item_memory_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_privacy_event_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_health_event.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_hosted_import_validator.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_hosted_manifest.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_schema.dart';

void main() {
  test(
    'builds hosted catalog pack and manifest documents without item docs',
    () {
      final manifest = buildWorkSupplyHostedCatalogManifest(
        generatedAt: DateTime.utc(2026, 6, 23, 12),
      );

      final pack = MaintainiacFirestoreDocumentBuilder.catalogPackDocument(
        manifest,
      );
      final manifestDoc =
          MaintainiacFirestoreDocumentBuilder.catalogManifestDocument(manifest);

      expect(
        pack.path,
        MaintainiacFirestoreSchema.catalogPackDocumentPath(manifest.packId),
      );
      expect(
        manifestDoc.path,
        MaintainiacFirestoreSchema.catalogPackManifestDocumentPath(
          manifest.packId,
          manifest.packVersion,
        ),
      );
      expect(pack.data['firestoreItemDocumentReadCount'], 0);
      expect(pack.data['deliveryMode'], 'manifest_storage_chunks');
      expect(manifestDoc.data['deliveryMode'], 'manifest_storage_chunks');
      expect(manifestDoc.data['chunks'], isA<List>());

      final encodedPack = pack.data.toString().toLowerCase();
      expect(encodedPack, isNot(contains('copper')));
      expect(encodedPack, isNot(contains('pvc')));
      expect(encodedPack, isNot(contains('aliases')));
    },
  );

  test('builds privacy-safe catalog health document', () {
    final manifest = buildWorkSupplyHostedCatalogManifest(
      generatedAt: DateTime.utc(2026, 6, 23, 12),
    );
    final validation = WorkSupplyHostedCatalogValidationResult(
      status: WorkSupplyHostedCatalogValidationStatus.ready,
      manifest: manifest,
      issues: const [],
      checkedChunkCount: manifest.chunkCount,
      checkedItemCount: manifest.itemCount,
    );
    final event = WorkSupplyCatalogHealthEvent.fromValidation(validation);
    final doc = MaintainiacFirestoreDocumentBuilder.catalogHealthDocument(
      event,
      generatedAtUtc: DateTime.utc(2026, 6, 23, 13),
    );

    expect(
      doc.path,
      startsWith('${MaintainiacFirestoreSchema.catalogHealth}/'),
    );
    expect(doc.data['schema'], 'catalog_health_event_v1');
    expect(doc.data['event'], 'catalogpackready');
    expect(doc.data['featureArea'], 'inventory_catalog');
    expect(doc.data['firestoreItemDocumentReadCount'], 0);

    final encoded = doc.data.toString().toLowerCase();
    expect(encoded, isNot(contains('items:')));
    expect(encoded, isNot(contains('aliases')));
    expect(encoded, isNot(contains('copper')));
  });

  test('builds receipt diagnostic and parser health documents safely', () {
    final parsed = parseExpenseReceiptText('''
PRIVATE SUPPLY STORE
06/12/2026
SECRET JOB MATERIAL 12.34
Subtotal 12.34
Tax 1.00
Total 13.34
''');
    final record = PrivacySafeReceiptEventRecord(
      id: 'evt_123',
      queuedAtUtc: DateTime.utc(2026, 6, 23, 14),
      payload: ReceiptPrivacyEventPolicy.sanitize(
        PrivacySafeReceiptEvent.fromParseResult(
          result: parsed,
          featureArea: 'materials inventory',
        ),
      ),
    );
    final diagnostic =
        MaintainiacFirestoreDocumentBuilder.receiptDiagnosticDocument(
          orgId: 'ORG-1',
          record: record,
        );
    final health = ReceiptPrivacyEventHealthSnapshot.fromRecords([record]);
    final parserHealth =
        MaintainiacFirestoreDocumentBuilder.parserHealthDocument(health);

    expect(
      diagnostic.path,
      'orgs/ORG-1/${MaintainiacFirestoreSchema.orgReceiptDiagnostics}/evt_123',
    );
    expect(diagnostic.data['schema'], 'receipt_diagnostic_event_v1');
    expect(parserHealth.path, 'parserHealth/receipt_parser_v1');
    expect(parserHealth.data['schema'], 'parser_health_snapshot_v1');
    expect(parserHealth.data['healthLabel'], isNot('no_data'));

    final encoded = {
      ...diagnostic.data,
      ...parserHealth.data,
    }.toString().toLowerCase();
    expect(encoded, isNot(contains('private supply')));
    expect(encoded, isNot(contains('secret job')));
    expect(encoded, isNot(contains('12.34')));
    expect(encoded, isNot(contains('13.34')));
  });

  test('builds expense telemetry summary without raw event upload', () {
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
      ExpenseTelemetryRecord(
        id: 'evt_1',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
        payload: ExpenseTelemetryPolicy.sanitize(
          const ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.addExpenseStarted,
          ),
        ),
      ),
      ExpenseTelemetryRecord(
        id: 'evt_2',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 1),
        payload: ExpenseTelemetryPolicy.sanitize(
          const ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.ocrFailed,
            failureKind: 'no_readable_text',
            diagnostic: ExpenseFailureDiagnostic(
              workflowStep: ExpenseWorkflowStep.receiptOcr,
              failedAt: 'after_attachment_read_before_parser',
              confirmedCause: 'no_readable_text',
              causeStatus: ExpenseFailureCauseStatus.confirmed,
              evidence: 'ocr_zero_lines',
              missingEvidence: 'none',
              abandoned: true,
            ),
          ),
        ),
      ),
    ], generatedAtUtc: DateTime.utc(2026, 6, 24, 13));

    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
        );

    expect(
      doc.path,
      'orgs/ORG-1/${MaintainiacFirestoreSchema.orgExpenseTelemetrySummaries}/latest',
    );
    expect(doc.data['schema'], 'expense_telemetry_summary_v1');
    expect(doc.data['summaryScope'], 'expense_screen');
    expect(doc.data['uploadShape'], 'single_summary_document');
    expect(doc.data['rawEventUploadCount'], 0);
    expect(doc.data['ocrFailedCount'], 1);
    expect(doc.data['failureBreakdowns'], isA<List>());
    expect(
      (doc.data['failureBreakdowns'] as List).single.toString(),
      contains('no_readable_text'),
    );
    expect(
      (doc.data['failureBreakdowns'] as List).single.toString(),
      contains('No readable text'),
    );
    expect(doc.data['recentFailureDetails'], isA<List>());
    expect(
      (doc.data['recentFailureDetails'] as List).single.toString(),
      contains('Confirmed cause'),
    );
    expect(
      (doc.data['failureBreakdowns'] as List).single.toString(),
      contains('platformCounts'),
    );
    expect(
      (doc.data['failureBreakdowns'] as List).single.toString(),
      contains('deviceTierCounts'),
    );

    final encoded = doc.data.toString().toLowerCase();
    expect(encoded, isNot(contains('receipttext')));
    expect(encoded, isNot(contains('customer')));
    expect(encoded, isNot(contains('store name')));
  });

  test('builds shared correction candidate with hashes, not receipt text', () {
    final memory = ExpenseReceiptItemMemory(
      id: 'local',
      merchantName: 'Private Hardware On Main Street',
      description: '1/2 COPPER ELBOW PRIVATE JOB 4.99',
      normalizedDescription: '1 2 copper elbow private job 4 99',
      rawReceiptText: '1/2 COPPER ELBOW PRIVATE JOB 4.99',
      correctedDescription: 'Copper elbow',
      category: 'Plumbing fittings',
      useName: ExpenseLineUse.business.name,
      unit: 'each',
      quantity: 1,
      unitsPerPackage: 1,
      subtotal: 4.99,
      unitPrice: 4.99,
      catalogItemId: 'plumbing:fittings:copper_elbow',
      catalogItemName: 'Copper elbow',
      catalogItemPath: 'Plumbing / Fittings / Copper',
      catalogMatchConfidence: .92,
      catalogMatchedTerms: const ['copper elbow'],
      parserConfidence: .88,
      parserReviewLabel: 'Good',
      parserReviewReason: 'catalog match',
      reviewAction: 'edited',
      seenCount: 4,
      firstSeenAt: DateTime.utc(2026, 6, 1),
      lastSeenAt: DateTime.utc(2026, 6, 20),
    );

    final doc =
        MaintainiacFirestoreDocumentBuilder.sharedCorrectionCandidateDocument(
          memory,
          submittedAtUtc: DateTime.utc(2026, 6, 23),
        );

    expect(
      doc.path,
      startsWith('${MaintainiacFirestoreSchema.sharedCorrectionCandidates}/'),
    );
    expect(doc.data['schema'], 'shared_correction_candidate_v1');
    expect(doc.data['merchantHash'], isA<String>());
    expect(doc.data['normalizedDescriptionHash'], isA<String>());
    expect(doc.data['rawReceiptTextHash'], isA<String>());
    expect(doc.data['catalogItemId'], 'plumbing:fittings:copper_elbow');
    expect(doc.data['seenCountBucket'], '4_9');
    expect(doc.data['firstSeenAgeBucket'], 'month');

    final encoded = doc.data.toString().toLowerCase();
    expect(encoded, isNot(contains('private hardware')));
    expect(encoded, isNot(contains('private job')));
    expect(encoded, isNot(contains('4.99')));
    expect(encoded, isNot(contains('copper elbow')));
    expect(encoded, isNot(contains('plumbing / fittings')));
  });
}
