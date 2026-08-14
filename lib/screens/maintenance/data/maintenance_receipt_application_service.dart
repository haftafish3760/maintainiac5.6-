import '../../../shared/state/app_state.dart';
import 'maintenance_receipt_parser.dart';
import 'maintenance_receipt_review.dart';

class MaintenanceReceiptApplicationIssue {
  const MaintenanceReceiptApplicationIssue({
    required this.code,
    required this.message,
    this.commandId,
  });

  final String code;
  final String message;
  final String? commandId;
}

class MaintenanceReceiptApplicationResult {
  const MaintenanceReceiptApplicationResult({
    required this.issues,
    required this.recordsAdded,
    required this.eventsAdded,
  });

  final List<MaintenanceReceiptApplicationIssue> issues;
  final int recordsAdded;
  final int eventsAdded;

  bool get isApplied => issues.isEmpty;
}

/// Validates and atomically commits user-confirmed receipt commands.
///
/// This layer never changes global odometer state and never stores raw receipt
/// text. Exact retries are idempotent through record natural keys and command
/// IDs used as service-event IDs.
Future<MaintenanceReceiptApplicationResult> applyMaintenanceReceiptOutcome({
  required AppStateController state,
  required MaintenanceReceiptReviewOutcome outcome,
}) async {
  final issues = <MaintenanceReceiptApplicationIssue>[];
  final activeVehicle = state.activeVehicle;
  if (!outcome.isValid) {
    issues.add(
      const MaintenanceReceiptApplicationIssue(
        code: 'review_not_valid',
        message: 'Resolve every receipt review issue before applying it.',
      ),
    );
  }
  if (activeVehicle == null) {
    issues.add(
      const MaintenanceReceiptApplicationIssue(
        code: 'active_vehicle_required',
        message: 'Select the receipt vehicle before applying maintenance.',
      ),
    );
  } else if (outcome.vehicleId.trim() != activeVehicle.id) {
    issues.add(
      const MaintenanceReceiptApplicationIssue(
        code: 'active_vehicle_changed',
        message: 'The active vehicle changed after this receipt was reviewed.',
      ),
    );
  }
  if (!_isSha256(outcome.sourceFingerprintSha256.trim().toLowerCase())) {
    issues.add(
      const MaintenanceReceiptApplicationIssue(
        code: 'invalid_source_fingerprint',
        message: 'The receipt source identity is invalid.',
      ),
    );
  }

  final commandIds = <String>{};
  for (final command in outcome.commands) {
    final catalogItem = maintenanceReceiptCatalogItem(command.itemName);
    final commandId = command.commandId.trim().toLowerCase();
    final fingerprint = command.sourceFingerprintSha256.trim().toLowerCase();
    if (activeVehicle != null && command.vehicleId.trim() != activeVehicle.id) {
      issues.add(
        MaintenanceReceiptApplicationIssue(
          code: 'active_vehicle_changed',
          message:
              'The active vehicle changed after this receipt was reviewed.',
          commandId: commandId,
        ),
      );
    }
    if (command.vehicleId.trim() != outcome.vehicleId.trim() ||
        fingerprint != outcome.sourceFingerprintSha256.trim().toLowerCase()) {
      issues.add(
        MaintenanceReceiptApplicationIssue(
          code: 'receipt_identity_mismatch',
          message: 'The receipt command does not match its reviewed source.',
          commandId: commandId,
        ),
      );
    }
    if (!_isSha256(commandId) || !commandIds.add(commandId)) {
      issues.add(
        MaintenanceReceiptApplicationIssue(
          code: 'invalid_command_id',
          message: 'The receipt command identity is invalid or duplicated.',
          commandId: commandId,
        ),
      );
    }
    final decisionMatches = switch (command.decision) {
      MaintenanceReceiptReviewDecision.setupOnly =>
        command.setupTracking && !command.logCompletedService,
      MaintenanceReceiptReviewDecision.serviceOnly =>
        !command.setupTracking && command.logCompletedService,
      MaintenanceReceiptReviewDecision.setupAndService =>
        command.setupTracking && command.logCompletedService,
      _ => false,
    };
    final expectedCommandId = command.candidateIndex < 0
        ? ''
        : maintenanceReceiptCommandId(
            sourceFingerprint: command.sourceFingerprintSha256,
            parserSchemaVersion: command.parserSchemaVersion,
            vehicleId: command.vehicleId,
            candidateIndex: command.candidateIndex,
            itemName: command.itemName,
            decision: command.decision,
            setupMode: command.setupMode,
            merchantName: command.merchantName,
            detailA: command.detailA,
            detailB: command.detailB,
            serviceDate: command.serviceDate,
            serviceOdometer: command.serviceOdometer,
            intervalMiles: command.intervalMiles,
            intervalMonths: command.intervalMonths,
          );
    if (!decisionMatches || commandId != expectedCommandId) {
      issues.add(
        MaintenanceReceiptApplicationIssue(
          code: 'command_integrity_failed',
          message:
              'The confirmed receipt command changed after review; review it again.',
          commandId: commandId,
        ),
      );
    }
    if (command.setupMode == MaintenanceReceiptSetupMode.basic &&
        (command.detailA != null || command.detailB != null)) {
      issues.add(
        MaintenanceReceiptApplicationIssue(
          code: 'basic_setup_contains_advanced_details',
          message:
              'Basic maintenance setup cannot save product-specific details.',
          commandId: commandId,
        ),
      );
    }
    if (!_isSha256(fingerprint)) {
      issues.add(
        MaintenanceReceiptApplicationIssue(
          code: 'invalid_source_fingerprint',
          message: 'The receipt source identity is invalid.',
          commandId: commandId,
        ),
      );
    }
    if (command.parserSchemaVersion !=
        MaintenanceReceiptParserResult.schemaVersion) {
      issues.add(
        MaintenanceReceiptApplicationIssue(
          code: 'unsupported_parser_schema',
          message: 'Review this receipt again with the current parser.',
          commandId: commandId,
        ),
      );
    }
    if (command.itemName.trim().isEmpty ||
        (!command.setupTracking && !command.logCompletedService)) {
      issues.add(
        MaintenanceReceiptApplicationIssue(
          code: 'invalid_maintenance_action',
          message: 'The confirmed maintenance action is incomplete.',
          commandId: commandId,
        ),
      );
    }
    if ((command.intervalMiles != null && command.intervalMiles! <= 0) ||
        (command.intervalMonths != null && command.intervalMonths! <= 0)) {
      issues.add(
        MaintenanceReceiptApplicationIssue(
          code: 'invalid_interval',
          message: 'Maintenance intervals must be greater than zero.',
          commandId: commandId,
        ),
      );
    }
    final serviceOdometerRequired = catalogItem?.timeOnly != true;
    if (command.logCompletedService &&
        (command.serviceDate == null ||
            (serviceOdometerRequired && command.serviceOdometer == null))) {
      issues.add(
        MaintenanceReceiptApplicationIssue(
          code: 'service_evidence_required',
          message: serviceOdometerRequired
              ? 'A completed service needs a confirmed date and odometer before it can be saved.'
              : 'A completed time-only service needs a confirmed date before it can be saved.',
          commandId: commandId,
        ),
      );
    }
    if (command.logCompletedService &&
        command.serviceDate != null &&
        state.maintenanceEvents.any(
          (event) =>
              event.eventId.trim().toLowerCase() != commandId &&
              event.vehicleId == command.vehicleId &&
              event.itemName.trim().toLowerCase() ==
                  command.itemName.trim().toLowerCase() &&
              _sameCalendarDate(event.serviceDate, command.serviceDate!) &&
              (command.serviceOdometer == null ||
                  event.odometer == command.serviceOdometer),
        )) {
      issues.add(
        MaintenanceReceiptApplicationIssue(
          code: 'possible_duplicate_service_event',
          message:
              'A matching service already exists for this vehicle, item, date, and odometer.',
          commandId: commandId,
        ),
      );
    }
  }

  if (issues.isNotEmpty || activeVehicle == null) {
    return MaintenanceReceiptApplicationResult(
      issues: List.unmodifiable(issues),
      recordsAdded: 0,
      eventsAdded: 0,
    );
  }

  final recordsBefore = state.maintenance.length;
  final eventsBefore = state.maintenanceEvents.length;
  final records = <MaintenanceRecord>[];
  final events = <MaintenanceServiceEvent>[];
  for (final command in outcome.commands) {
    if (command.setupTracking) {
      final catalogItem = maintenanceReceiptCatalogItem(command.itemName);
      records.add(
        MaintenanceRecord(
          itemName: command.itemName.trim(),
          vehicleId: activeVehicle.id,
          vehicleName: activeVehicle.nickname,
          intervalMiles: command.intervalMiles ?? 0,
          milesSinceService: 0,
          intervalMonths: command.intervalMonths ?? 0,
          monthsSinceService: 0,
          importance: catalogItem?.importance ?? 100,
          detailA: command.detailA?.trim() ?? '',
          detailB: command.detailB?.trim() ?? '',
          setupComplete: false,
          timeOnly: catalogItem?.timeOnly ?? false,
          sourceCommandId: command.commandId,
          sourceReceiptFingerprint: command.sourceFingerprintSha256,
          sourceParserSchemaVersion: command.parserSchemaVersion,
        ),
      );
    }
    if (command.logCompletedService) {
      events.add(
        MaintenanceServiceEvent(
          eventId: command.commandId.trim().toLowerCase(),
          itemName: command.itemName.trim(),
          vehicleId: activeVehicle.id,
          vehicleName: activeVehicle.nickname,
          serviceDate: command.serviceDate!,
          odometer: command.serviceOdometer ?? 0,
          provider: command.merchantName.trim(),
          notes: 'Confirmed from maintenance receipt review.',
          sourceCommandId: command.commandId,
          sourceReceiptFingerprint: command.sourceFingerprintSha256,
          sourceParserSchemaVersion: command.parserSchemaVersion,
        ),
      );
    }
  }

  await state.applyMaintenanceTransaction(records: records, events: events);
  return MaintenanceReceiptApplicationResult(
    issues: const [],
    recordsAdded: state.maintenance.length - recordsBefore,
    eventsAdded: state.maintenanceEvents.length - eventsBefore,
  );
}

bool _isSha256(String value) => RegExp(r'^[a-f0-9]{64}$').hasMatch(value);

bool _sameCalendarDate(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
