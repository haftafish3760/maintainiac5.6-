import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/state/app_state.dart';
import '../../shared/state/global_odometer.dart';
import 'data/maintenance_receipt_parser.dart';
import 'data/maintenance_receipt_application_service.dart';
import 'data/maintenance_receipt_review.dart';
import 'maintenance_draft_store.dart';
import 'maintenance_receipt_apply_dialog.dart';
import 'maintenance_receipt_review_screen.dart';

/// Maintenance-owned boundary for source-faithful text produced elsewhere.
///
/// Camera and OCR code should only supply text to this function. This function
/// does not retain the raw text, write maintenance, or update the odometer.
Future<MaintenanceReceiptReviewOutcome?> openMaintenanceReceiptTextReview(
  BuildContext context, {
  required String sourceText,
  String locale = 'en-US',
}) async {
  final state = AppStateScope.of(context);
  final vehicle = state.activeVehicle;
  if (vehicle == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Select a vehicle before reviewing a maintenance receipt.',
        ),
      ),
    );
    return null;
  }
  final odometer = GlobalOdometerScope.of(context);
  final parserResult = parseMaintenanceReceipt(
    MaintenanceReceiptParserInput(
      sourceText: sourceText,
      activeVehicleId: vehicle.id,
      activeVehicleName: vehicle.nickname,
      currentOdometer: odometer.reading,
      locale: locale,
      referenceDate: DateTime.now(),
    ),
  );
  MaintenanceReceiptReview? initialReview;
  try {
    final stored = await MaintenanceDraftStore.loadReceiptReviewDraft(
      vehicleId: vehicle.id,
      sourceFingerprintSha256: parserResult.sourceFingerprintSha256,
    );
    final payload = stored?['review'];
    if (payload is Map) {
      final restored = MaintenanceReceiptReview.fromDraftJson(payload);
      if (restored.parserResult.activeVehicleId == vehicle.id &&
          restored.parserResult.sourceFingerprintSha256 ==
              parserResult.sourceFingerprintSha256) {
        initialReview = restored;
      }
    }
  } on Object catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved receipt review could not be read: $error'),
        ),
      );
    }
  }
  if (!context.mounted) return null;
  return Navigator.of(context).push<MaintenanceReceiptReviewOutcome>(
    appNativeRoute<MaintenanceReceiptReviewOutcome>(
      context,
      MaintenanceReceiptReviewScreen(
        parserResult: parserResult,
        initialReview: initialReview,
      ),
    ),
  );
}

/// Full maintenance-owned flow for a future OCR/text handoff.
///
/// Review remains mutation-free. A second explicit confirmation applies the
/// commands atomically, and cancellation preserves the local review draft.
Future<MaintenanceReceiptApplicationResult?>
openMaintenanceReceiptTextReviewAndConfirm(
  BuildContext context, {
  required String sourceText,
  String locale = 'en-US',
}) async {
  final outcome = await openMaintenanceReceiptTextReview(
    context,
    sourceText: sourceText,
    locale: locale,
  );
  if (outcome == null || !context.mounted) return null;
  return confirmAndApplyMaintenanceReceiptOutcome(context, outcome: outcome);
}
