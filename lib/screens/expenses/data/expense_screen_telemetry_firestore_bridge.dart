import '../../../shared/firebase/maintainiac_firestore_documents.dart';
import '../../../shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'expense_screen_telemetry.dart';

class ExpenseTelemetryFirestoreWriteBudget {
  const ExpenseTelemetryFirestoreWriteBudget._();

  static const dailyFirestoreWriteSafetyTarget = 20000;
  static const rawEventUploadCount = 0;
  static const uploadShape = 'single_summary_document';

  static int estimatedScheduledSummaryWritesPerDay(Duration minInterval) {
    if (minInterval <= Duration.zero) return dailyFirestoreWriteSafetyTarget;
    return (const Duration(days: 1).inMicroseconds / minInterval.inMicroseconds)
        .ceil();
  }
}

class ExpenseTelemetryFirestoreBridgeResult {
  const ExpenseTelemetryFirestoreBridgeResult({
    required this.queuedDocument,
    required this.snapshot,
  });

  final MaintainiacFirestoreQueuedDocument queuedDocument;
  final ExpenseTelemetryHealthSnapshot snapshot;
}

class ExpenseTelemetryFirestoreBridge {
  const ExpenseTelemetryFirestoreBridge({
    required ExpenseTelemetryStore telemetryStore,
    required MaintainiacFirestoreUploadQueueStore queueStore,
  }) : _telemetryStore = telemetryStore,
       _queueStore = queueStore;

  final ExpenseTelemetryStore _telemetryStore;
  final MaintainiacFirestoreUploadQueueStore _queueStore;

  static Future<ExpenseTelemetryFirestoreBridge> create() async {
    return ExpenseTelemetryFirestoreBridge(
      telemetryStore: await ExpenseTelemetryStore.create(),
      queueStore: await MaintainiacFirestoreUploadQueueStore.create(),
    );
  }

  Future<ExpenseTelemetryFirestoreBridgeResult> queueHealthSummary({
    required String orgId,
    String summaryId = 'latest',
    DateTime? nowUtc,
    Map<String, Object?>? commandCenterOcrContract,
  }) async {
    final generatedAt = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final snapshot = _telemetryStore.buildHealthSnapshot(nowUtc: generatedAt);
    final queued = await _queueStore.enqueueReplacingPendingForPath(
      MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
        orgId: orgId,
        summaryId: summaryId,
        snapshot: snapshot,
        commandCenterOcrContract: commandCenterOcrContract,
      ),
      queuedAtUtc: generatedAt,
    );
    return ExpenseTelemetryFirestoreBridgeResult(
      queuedDocument: queued,
      snapshot: snapshot,
    );
  }
}
