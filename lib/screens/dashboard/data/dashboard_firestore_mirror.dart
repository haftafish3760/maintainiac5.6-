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
    String workStyle = 'general_road',
    String stopDetectionMode = 'walking_assisted',
    String stopReviewReasonCode = 'road_vehicle_stop_walk_review',
    String stopSignal = 'no_stop',
    String stopActionToken = 'keep_tracking',
    String stopClassificationReason = 'no_stop_review_needed',
    bool recommendedActivityRecognition = true,
    bool requiresStrongerStopDebounce = false,
    String recoveryState = 'none',
    String recoveryReason = 'trip_recovery_none',
    bool recoveryUserActionRequired = false,
    String mileageMode = 'manual',
    String syncMode = 'device_retained',
    String gpsAssistState = 'off',
    String gpsSignalQuality = 'no_samples',
    String gpsSignalReason = 'gps_signal_waiting_for_samples',
    bool gpsSignalReviewRequired = false,
    String mapboxAssistState = 'disabled',
    String mapboxAssistReason = 'mapbox_assist_disabled',
    bool mapboxAssistReviewRequired = false,
    String mapboxTrustedMileageSource = 'none',
    double? mapboxRouteDistanceMiles,
    double? mapboxRouteDeltaMiles,
    bool mapPreviewEnabled = false,
    bool mapRouteHistorySavingEnabled = false,
    double mapRouteHistoryDailyBudgetMb = 0,
    int mapRouteHistorySampleIntervalSeconds = 30,
    String mapRouteHistoryState = 'disabled',
    int mapRouteHistoryEstimatedSamplesPerDay = 0,
    double mapRouteHistoryEstimatedDailyMb = 0,
    String storageState = 'unknown',
    String deviceCapabilityState = 'unknown',
    String sensorAssistState = 'unknown',
    String durableRecordBackupState = 'not_configured',
    bool usesSharedDeviceCapabilityProfile = false,
    bool usesSharedDurableTripRecordStore = false,
    bool durableTripRecordsReviewedOnly = false,
    bool odometerCalibrationAssistEnabled = false,
    String odometerCalibrationState = 'disabled',
    int? odometerCalibrationSamples,
    double? odometerCalibrationMultiplier,
    String odometerUsageState = 'disabled',
    int? odometerUsageReviewedDays,
    double? odometerUsageCurrentMiles,
    double? odometerUsageAverageDailyMiles,
    double? odometerUsageReviewThresholdMiles,
    List<String> dashboardWidgetTokens = const [],
    List<String> quickActionTokens = const [],
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
          workStyle: workStyle,
          stopDetectionMode: stopDetectionMode,
          stopReviewReasonCode: stopReviewReasonCode,
          stopSignal: stopSignal,
          stopActionToken: stopActionToken,
          stopClassificationReason: stopClassificationReason,
          recommendedActivityRecognition: recommendedActivityRecognition,
          requiresStrongerStopDebounce: requiresStrongerStopDebounce,
          recoveryState: recoveryState,
          recoveryReason: recoveryReason,
          recoveryUserActionRequired: recoveryUserActionRequired,
          mileageMode: mileageMode,
          syncMode: syncMode,
          gpsAssistState: gpsAssistState,
          gpsSignalQuality: gpsSignalQuality,
          gpsSignalReason: gpsSignalReason,
          gpsSignalReviewRequired: gpsSignalReviewRequired,
          mapboxAssistState: mapboxAssistState,
          mapboxAssistReason: mapboxAssistReason,
          mapboxAssistReviewRequired: mapboxAssistReviewRequired,
          mapboxTrustedMileageSource: mapboxTrustedMileageSource,
          mapboxRouteDistanceMiles: mapboxRouteDistanceMiles,
          mapboxRouteDeltaMiles: mapboxRouteDeltaMiles,
          mapPreviewEnabled: mapPreviewEnabled,
          mapRouteHistorySavingEnabled: mapRouteHistorySavingEnabled,
          mapRouteHistoryDailyBudgetMb: mapRouteHistoryDailyBudgetMb,
          mapRouteHistorySampleIntervalSeconds:
              mapRouteHistorySampleIntervalSeconds,
          mapRouteHistoryState: mapRouteHistoryState,
          mapRouteHistoryEstimatedSamplesPerDay:
              mapRouteHistoryEstimatedSamplesPerDay,
          mapRouteHistoryEstimatedDailyMb: mapRouteHistoryEstimatedDailyMb,
          storageState: storageState,
          deviceCapabilityState: deviceCapabilityState,
          sensorAssistState: sensorAssistState,
          durableRecordBackupState: durableRecordBackupState,
          usesSharedDeviceCapabilityProfile: usesSharedDeviceCapabilityProfile,
          usesSharedDurableTripRecordStore: usesSharedDurableTripRecordStore,
          durableTripRecordsReviewedOnly: durableTripRecordsReviewedOnly,
          odometerCalibrationAssistEnabled: odometerCalibrationAssistEnabled,
          odometerCalibrationState: odometerCalibrationState,
          odometerCalibrationSamples: odometerCalibrationSamples,
          odometerCalibrationMultiplier: odometerCalibrationMultiplier,
          odometerUsageState: odometerUsageState,
          odometerUsageReviewedDays: odometerUsageReviewedDays,
          odometerUsageCurrentMiles: odometerUsageCurrentMiles,
          odometerUsageAverageDailyMiles: odometerUsageAverageDailyMiles,
          odometerUsageReviewThresholdMiles: odometerUsageReviewThresholdMiles,
          dashboardWidgetTokens: dashboardWidgetTokens,
          quickActionTokens: quickActionTokens,
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
    String gpsSignalQuality = 'no_samples',
    String gpsSignalReason = 'gps_signal_waiting_for_samples',
    bool gpsSignalReviewRequired = false,
    String mapboxAssistState = 'disabled',
    String mapboxAssistReason = 'mapbox_assist_disabled',
    bool mapboxAssistReviewRequired = false,
    String mapboxTrustedMileageSource = 'none',
    double? mapboxRouteDistanceMiles,
    double? mapboxRouteDeltaMiles,
    bool mapPreviewEnabled = false,
    bool mapRouteHistorySavingEnabled = false,
    double mapRouteHistoryDailyBudgetMb = 0,
    int mapRouteHistorySampleIntervalSeconds = 30,
    String mapRouteHistoryState = 'disabled',
    int mapRouteHistoryEstimatedSamplesPerDay = 0,
    double mapRouteHistoryEstimatedDailyMb = 0,
    String storageState = 'unknown',
    String deviceCapabilityState = 'unknown',
    String sensorAssistState = 'unknown',
    String durableRecordBackupState = 'not_configured',
    bool usesSharedDeviceCapabilityProfile = false,
    bool usesSharedDurableTripRecordStore = false,
    bool durableTripRecordsReviewedOnly = false,
    bool odometerCalibrationAssistEnabled = false,
    String odometerCalibrationState = 'disabled',
    int? odometerCalibrationSamples,
    double? odometerCalibrationMultiplier,
    String odometerUsageState = 'disabled',
    int? odometerUsageReviewedDays,
    double? odometerUsageCurrentMiles,
    double? odometerUsageAverageDailyMiles,
    double? odometerUsageReviewThresholdMiles,
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
      workStyle: 'general_road',
      stopDetectionMode: 'walking_assisted',
      stopReviewReasonCode: 'road_vehicle_stop_walk_review',
      stopSignal: 'no_stop',
      stopActionToken: 'keep_tracking',
      stopClassificationReason: 'no_stop_review_needed',
      recommendedActivityRecognition: true,
      requiresStrongerStopDebounce: false,
      recoveryState: 'none',
      recoveryReason: 'trip_recovery_none',
      recoveryUserActionRequired: false,
      mileageMode: operationalContext.dashboardSummaryMileageToken,
      syncMode: operationalContext.dashboardSummarySyncToken,
      gpsAssistState: gpsAssistState,
      gpsSignalQuality: gpsSignalQuality,
      gpsSignalReason: gpsSignalReason,
      gpsSignalReviewRequired: gpsSignalReviewRequired,
      mapboxAssistState: mapboxAssistState,
      mapboxAssistReason: mapboxAssistReason,
      mapboxAssistReviewRequired: mapboxAssistReviewRequired,
      mapboxTrustedMileageSource: mapboxTrustedMileageSource,
      mapboxRouteDistanceMiles: mapboxRouteDistanceMiles,
      mapboxRouteDeltaMiles: mapboxRouteDeltaMiles,
      mapPreviewEnabled: mapPreviewEnabled,
      mapRouteHistorySavingEnabled: mapRouteHistorySavingEnabled,
      mapRouteHistoryDailyBudgetMb: mapRouteHistoryDailyBudgetMb,
      mapRouteHistorySampleIntervalSeconds:
          mapRouteHistorySampleIntervalSeconds,
      mapRouteHistoryState: mapRouteHistoryState,
      mapRouteHistoryEstimatedSamplesPerDay:
          mapRouteHistoryEstimatedSamplesPerDay,
      mapRouteHistoryEstimatedDailyMb: mapRouteHistoryEstimatedDailyMb,
      storageState: storageState,
      deviceCapabilityState: deviceCapabilityState,
      sensorAssistState: sensorAssistState,
      durableRecordBackupState: durableRecordBackupState,
      usesSharedDeviceCapabilityProfile: usesSharedDeviceCapabilityProfile,
      usesSharedDurableTripRecordStore: usesSharedDurableTripRecordStore,
      durableTripRecordsReviewedOnly: durableTripRecordsReviewedOnly,
      odometerCalibrationAssistEnabled: odometerCalibrationAssistEnabled,
      odometerCalibrationState: odometerCalibrationState,
      odometerCalibrationSamples: odometerCalibrationSamples,
      odometerCalibrationMultiplier: odometerCalibrationMultiplier,
      odometerUsageState: odometerUsageState,
      odometerUsageReviewedDays: odometerUsageReviewedDays,
      odometerUsageCurrentMiles: odometerUsageCurrentMiles,
      odometerUsageAverageDailyMiles: odometerUsageAverageDailyMiles,
      odometerUsageReviewThresholdMiles: odometerUsageReviewThresholdMiles,
      dashboardWidgetTokens: const [],
      quickActionTokens: const [],
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
      workStyle: tripTracking.workStyle,
      stopDetectionMode: tripTracking.stopDetectionMode,
      stopReviewReasonCode: tripTracking.stopReviewReasonCode,
      stopSignal: tripTracking.stopSignal,
      stopActionToken: tripTracking.stopActionToken,
      stopClassificationReason: tripTracking.stopClassificationReason,
      recommendedActivityRecognition:
          tripTracking.recommendedActivityRecognition,
      requiresStrongerStopDebounce: tripTracking.requiresStrongerStopDebounce,
      recoveryState: tripTracking.recoveryState,
      recoveryReason: tripTracking.recoveryReason,
      recoveryUserActionRequired: tripTracking.recoveryUserActionRequired,
      mileageMode: tripTracking.mileageMode,
      syncMode: tripTracking.syncMode,
      gpsAssistState: tripTracking.gpsAssistState,
      gpsSignalQuality: tripTracking.gpsSignalQuality,
      gpsSignalReason: tripTracking.gpsSignalReason,
      gpsSignalReviewRequired: tripTracking.gpsSignalReviewRequired,
      mapboxAssistState: tripTracking.mapboxAssistState,
      mapboxAssistReason: tripTracking.mapboxAssistReason,
      mapboxAssistReviewRequired: tripTracking.mapboxAssistReviewRequired,
      mapboxTrustedMileageSource: tripTracking.mapboxTrustedMileageSource,
      mapboxRouteDistanceMiles: tripTracking.mapboxRouteDistanceMiles,
      mapboxRouteDeltaMiles: tripTracking.mapboxRouteDeltaMiles,
      mapPreviewEnabled: tripTracking.mapPreviewEnabled,
      mapRouteHistorySavingEnabled: tripTracking.mapRouteHistorySavingEnabled,
      mapRouteHistoryDailyBudgetMb: tripTracking.mapRouteHistoryDailyBudgetMb,
      mapRouteHistorySampleIntervalSeconds:
          tripTracking.mapRouteHistorySampleIntervalSeconds,
      mapRouteHistoryState: tripTracking.mapRouteHistoryState,
      mapRouteHistoryEstimatedSamplesPerDay:
          tripTracking.mapRouteHistoryEstimatedSamplesPerDay,
      mapRouteHistoryEstimatedDailyMb:
          tripTracking.mapRouteHistoryEstimatedDailyMb,
      storageState: tripTracking.storageState,
      deviceCapabilityState: tripTracking.deviceCapabilityState,
      sensorAssistState: tripTracking.sensorAssistState,
      durableRecordBackupState: tripTracking.durableRecordBackupState,
      usesSharedDeviceCapabilityProfile:
          tripTracking.usesSharedDeviceCapabilityProfile,
      usesSharedDurableTripRecordStore:
          tripTracking.usesSharedDurableTripRecordStore,
      durableTripRecordsReviewedOnly:
          tripTracking.durableTripRecordsReviewedOnly,
      odometerCalibrationAssistEnabled:
          tripTracking.odometerCalibrationAssistEnabled,
      odometerCalibrationState: tripTracking.odometerCalibrationState,
      odometerCalibrationSamples: tripTracking.odometerCalibrationSamples,
      odometerCalibrationMultiplier: tripTracking.odometerCalibrationMultiplier,
      odometerUsageState: tripTracking.odometerUsageState,
      odometerUsageReviewedDays: tripTracking.odometerUsageReviewedDays,
      odometerUsageCurrentMiles: tripTracking.odometerUsageCurrentMiles,
      odometerUsageAverageDailyMiles:
          tripTracking.odometerUsageAverageDailyMiles,
      odometerUsageReviewThresholdMiles:
          tripTracking.odometerUsageReviewThresholdMiles,
      dashboardWidgetTokens: tripTracking.dashboardWidgetTokens,
      quickActionTokens: tripTracking.quickActionTokens,
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
