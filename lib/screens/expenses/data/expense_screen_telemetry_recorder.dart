import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../shared/profiles/user_profile_store.dart';
import '../../../shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import '../../../shared/widgets/receipt_capture/receipt_capture_models.dart';
import '../../../shared/widgets/receipt_capture/receipt_capture_settings_store.dart';
import 'expense_screen_telemetry.dart';
import 'expense_screen_telemetry_summary_scheduler.dart';

class ExpenseScreenTelemetryRecorder {
  const ExpenseScreenTelemetryRecorder._();

  static void record(
    BuildContext context,
    ExpenseTelemetryEventType type, {
    int durationMs = 0,
    String? validationErrorKind,
    String? failureKind,
    ExpenseFailureDiagnostic? diagnostic,
    String? categoryGroup,
    Map<String, Object?> metadata = const {},
  }) {
    final event = ExpenseTelemetryEvent(
      type: type,
      context: contextFor(context),
      durationMs: durationMs,
      validationErrorKind: validationErrorKind,
      failureKind: failureKind,
      diagnostic: diagnostic,
      categoryGroup: categoryGroup,
      metadata: metadata,
    );
    final profile = UserProfileScope.maybeOf(context)?.activeProfile;
    final orgIdForSummary = profile?.cloudBackupEnabled == true
        ? profile?.id
        : null;
    unawaited(_enqueueAndQueueSummary(event, orgIdForSummary));
  }

  static ExpenseScreenTelemetrySnapshot snapshot(BuildContext context) {
    final profile = UserProfileScope.maybeOf(context)?.activeProfile;
    return ExpenseScreenTelemetrySnapshot(
      context: contextFor(context),
      summaryOrgId: profile?.cloudBackupEnabled == true ? profile?.id : null,
    );
  }

  static void recordSnapshot(
    ExpenseScreenTelemetrySnapshot snapshot,
    ExpenseTelemetryEventType type, {
    int durationMs = 0,
    String? validationErrorKind,
    String? failureKind,
    ExpenseFailureDiagnostic? diagnostic,
    String? categoryGroup,
    Map<String, Object?> metadata = const {},
  }) {
    final event = ExpenseTelemetryEvent(
      type: type,
      context: snapshot.context,
      durationMs: durationMs,
      validationErrorKind: validationErrorKind,
      failureKind: failureKind,
      diagnostic: diagnostic,
      categoryGroup: categoryGroup,
      metadata: metadata,
    );
    unawaited(_enqueueAndQueueSummary(event, snapshot.summaryOrgId));
  }

  static ExpenseTelemetryContext contextFor(BuildContext context) {
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    final profile = UserProfileScope.maybeOf(context)?.activeProfile;
    return ExpenseTelemetryContext(
      appVersion: const String.fromEnvironment(
        'MAINTAINIAC_APP_VERSION',
        defaultValue: '1.0.0',
      ),
      platform: defaultTargetPlatform.name,
      deviceTier:
          settings?.deviceCapability.tier.name ??
          ReceiptCapabilityTier.medium.name,
      profileType: profile?.type.name ?? 'unknown',
      storageMode: _storageModeFor(settings?.defaultDataSaverLevel),
      planStatus: ExpenseTelemetryPlanStatus.unknown,
      connectionStatus: ExpenseTelemetryConnectionStatus.unknown,
    );
  }

  static ExpenseTelemetryStorageMode storageModeForAttachment(
    ReceiptAttachmentRecord attachment,
  ) {
    return _storageModeFor(attachment.dataSaverLevel);
  }

  static Future<void> _enqueue(ExpenseTelemetryEvent event) async {
    try {
      final store = await ExpenseTelemetryStore.create();
      await store.enqueue(event);
    } catch (_) {
      // Expense telemetry must never interrupt the user's receipt workflow.
    }
  }

  static Future<void> _enqueueAndQueueSummary(
    ExpenseTelemetryEvent event,
    String? orgId,
  ) async {
    await _enqueue(event);
    if (orgId == null || orgId.trim().isEmpty) return;
    await _queueSummaryIfDue(orgId);
  }

  static Future<void> _queueSummaryIfDue(String orgId) async {
    try {
      final scheduler = await ExpenseTelemetrySummaryScheduler.create();
      final result = await scheduler.queueIfDue(orgId: orgId);
      await recordSummaryScheduleTrace(result);
    } catch (_) {
      // Summary scheduling must never interrupt expense entry.
    }
  }

  @visibleForTesting
  static Future<void> recordSummaryScheduleTrace(
    ExpenseTelemetrySummaryScheduleResult result,
  ) async {
    if (result.status != ExpenseTelemetrySummaryScheduleStatus.queued) return;
    await _enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.syncPending,
        metadata: {
          'syncState': 'expense_summary_queued',
          'summaryStatus': result.status.name,
          'ocrContractQueued': result.ocrContractQueued,
          'ocrContractSource': result.ocrContractSource,
          if (result.ocrContractSkippedReason.isNotEmpty)
            'ocrContractSkippedReason': result.ocrContractSkippedReason,
        },
      ),
    );
  }

  static ExpenseTelemetryStorageMode _storageModeFor(
    ReceiptDataSaverLevel? level,
  ) {
    return switch (level) {
      ReceiptDataSaverLevel.original ||
      ReceiptDataSaverLevel.light ||
      null => ExpenseTelemetryStorageMode.normal,
      ReceiptDataSaverLevel.balanced ||
      ReceiptDataSaverLevel.strong => ExpenseTelemetryStorageMode.low,
      ReceiptDataSaverLevel.maximum => ExpenseTelemetryStorageMode.ultraLow,
    };
  }
}

@immutable
class ExpenseScreenTelemetrySnapshot {
  const ExpenseScreenTelemetrySnapshot({
    required this.context,
    this.summaryOrgId,
  });

  final ExpenseTelemetryContext context;
  final String? summaryOrgId;
}
