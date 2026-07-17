import '../../../shared/firebase/maintainiac_firestore_documents.dart';
import '../../../shared/firebase/maintainiac_firestore_upload_queue.dart';

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
    int? freeSyncsRemaining,
    int? syncsUsedInWindow,
    bool batteryGpsLimited = false,
    bool reviewRequired = false,
  }) async {
    final document =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: uid,
          dashboardId: dashboardId,
          updatedAtUtc: updatedAtUtc,
          orgId: orgId,
          activeVehicleId: activeVehicleId,
          activeWorkdayId: activeWorkdayId,
          activeWorkProfileId: activeWorkProfileId,
          dashboardMode: dashboardMode,
          mileageMode: mileageMode,
          syncMode: syncMode,
          gpsAssistState: gpsAssistState,
          storageState: storageState,
          freeSyncsRemaining: freeSyncsRemaining,
          syncsUsedInWindow: syncsUsedInWindow,
          batteryGpsLimited: batteryGpsLimited,
          reviewRequired: reviewRequired,
        );
    await _queueStore.enqueueReplacingPendingForPath(
      document,
      queuedAtUtc: updatedAtUtc.toUtc(),
      preserveAttemptMetadata: true,
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
}
