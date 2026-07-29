import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/maintaniac_app.dart';
import 'screens/dashboard/active_workday_actions.dart';
import 'screens/dashboard/data/active_workday_context_handoff_coordinator.dart';
import 'screens/dashboard/data/active_workday_store.dart';
import 'screens/dashboard/data/dashboard_firestore_mirror.dart';
import 'screens/dashboard/data/dashboard_trip_tracking_summary_reporter.dart';
import 'screens/expenses/data/expense_draft_store.dart';
import 'screens/expenses/data/expense_cloud_backup_service.dart';
import 'screens/expenses/data/expense_cloud_proof_reference_store.dart';
import 'screens/expenses/data/expense_export_store.dart';
import 'screens/expenses/data/expense_ledger_store.dart';
import 'screens/expenses/data/expense_reminder_store.dart';
import 'screens/expenses/data/expense_work_profile_store.dart';
import 'screens/invoices/data/invoice_ledger_store.dart';
import 'shared/state/app_state.dart';
import 'shared/state/expense_settings_store.dart';
import 'shared/firebase/maintainiac_firebase.dart';
import 'shared/firebase/app_installation_identity.dart';
import 'shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'shared/context/operational_context_store.dart';
import 'shared/device_capabilities/device_capabilities.dart';
import 'shared/jobs/maintainiac_job_store.dart';
import 'shared/maps/mapbox_runtime.dart';
import 'shared/profiles/user_profile_store.dart';
import 'shared/profiles/employee_work_time_store.dart';
import 'shared/records/maintainiac_durable_record_store.dart';
import 'shared/signatures/app_signature_store.dart';
import 'shared/state/global_odometer.dart';
import 'shared/storage/app_storage_guard.dart';
import 'shared/odometer/odometer_store.dart';
import 'shared/odometer/odometer_vehicle_snapshot.dart';
import 'shared/trip_tracking/trip_tracking_controller.dart';
import 'shared/trip_tracking/trip_tracking_bluetooth.dart';
import 'shared/trip_tracking/trip_tracking_bluetooth_coordinator.dart';
import 'shared/trip_tracking/trip_tracking_bluetooth_runtime.dart';
import 'shared/trip_tracking/trip_tracking_durable_record_bridge.dart';
import 'shared/trip_tracking/trip_tracking_platform.dart';
import 'shared/trip_tracking/trip_tracking_route_point_store.dart';
import 'shared/trip_tracking/trip_tracking_session_store.dart';
import 'shared/trip_tracking/trip_tracking_settings_store.dart';
import 'shared/trip_tracking/trip_tracking_trip_log_proposal_store.dart';
import 'shared/widgets/receipt_capture/incoming_receipt_share.dart';
import 'shared/widgets/receipt_capture/receipt_capture_settings_store.dart';

const maintaniacSystemUiStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Color(0xFF050607),
  systemNavigationBarIconBrightness: Brightness.light,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MaintainiacMapRuntime.initializeFromEnvironment();
  final firebaseSupported = await MaintainiacFirebase.initializeIfSupported();
  await Hive.initFlutter();
  final installationIdentity = await AppInstallationIdentityStore()
      .getOrCreate();
  final expenseSettings = await ExpenseSettingsController.create();
  final expenseLedger = await ExpenseLedgerController.create();
  final expenseReminders = await ExpenseReminderController.create();
  final expenseWorkProfiles = await ExpenseWorkProfileController.create();
  final jobs = await MaintainiacJobController.create();
  final expenseDrafts = await ExpenseDraftController.create();
  final expenseExports = await ExpenseExportController.create();
  final receiptCaptureSettings =
      await ReceiptCaptureSettingsController.create();
  final signatureStore = await AppSignatureStore.create();
  final invoiceLedger = await InvoiceLedgerStore.create();
  final userProfiles = await UserProfileController.create();
  final employeeWorkTime = await EmployeeWorkTimeController.createOrMemory();
  final appState = await AppStateController.create();
  ExpenseCloudBackupMirror expenseCloudBackup =
      const NoopExpenseCloudBackupMirror();
  if (firebaseSupported) {
    final queueStore = await MaintainiacFirestoreUploadQueueStore.create();
    final proofReferences = await ExpenseCloudProofReferenceStore.create();
    final uploadCoordinator = MaintainiacFirestoreUploadCoordinator(
      queue: queueStore,
      sink: FirebaseFirestoreDocumentSink(),
      uploadEnabled: true,
    );
    expenseCloudBackup = FirebaseExpenseCloudBackupMirror(
      ledger: expenseLedger,
      settings: expenseSettings,
      reminders: expenseReminders,
      workProfiles: expenseWorkProfiles,
      appState: appState,
      queueStore: queueStore,
      uploadCoordinator: uploadCoordinator,
      proofReferences: proofReferences,
      deviceId: installationIdentity.installationId,
      backupEnabled: () => userProfiles.activeProfile.cloudBackupEnabled,
    );
  }
  final incomingReceiptShare = IncomingReceiptShareController();
  unawaited(incomingReceiptShare.start());
  unawaited(
    expenseDrafts.cleanAbandonedStagedProofs(
      additionalRetainedPaths: [
        for (final receipt in expenseLedger.storedReceipts)
          for (final attachment in receipt.attachments) attachment.path,
      ],
    ),
  );
  final activeWorkday = await ActiveWorkdayController.create();
  final quickActionLayout = await WorkdayQuickActionLayoutController.create();
  final tripTrackingSettings = await TripTrackingSettingsController.create();
  final odometerStore = await OdometerStore.create();
  final activeVehicleId = odometerVehicleIdForVehicleId(
    appState.activeVehicle?.id,
    fallbackLabel: appState.activeVehicle?.nickname,
  );
  final operationalContext = await OperationalContextController.create(
    profile: userProfiles.activeProfile,
    activeVehicleId: activeVehicleId,
    activeVehicleLabel: appState.activeVehicle?.nickname ?? 'Active vehicle',
    activeVehicleUsage:
        appState.activeVehicle?.usage ?? VehicleUsage.businessPersonal,
  );
  await operationalContext.setActiveWorkProfile(
    workProfileId: expenseWorkProfiles.activeWorkProfile.id,
    workProfileName: expenseWorkProfiles.activeWorkProfile.name,
  );
  final odometerSnapshot = odometerStore.snapshotForVehicle(activeVehicleId);
  final globalOdometer = GlobalOdometerController(
    vehicleId: odometerSnapshot.vehicleId,
    initialReading: odometerSnapshot.currentReading,
    initialRecordedAt: odometerSnapshot.updatedAt,
    initialHistory: odometerSnapshot.history,
    snapshotReader: odometerStore.loadSnapshotForVehicle,
    snapshotWriter: odometerStore.saveSnapshot,
  );
  final tripTrackingStore = await TripTrackingSessionStore.create();
  TripTrackingTripLogProposalStore tripLogProposalStore;
  try {
    tripLogProposalStore = await TripTrackingTripLogProposalStore.create();
  } catch (_) {
    tripLogProposalStore = TripTrackingTripLogProposalStore.unavailable();
  }
  TripTrackingRoutePointStore routePointStore;
  try {
    routePointStore = await TripTrackingRoutePointStore.create();
  } catch (_) {
    routePointStore = TripTrackingRoutePointStore.unavailable();
  }
  final durableRecordStore = await MaintainiacDurableRecordStore.create(
    'maintainiac_durable_records',
  );
  final activeWorkdayContextHandoffs = ActiveWorkdayContextHandoffCoordinator(
    records: durableRecordStore,
    ports: ActiveWorkdayContextHandoffPorts(
      activeSession: () => activeWorkday.activeSession,
      applyWorkdayBoundary: (request) => activeWorkday.handoffContext(
        vehicleId: request.vehicleId,
        vehicleLabel: request.vehicleLabel,
        workProfileId: request.workProfileId,
        endingOdometer: request.endingOdometer,
        startingOdometer: request.startingOdometer,
        occurredAt: request.occurredAt,
      ),
      switchOdometerVehicle: (vehicleId) => globalOdometer.switchVehicleById(
        odometerVehicleIdForVehicleId(vehicleId),
      ),
      selectVehicle: (vehicleId) async {
        final vehicle = appState.vehicleById(vehicleId);
        if (vehicle == null || vehicle.isArchived) {
          throw StateError('The selected vehicle is not available.');
        }
        await appState.selectVehicle(vehicle);
      },
      selectWorkProfile: (profileId) async {
        final profile = expenseWorkProfiles.profileById(profileId);
        if (profile == null || profile.isArchived) {
          throw StateError('The selected work profile is not available.');
        }
        await expenseWorkProfiles.select(profile.id);
      },
      syncOperationalContext: (request) async {
        final vehicle = appState.vehicleById(request.vehicleId);
        final profile = expenseWorkProfiles.profileById(request.workProfileId);
        if (vehicle == null ||
            vehicle.isArchived ||
            profile == null ||
            profile.isArchived) {
          throw StateError('The selected work context is not available.');
        }
        await operationalContext.save(
          operationalContext.context.copyWith(
            activeVehicleId: globalOdometer.vehicleId,
            activeVehicleLabel: vehicle.nickname,
            activeVehicleUsage: vehicle.usage,
            workProfileId: profile.id,
            workProfileName: profile.name,
            updatedAt: DateTime.now(),
          ),
        );
      },
    ),
  );
  await activeWorkdayContextHandoffs.recoverPending();
  DashboardFirestoreMirror? dashboardMirror;
  if (firebaseSupported && userProfiles.activeProfile.id.trim().isNotEmpty) {
    final queueStore = await MaintainiacFirestoreUploadQueueStore.create();
    final uploadCoordinator = MaintainiacFirestoreUploadCoordinator(
      queue: queueStore,
      sink: FirebaseFirestoreDocumentSink(),
      uploadEnabled: true,
    );
    dashboardMirror = DashboardFirestoreMirror(
      queueStore: queueStore,
      uploadCoordinator: uploadCoordinator,
    );
  }
  final tripTracking = TripTrackingController(
    sessionStore: tripTrackingStore,
    odometer: globalOdometer,
    platform: TripTrackingPlatform(),
    routePointStore: routePointStore,
    routeSettings: () => tripTrackingSettings.settings,
    localRouteDayKey: tripTrackingLocalDayKey,
    activeVehicleConfigurationRevision: () =>
        appState.activeVehicle?.tireConfigurationRevision ?? 0,
    durableRecordBridge: TripTrackingDurableRecordBridge(durableRecordStore),
    tripLogProposalSink: tripLogProposalStore,
  );
  await tripTracking.restore();
  await tripTracking.retryPendingTripLogProposals();
  await tripTracking.applyGpsAssistanceConsent(
    enabled: tripTrackingSettings.settings.gpsAssistedTrackingEnabled,
  );
  await tripTracking.applyActiveTrackingSettings(tripTrackingSettings.settings);
  void syncTripGpsAssistanceConsent() {
    unawaited(
      tripTracking.applyGpsAssistanceConsent(
        enabled: tripTrackingSettings.settings.gpsAssistedTrackingEnabled,
      ),
    );
  }

  tripTrackingSettings.addListener(syncTripGpsAssistanceConsent);
  void syncActiveTripSettings() {
    unawaited(
      tripTracking.applyActiveTrackingSettings(tripTrackingSettings.settings),
    );
  }

  tripTrackingSettings.addListener(syncActiveTripSettings);
  void syncTripCalibrationAssist() {
    tripTracking.refreshGpsAssistanceCalibration(
      enabled:
          tripTrackingSettings.settings.gpsOdometerCalibrationAssistEnabled,
    );
  }

  syncTripCalibrationAssist();
  tripTrackingSettings.addListener(syncTripCalibrationAssist);
  TripTrackingBluetoothVehicleLinkStore bluetoothVehicleLinks;
  try {
    bluetoothVehicleLinks =
        await TripTrackingBluetoothVehicleLinkStore.create();
  } catch (_) {
    bluetoothVehicleLinks = TripTrackingBluetoothVehicleLinkStore.memory();
  }
  final bluetoothTripCoordinator = TripTrackingBluetoothCoordinator(
    linkStore: bluetoothVehicleLinks,
    settings: () => tripTrackingSettings.settings,
    hasActiveSession: () => tripTracking.isTracking,
    hasUnfinishedStoredSession: () => tripTracking.isTracking,
    currentVehicleId: () => globalOdometer.vehicleId,
    decisionResolver: (deviceId) =>
        tripTracking.evaluateBluetoothVehicleIdentity(
          deviceId: deviceId,
          settings: tripTrackingSettings.settings,
          linkStore: bluetoothVehicleLinks,
        ),
    switchVehicle: (vehicleId) async {
      final vehicle = appState.vehicleById(vehicleId);
      if (vehicle == null || vehicle.isArchived) return false;
      final switched = await globalOdometer.switchVehicleById(
        odometerVehicleIdForVehicleId(
          vehicle.id,
          fallbackLabel: vehicle.nickname,
        ),
      );
      if (!switched) return false;
      await appState.selectVehicle(vehicle);
      await operationalContext.setActiveVehicle(
        vehicleId: globalOdometer.vehicleId,
        vehicleLabel: vehicle.nickname,
        usage: vehicle.usage,
      );
      return true;
    },
  );
  final bluetoothTripRuntime = TripTrackingBluetoothRuntimeController(
    probe: DeviceCapabilityService.instance,
    coordinator: bluetoothTripCoordinator,
    linkStore: bluetoothVehicleLinks,
    requestObservationAccess: Platform.isAndroid
        ? DeviceCapabilityService.instance.requestBluetoothConnectionAccess
        : null,
  );
  final activeDashboardMirror = dashboardMirror;
  if (activeDashboardMirror != null) {
    final dashboardReporter = DashboardTripTrackingSummaryReporter(
      mirror: activeDashboardMirror,
      settingsController: tripTrackingSettings,
      uid: () => FirebaseAuth.instance.currentUser?.uid,
      dashboardId: () => 'active_dashboard',
      orgId: () => operationalContext.context.companyId,
      activeVehicleId: () => operationalContext.context.activeVehicleId,
      activeWorkdayId: () => activeWorkday.activeSession?.id,
      activeWorkProfileId: () => operationalContext.context.workProfileId,
      tripTracking: tripTracking,
      activeWorkday: activeWorkday,
      storageReader: () =>
          AppStorageGuard.check(AppStoragePurpose.mileageTracking),
      deviceCapabilityProfile: () => DeviceCapabilityService.instance.profile(),
    );
    Future<void> queueDashboardTripSummary() async {
      await dashboardReporter.queueNow();
    }

    unawaited(queueDashboardTripSummary());
    tripTracking.addListener(() {
      unawaited(queueDashboardTripSummary());
    });
    globalOdometer.addListener(() {
      unawaited(queueDashboardTripSummary());
    });
    tripTrackingSettings.addListener(() {
      unawaited(queueDashboardTripSummary());
    });
    activeWorkday.addListener(() {
      unawaited(queueDashboardTripSummary());
    });
    operationalContext.addListener(() {
      unawaited(queueDashboardTripSummary());
    });
  }
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(maintaniacSystemUiStyle);
  runApp(
    AppStateScope(
      controller: appState,
      child: ExpenseSettingsScope(
        controller: expenseSettings,
        child: ExpenseCloudBackupScope(
          mirror: expenseCloudBackup,
          child: ExpenseReminderScope(
            controller: expenseReminders,
            child: ExpenseWorkProfileScope(
              controller: expenseWorkProfiles,
              child: MaintainiacJobScope(
                controller: jobs,
                child: ExpenseLedgerScope(
                  controller: expenseLedger,
                  child: ExpenseDraftScope(
                    controller: expenseDrafts,
                    child: ExpenseExportScope(
                      controller: expenseExports,
                      child: ReceiptCaptureSettingsScope(
                        controller: receiptCaptureSettings,
                        child: ActiveWorkdayContextHandoffScope(
                          coordinator: activeWorkdayContextHandoffs,
                          child: ActiveWorkdayScope(
                            controller: activeWorkday,
                            child: WorkdayQuickActionLayoutScope(
                              controller: quickActionLayout,
                              child: GlobalOdometerScope(
                                controller: globalOdometer,
                                child: TripTrackingSettingsScope(
                                  controller: tripTrackingSettings,
                                  child: TripTrackingScope(
                                    controller: tripTracking,
                                    child: IncomingReceiptShareScope(
                                      controller: incomingReceiptShare,
                                      child: AppSignatureStoreScope(
                                        store: signatureStore,
                                        child: UserProfileScope(
                                          controller: userProfiles,
                                          child: EmployeeWorkTimeScope(
                                            controller: employeeWorkTime,
                                            child: OperationalContextScope(
                                              controller: operationalContext,
                                              child: InvoiceLedgerScope(
                                                controller: invoiceLedger,
                                                child: MaintaniacApp(
                                                  bluetoothTripRuntime:
                                                      bluetoothTripRuntime,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
