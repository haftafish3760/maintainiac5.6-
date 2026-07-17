import '../../../shared/context/operational_context_models.dart';
import '../../../shared/firebase/maintainiac_firestore_documents.dart';
import '../../../shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'dashboard_trip_tracking_summary.dart';

/// Dashboard-only cloud mirror.
///
/// This queues reference-only command-center summaries. It deliberately does
/// not upload raw module records, GPS points, route geometry, addresses,
/// receipt text, or local file paths.
class DashboardFirestoreMirror {
  DashboardFirestoreMirror({
    required MaintainiacFirestoreUploadQueueStore queueStore,
    required MaintainiacFirestoreUploadCoordinator uploadCoordinator,
  }) : _queueStore = queueStore,
       _uploadCoordinator = uploadCoordinator;

  final MaintainiacFirestoreUploadQueueStore _queueStore;
  final MaintainiacFirestoreUploadCoordinator _uploadCoordinator;

  Future<void> queueSummary({
    required String uid,
    required String dashboardId,
    required DateTime updatedAtUtc,
    String? orgId,
    String? activeVehicleId,
    String? activeWorkdayId,
    String? activeWorkProfileId,
    String dashboardMode = 'default',
    String mileageMode = 'manual',
    String syncMode = 'device_retained',
    String gpsAssistState = 'off',
    String storageState = 'unknown',
    String deviceCapabilityState = 'unknown',
    String sensorAssistState = 'unknown',
    String odometerCalibrationState = 'unknown',
    int? odometerCalibrationSamples,
    int? freeSyncsRemaining,
    int? syncsUsedInWindow,
    bool batteryGpsLimited = false,
    bool reviewRequired = false,
  }) async {
    final updatedAt = updatedAtUtc.toUtc();
    final existing = _pendingSummaryFor(
      uid: uid,
      dashboardId: dashboardId,
      orgId: orgId,
      nowUtc: updatedAt,
    );
    final existingUpdatedAt = existing == null
        ? null
        : DateTime.tryParse('${existing.data['updatedAt'] ?? ''}');
    if (existingUpdatedAt != null && updatedAt.isBefore(existingUpdatedAt)) {
      return;
    }
    final document =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: uid,
          dashboardId: dashboardId,
          updatedAtUtc: updatedAt,
          orgId: orgId,
          activeVehicleId: activeVehicleId,
          activeWorkdayId: activeWorkdayId,
          activeWorkProfileId: activeWorkProfileId,
          dashboardMode: dashboardMode,
          mileageMode: mileageMode,
          syncMode: syncMode,
          gpsAssistState: gpsAssistState,
          storageState: storageState,
          deviceCapabilityState: deviceCapabilityState,
          sensorAssistState: sensorAssistState,
          odometerCalibrationState: odometerCalibrationState,
          odometerCalibrationSamples: odometerCalibrationSamples,
          freeSyncsRemaining: freeSyncsRemaining,
          syncsUsedInWindow: syncsUsedInWindow,
          batteryGpsLimited: batteryGpsLimited,
          reviewRequired: reviewRequired,
        );
    await _queueStore.enqueueReplacingPendingForPath(
      document,
      queuedAtUtc: updatedAt,
      preserveAttemptMetadata: true,
    );
  }

  Future<void> queueOperationalContextSummary({
    required String uid,
    required String dashboardId,
    required ActiveOperationalContext operationalContext,
    required DateTime updatedAtUtc,
    String? activeWorkdayId,
    String gpsAssistState = 'off',
    String storageState = 'unknown',
    String deviceCapabilityState = 'unknown',
    String sensorAssistState = 'unknown',
    String odometerCalibrationState = 'unknown',
    int? odometerCalibrationSamples,
    int? freeSyncsRemaining,
    int? syncsUsedInWindow,
    bool batteryGpsLimited = false,
    bool reviewRequired = false,
  }) {
    return queueSummary(
      uid: uid,
      dashboardId: dashboardId,
      updatedAtUtc: updatedAtUtc,
      orgId: operationalContext.companyId.trim().isEmpty
          ? null
          : operationalContext.companyId,
      activeVehicleId: operationalContext.activeVehicleId,
      activeWorkdayId: activeWorkdayId,
      activeWorkProfileId: operationalContext.workProfileId,
      dashboardMode: operationalContext.dashboardSummaryModeToken,
      mileageMode: operationalContext.dashboardSummaryMileageToken,
      syncMode: operationalContext.dashboardSummarySyncToken,
      gpsAssistState: gpsAssistState,
      storageState: storageState,
      deviceCapabilityState: deviceCapabilityState,
      sensorAssistState: sensorAssistState,
      odometerCalibrationState: odometerCalibrationState,
      odometerCalibrationSamples: odometerCalibrationSamples,
      freeSyncsRemaining: freeSyncsRemaining,
      syncsUsedInWindow: syncsUsedInWindow,
      batteryGpsLimited: batteryGpsLimited,
      reviewRequired: reviewRequired,
    );
  }

  Future<void> queueTripTrackingSummary({
    required String uid,
    required String dashboardId,
    required DateTime updatedAtUtc,
    required DashboardTripTrackingSummary tripTracking,
    String? orgId,
    String? activeVehicleId,
    String? activeWorkdayId,
    String? activeWorkProfileId,
  }) {
    return queueSummary(
      uid: uid,
      dashboardId: dashboardId,
      updatedAtUtc: updatedAtUtc,
      orgId: orgId,
      activeVehicleId: activeVehicleId,
      activeWorkdayId: activeWorkdayId,
      activeWorkProfileId: activeWorkProfileId,
      dashboardMode: tripTracking.dashboardMode,
      mileageMode: tripTracking.mileageMode,
      syncMode: tripTracking.syncMode,
      gpsAssistState: tripTracking.gpsAssistState,
      storageState: tripTracking.storageState,
      deviceCapabilityState: tripTracking.deviceCapabilityState,
      sensorAssistState: tripTracking.sensorAssistState,
      odometerCalibrationState: tripTracking.odometerCalibrationState,
      odometerCalibrationSamples: tripTracking.odometerCalibrationSamples,
      freeSyncsRemaining: tripTracking.freeSyncsRemaining,
      syncsUsedInWindow: tripTracking.syncsUsedInWindow,
      batteryGpsLimited: tripTracking.batteryGpsLimited,
      reviewRequired: tripTracking.reviewRequired,
    );
  }

  Future<MaintainiacFirestoreUploadResult> flushSummary({
    required String uid,
    required String dashboardId,
    String? orgId,
    DateTime? nowUtc,
  }) {
    final path = orgId == null
        ? MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
            uid: uid,
            dashboardId: dashboardId,
            updatedAtUtc: nowUtc ?? DateTime.now().toUtc(),
          ).path
        : MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
            uid: uid,
            orgId: orgId,
            dashboardId: dashboardId,
            updatedAtUtc: nowUtc ?? DateTime.now().toUtc(),
          ).path;
    return _uploadCoordinator.uploadPending(path: path, nowUtc: nowUtc);
  }

  MaintainiacFirestoreQueuedDocument? _pendingSummaryFor({
    required String uid,
    required String dashboardId,
    required String? orgId,
    required DateTime nowUtc,
  }) {
    final path = orgId == null
        ? MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
            uid: uid,
            dashboardId: dashboardId,
            updatedAtUtc: nowUtc,
          ).path
        : MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
            uid: uid,
            orgId: orgId,
            dashboardId: dashboardId,
            updatedAtUtc: nowUtc,
          ).path;
    for (final record in _queueStore.pendingRecords) {
      if (record.path == path) return record;
    }
    return null;
  }
}
