import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry_recorder.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart';

import 'helpers/expense_screen_telemetry_harness.dart';

void main() {
  installExpenseTelemetryHiveLifecycle('expense_screen_telemetry_test_');

  test('queues privacy-safe expense screen events locally first', () async {
    final store = await ExpenseTelemetryStore.create();
    final context = expenseTelemetryContextFixture();

    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.screenOpened,
        context: context,
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
    );
    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.addExpenseStarted,
        context: context,
        metadata: const {'entryMode': 'receipt'},
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 1),
    );
    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.addExpenseCompleted,
        context: context,
        metadata: const {'saveDestination': 'local_first'},
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 2),
    );

    expect(store.records, hasLength(3));
    expect(store.pendingUploadRecords, hasLength(3));
    expect(store.pendingUploadPayloads(), hasLength(3));
    expect(
      store.pendingUploadPayloads().first['payload'],
      containsPair('platform', 'android'),
    );
  });

  test('allows content-free native capture failure metadata', () {
    final sanitized = ExpenseTelemetryPolicy.sanitize(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.imageAttachFailure,
        failureKind: 'native_camera_unavailable',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptAttachment,
          failedAt: 'native_camera_open',
          confirmedCause: 'native_camera_unavailable',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'open_backup_receipt_photo_option',
        ),
        metadata: const {
          'captureFlow': 'maintainiac_native_receipt_camera',
          'nativeCaptureFailureStage': 'native_camera_open',
          'nativeCaptureFailureReason': 'native_camera_unavailable',
          'nativeCaptureRecoveryAction': 'open_backup_receipt_photo_option',
          'nativeCameraEngine': 'cameraX',
          'nativeCameraAvailable': true,
          'nativeCameraPermissionGranted': true,
          'nativeCameraHasRearCamera': true,
        },
      ),
    );

    final metadata = sanitized['metadata'] as Map<String, Object?>;
    expect(metadata['captureFlow'], 'maintainiac_native_receipt_camera');
    expect(metadata['nativeCaptureFailureStage'], 'native_camera_open');
    expect(metadata['nativeCaptureFailureReason'], 'native_camera_unavailable');
    expect(
      metadata['nativeCaptureRecoveryAction'],
      'open_backup_receipt_photo_option',
    );
    expect(metadata['nativeCameraEngine'], 'cameraX');
    expect(metadata['nativeCameraAvailable'], isTrue);
    expect(metadata['nativeCameraPermissionGranted'], isTrue);
    expect(metadata['nativeCameraHasRearCamera'], isTrue);
  });

  test('allows privacy-safe receipt install footprint metadata only', () {
    final sanitized = ExpenseTelemetryPolicy.sanitize(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.ocrStarted,
        metadata: const {
          'source': 'expenses',
          'receiptInstallRequiredBaseBytes': 40 * 1024 * 1024,
          'receiptInstallOptionalOfflineBytes': 24 * 1024 * 1024,
          'receiptInstallFullOfflineBytes': 64 * 1024 * 1024,
          'receiptInstallStorageClass': 'low',
          'receiptInstallRequiredSegmentCode': 'required_base_lean_under_40mb',
          'receiptInstallFullOfflineSegmentCode':
              'full_offline_under_100mb_optional',
          'receiptInstallLowStorageUserImpactCode':
              'low_storage_base_only_optional_pack_hidden',
          'receiptInstallRecommendedDistributionCode':
              'ship_base_hide_large_packs_until_storage_allows',
          'receiptInstallCameraShellParserFree': true,
          'receiptInstallBaseUsefulOnTinyPhones': true,
          'receiptInstallOptionalPacksRequireConsent': true,
          'receiptInstallUserFacingSummary':
              'Base receipt flow works before optional packs.',
        },
      ),
    );

    final metadata = sanitized['metadata'] as Map<String, Object?>;
    expect(
      metadata['receiptInstallRecommendedDistributionCode'],
      'ship_base_hide_large_packs_until_storage_allows',
    );
    expect(metadata['receiptInstallBaseUsefulOnTinyPhones'], isTrue);
    expect(metadata['receiptInstallOptionalOfflineBytes'], 24 * 1024 * 1024);
  });

  test(
    'records scheduled OCR summary queue trace without receipt content',
    () async {
      final store = await ExpenseTelemetryStore.create();

      await ExpenseScreenTelemetryRecorder.recordSummaryScheduleTrace(
        const ExpenseTelemetrySummaryScheduleResult(
          status: ExpenseTelemetrySummaryScheduleStatus.queued,
          queuedPath: 'orgs/ORG-1/expenseTelemetrySummaries/latest',
          ocrContractQueued: true,
          ocrContractSource: 'rolling_local_ledger',
        ),
      );

      expect(store.records, hasLength(1));
      final payload = store.records.single.payload;
      final metadata = payload['metadata'] as Map<String, Object?>;
      expect(payload['event'], ExpenseTelemetryEventType.syncPending.name);
      expect(metadata['syncState'], 'expense_summary_queued');
      expect(metadata['summaryStatus'], 'queued');
      expect(metadata['ocrContractQueued'], isTrue);
      expect(metadata['ocrContractSource'], 'rolling_local_ledger');
      expect(metadata.containsKey('queuedPath'), isFalse);
      expect(payload.toString().toLowerCase(), isNot(contains('receipt text')));
      expect(payload.toString(), isNot(contains('ORG-1')));
    },
  );

  test(
    'does not record scheduled summary trace for throttled checks',
    () async {
      final store = await ExpenseTelemetryStore.create();

      await ExpenseScreenTelemetryRecorder.recordSummaryScheduleTrace(
        ExpenseTelemetrySummaryScheduleResult(
          status: ExpenseTelemetrySummaryScheduleStatus.throttled,
          nextAllowedAtUtc: DateTime.utc(2026, 6, 24, 13, 15),
        ),
      );

      expect(store.records, isEmpty);
    },
  );

  test('summarizes scheduled OCR summary queue traces for Command 1', () async {
    final store = await ExpenseTelemetryStore.create();

    await store.enqueue(
      const ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.syncPending,
        metadata: {
          'syncState': 'expense_summary_queued',
          'summaryStatus': 'queued',
          'ocrContractQueued': true,
          'ocrContractSource': 'rolling_local_ledger',
        },
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
    );
    await store.enqueue(
      const ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.syncPending,
        metadata: {
          'syncState': 'expense_summary_queued',
          'summaryStatus': 'queued',
          'ocrContractQueued': false,
          'ocrContractSource': 'none',
          'ocrContractSkippedReason': 'ledger_ocr_contract_disabled',
        },
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 1),
    );
    await store.enqueue(
      const ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.syncPending,
        metadata: {'syncState': 'unrelated_sync_queue'},
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 2),
    );

    final snapshot = store.buildHealthSnapshot(
      nowUtc: DateTime.utc(2026, 6, 24, 13),
    );
    final map = snapshot.toCommandCenterMap();
    final encoded = map.toString().toLowerCase();

    expect(snapshot.syncPendingCount, 3);
    expect(snapshot.expenseSummaryQueuedCount, 2);
    expect(snapshot.expenseSummaryOcrContractQueuedCount, 1);
    expect(snapshot.expenseSummaryOcrContractSkippedCount, 1);
    expect(snapshot.expenseSummaryOcrContractSourceCounts, {
      'rolling_local_ledger': 1,
      'none': 1,
    });
    expect(snapshot.topExpenseSummaryOcrContractSource, 'none');
    expect(snapshot.expenseSummaryOcrContractSkippedReasonCounts, {
      'ledger_ocr_contract_disabled': 1,
    });
    expect(
      snapshot.topExpenseSummaryOcrContractSkippedReason,
      'ledger_ocr_contract_disabled',
    );
    expect(map['expenseSummaryQueuedCount'], 2);
    expect(map['expenseSummaryOcrContractQueuedCount'], 1);
    expect(map['expenseSummaryOcrContractSkippedCount'], 1);
    expect(encoded, isNot(contains('lowes')));
    expect(encoded, isNot(contains('receipt text')));
  });

  test(
    'rejects receipt text and private user content before storage',
    () async {
      final store = await ExpenseTelemetryStore.create();

      expect(
        () => ExpenseTelemetryPolicy.sanitizeMap({
          'event': ExpenseTelemetryEventType.receiptExpenseCreated.name,
          'receiptText': 'LOWES COPPER PIPE TOTAL 99.99',
        }),
        throwsArgumentError,
      );
      expect(
        () => ExpenseTelemetryPolicy.sanitize(
          ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.validationError,
            metadata: const {'notes': 'Customer asked me to hide this'},
          ),
        ),
        throwsArgumentError,
      );
      expect(
        store.enqueue(
          const ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.saveFailure,
            failureKind: 'PRIVATE STORE 99.99',
          ),
        ),
        throwsArgumentError,
      );
    },
  );
}
