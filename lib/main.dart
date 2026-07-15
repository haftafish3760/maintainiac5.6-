import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/maintaniac_app.dart';
import 'screens/dashboard/data/active_workday_store.dart';
import 'screens/expenses/data/expense_draft_store.dart';
import 'screens/expenses/data/expense_export_store.dart';
import 'screens/expenses/data/expense_ledger_store.dart';
import 'screens/expenses/data/expense_job_store.dart';
import 'screens/expenses/data/expense_reminder_store.dart';
import 'screens/expenses/data/expense_work_profile_store.dart';
import 'screens/expenses/data/expense_vehicle_profile_store.dart';
import 'screens/expenses/data/expense_receipt_deletion_store.dart';
import 'screens/invoices/data/invoice_ledger_store.dart';
import 'shared/state/app_state.dart';
import 'shared/state/expense_settings_store.dart';
import 'shared/firebase/maintainiac_firebase.dart';
import 'shared/context/operational_context_store.dart';
import 'shared/profiles/user_profile_store.dart';
import 'shared/signatures/app_signature_store.dart';
import 'shared/state/global_odometer.dart';
import 'shared/odometer/odometer_store.dart';
import 'shared/odometer/odometer_vehicle_snapshot.dart';
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
  await MaintainiacFirebase.initializeIfSupported();
  await Hive.initFlutter();
  final expenseSettings = await ExpenseSettingsController.create();
  final expenseLedger = await ExpenseLedgerController.create();
  final expenseJobs = await ExpenseJobController.create();
  final expenseReminders = await ExpenseReminderController.create();
  final expenseWorkProfiles = await ExpenseWorkProfileController.create();
  final expenseVehicleProfiles = await ExpenseVehicleProfileController.create();
  final expenseReceiptDeletions =
      await ExpenseReceiptDeletionController.create();
  final expenseDrafts = await ExpenseDraftController.create();
  final expenseExports = await ExpenseExportController.create();
  final receiptCaptureSettings =
      await ReceiptCaptureSettingsController.create();
  final signatureStore = await AppSignatureStore.create();
  final invoiceLedger = await InvoiceLedgerStore.create();
  final userProfiles = await UserProfileController.create();
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
  final odometerStore = await OdometerStore.create();
  final appState = AppStateController();
  final activeVehicleId = odometerVehicleIdForLabel(
    appState.activeVehicle?.nickname,
  );
  await expenseVehicleProfiles.ensureProfile(
    id: activeVehicleId,
    nickname: appState.activeVehicle?.nickname ?? 'Default vehicle',
    year: appState.activeVehicle?.year ?? '',
    make: appState.activeVehicle?.make ?? '',
    model: appState.activeVehicle?.model ?? '',
    usage: appState.activeVehicle?.usage ?? VehicleUsage.businessPersonal,
  );
  final operationalContext = await OperationalContextController.create(
    profile: userProfiles.activeProfile,
    activeVehicleId: activeVehicleId,
    activeVehicleLabel: appState.activeVehicle?.nickname ?? 'Active vehicle',
    activeVehicleUsage:
        appState.activeVehicle?.usage ?? VehicleUsage.businessPersonal,
  );
  await expenseWorkProfiles.ensureProfile(
    id: operationalContext.context.workProfileId,
    name: operationalContext.context.workProfileName,
  );
  appState.setWorkProfile(operationalContext.context.workProfileName);
  final odometerSnapshot = odometerStore.snapshotForVehicle(activeVehicleId);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(maintaniacSystemUiStyle);
  runApp(
    AppStateScope(
      controller: appState,
      child: ExpenseSettingsScope(
        controller: expenseSettings,
        child: ExpenseLedgerScope(
          controller: expenseLedger,
          child: ExpenseWorkProfileScope(
            controller: expenseWorkProfiles,
            child: ExpenseVehicleProfileScope(
              controller: expenseVehicleProfiles,
              child: ExpenseReceiptDeletionScope(
                controller: expenseReceiptDeletions,
                child: ExpenseJobScope(
                  controller: expenseJobs,
                  child: ExpenseReminderScope(
                    controller: expenseReminders,
                    child: ExpenseDraftScope(
                      controller: expenseDrafts,
                      child: ExpenseExportScope(
                        controller: expenseExports,
                        child: ReceiptCaptureSettingsScope(
                          controller: receiptCaptureSettings,
                          child: ActiveWorkdayScope(
                            controller: activeWorkday,
                            child: GlobalOdometerScope(
                              controller: GlobalOdometerController(
                                vehicleId: odometerSnapshot.vehicleId,
                                initialReading: odometerSnapshot.currentReading,
                                initialRecordedAt: odometerSnapshot.updatedAt,
                                initialHistory: odometerSnapshot.history,
                                snapshotReader:
                                    odometerStore.loadSnapshotForVehicle,
                                snapshotWriter: odometerStore.saveSnapshot,
                              ),
                              child: IncomingReceiptShareScope(
                                controller: incomingReceiptShare,
                                child: AppSignatureStoreScope(
                                  store: signatureStore,
                                  child: UserProfileScope(
                                    controller: userProfiles,
                                    child: OperationalContextScope(
                                      controller: operationalContext,
                                      child: InvoiceLedgerScope(
                                        controller: invoiceLedger,
                                        child: const MaintaniacApp(),
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
