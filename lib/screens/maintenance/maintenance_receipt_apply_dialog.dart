import 'package:flutter/material.dart';

import '../../shared/state/app_state.dart';
import 'data/maintenance_receipt_application_service.dart';
import 'data/maintenance_receipt_review.dart';
import 'maintenance_draft_store.dart';

/// Explicit final consent boundary between receipt review and durable writes.
///
/// Cancel leaves the safe local review draft available. A successful,
/// idempotent durable application clears that exact vehicle/fingerprint draft.
Future<MaintenanceReceiptApplicationResult?>
confirmAndApplyMaintenanceReceiptOutcome(
  BuildContext context, {
  required MaintenanceReceiptReviewOutcome outcome,
}) async {
  final setupCount = outcome.commands
      .where((command) => command.setupTracking)
      .length;
  final serviceCount = outcome.commands
      .where((command) => command.logCompletedService)
      .length;
  final confirmed =
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Save reviewed maintenance?'),
          content: Text(
            [
              if (setupCount > 0)
                '$setupCount item${setupCount == 1 ? '' : 's'} to track',
              if (serviceCount > 0)
                '$serviceCount completed service '
                    'record${serviceCount == 1 ? '' : 's'}',
              if (setupCount == 0 && serviceCount == 0)
                'No maintenance records will be added.',
              'The vehicle odometer will not be changed.',
            ].join('\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Reviewing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save Maintenance'),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed || !context.mounted) return null;

  try {
    final result = await applyMaintenanceReceiptOutcome(
      state: AppStateScope.of(context),
      outcome: outcome,
    );
    if (!context.mounted) return result;
    if (!result.isApplied) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.issues.first.message)));
      return result;
    }
    await MaintenanceDraftStore.clearReceiptReviewDraft(
      vehicleId: outcome.vehicleId,
      sourceFingerprintSha256: outcome.sourceFingerprintSha256,
    );
    if (!context.mounted) return result;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.recordsAdded == 0 && result.eventsAdded == 0
              ? 'This reviewed receipt was already applied.'
              : 'Reviewed maintenance was saved locally.',
        ),
      ),
    );
    return result;
  } on StateError catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
    return null;
  }
}
