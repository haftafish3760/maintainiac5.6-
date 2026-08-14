part of 'maintenance_receipt_review.dart';

MaintenanceReceiptReview createMaintenanceReceiptReview({
  required MaintenanceReceiptParserResult parserResult,
  required int? currentOdometer,
}) {
  return MaintenanceReceiptReview(
    parserResult: parserResult,
    currentOdometer: currentOdometer,
    items: List.unmodifiable([
      for (final candidate in parserResult.candidates)
        createMaintenanceReceiptReviewItem(candidate),
    ]),
  );
}

MaintenanceReceiptReviewItem createMaintenanceReceiptReviewItem(
  MaintenanceReceiptCandidate candidate,
) {
  return MaintenanceReceiptReviewItem(
    source: candidate,
    intervalMiles: _catalogIntervalMiles(candidate.itemName),
    intervalMonths: _catalogIntervalMonths(candidate.itemName),
  );
}

int? _catalogIntervalMiles(String itemName) {
  final item = maintenanceReceiptCatalogItem(itemName);
  final miles = item?.defaultMiles;
  return miles == null || miles <= 0 ? null : miles;
}

int? _catalogIntervalMonths(String itemName) {
  final item = maintenanceReceiptCatalogItem(itemName);
  return item?.defaultMonths;
}

MaintenanceCatalogItem? maintenanceReceiptCatalogItem(String itemName) {
  final normalizedName = itemName.trim().toLowerCase();
  for (final item in maintenanceCatalog) {
    if (item.name.toLowerCase() == normalizedName) return item;
  }
  return null;
}

MaintenanceReceiptReviewOutcome buildMaintenanceReceiptCommands(
  MaintenanceReceiptReview review,
) {
  final issues = <MaintenanceReceiptReviewIssue>[];
  final commands = <MaintenanceReceiptConfirmedCommand>[];
  final vehicleId = review.parserResult.activeVehicleId.trim();

  for (var index = 0; index < review.items.length; index++) {
    final item = review.items[index];
    final decision = item.decision;
    if (decision == MaintenanceReceiptReviewDecision.undecided) {
      issues.add(
        MaintenanceReceiptReviewIssue(
          code: 'decision_required',
          message: 'Choose what to do with ${item.effectiveItemName}.',
          itemIndex: index,
        ),
      );
      continue;
    }
    if (decision == MaintenanceReceiptReviewDecision.ignore ||
        decision == MaintenanceReceiptReviewDecision.expenseOnly) {
      continue;
    }
    if (vehicleId.isEmpty) {
      issues.add(
        MaintenanceReceiptReviewIssue(
          code: 'vehicle_required',
          message: 'Select a vehicle before applying maintenance.',
          itemIndex: index,
        ),
      );
      continue;
    }
    if (item.effectiveItemName.isEmpty) {
      issues.add(
        MaintenanceReceiptReviewIssue(
          code: 'item_name_required',
          message: 'Enter the maintenance item name.',
          itemIndex: index,
        ),
      );
      continue;
    }

    final setup =
        decision == MaintenanceReceiptReviewDecision.setupOnly ||
        decision == MaintenanceReceiptReviewDecision.setupAndService;
    final service =
        decision == MaintenanceReceiptReviewDecision.serviceOnly ||
        decision == MaintenanceReceiptReviewDecision.setupAndService;
    if (setup &&
        (item.effectiveIntervalMiles == null ||
            item.effectiveIntervalMiles! <= 0) &&
        (item.effectiveIntervalMonths == null ||
            item.effectiveIntervalMonths! <= 0)) {
      issues.add(
        MaintenanceReceiptReviewIssue(
          code: 'maintenance_interval_required',
          message:
              'Enter a mileage or time interval before setting up tracking.',
          itemIndex: index,
        ),
      );
      continue;
    }
    if (item.source.returnOrExchangeIndicated &&
        !item.confirmedReturnOrExchangeResolved) {
      issues.add(
        MaintenanceReceiptReviewIssue(
          code: 'return_resolution_required',
          message:
              'Confirm what was ultimately kept or installed after the return or exchange.',
          itemIndex: index,
        ),
      );
      continue;
    }
    if (service &&
        item.source.notCompletedIndicated &&
        !item.confirmedWorkWasCompleted) {
      issues.add(
        MaintenanceReceiptReviewIssue(
          code: 'completed_work_confirmation_required',
          message:
              'Confirm the work was completed despite the estimate, recommendation, or declined-work language.',
          itemIndex: index,
        ),
      );
      continue;
    }
    if (service &&
        item.source.productPurchased &&
        !item.source.completedServiceIndicated &&
        !item.confirmedPurchasedItemWasInstalled) {
      issues.add(
        MaintenanceReceiptReviewIssue(
          code: 'installation_confirmation_required',
          message:
              'Confirm that the purchased ${item.effectiveItemName} was installed.',
          itemIndex: index,
        ),
      );
      continue;
    }
    if (service && item.effectiveServiceDate == null) {
      issues.add(
        MaintenanceReceiptReviewIssue(
          code: 'service_date_required',
          message: 'Enter the completed service date.',
          itemIndex: index,
        ),
      );
      continue;
    }
    final serviceOdometer = item.effectiveServiceOdometer;
    if (service && serviceOdometer != null && serviceOdometer < 0) {
      issues.add(
        MaintenanceReceiptReviewIssue(
          code: 'invalid_service_odometer',
          message: 'The service odometer cannot be negative.',
          itemIndex: index,
        ),
      );
      continue;
    }
    if (service &&
        serviceOdometer != null &&
        review.currentOdometer != null &&
        serviceOdometer > review.currentOdometer! &&
        !item.confirmedOdometerConflict) {
      issues.add(
        MaintenanceReceiptReviewIssue(
          code: 'odometer_conflict_confirmation_required',
          message:
              'Confirm the receipt odometer before using a value above the current vehicle odometer.',
          itemIndex: index,
        ),
      );
      continue;
    }

    commands.add(
      MaintenanceReceiptConfirmedCommand(
        vehicleId: vehicleId,
        vehicleName: review.parserResult.activeVehicleName.trim(),
        commandId: maintenanceReceiptCommandId(
          sourceFingerprint: review.parserResult.sourceFingerprintSha256,
          parserSchemaVersion: MaintenanceReceiptParserResult.schemaVersion,
          vehicleId: vehicleId,
          candidateIndex: index,
          itemName: item.effectiveItemName,
          decision: decision,
          setupMode: item.setupMode,
          merchantName: review.parserResult.merchantName,
          detailA: item.effectiveDetailA,
          detailB: item.effectiveDetailB,
          serviceDate: service ? item.effectiveServiceDate : null,
          serviceOdometer: service ? serviceOdometer : null,
          intervalMiles: item.effectiveIntervalMiles,
          intervalMonths: item.effectiveIntervalMonths,
        ),
        sourceFingerprintSha256: review.parserResult.sourceFingerprintSha256,
        parserSchemaVersion: MaintenanceReceiptParserResult.schemaVersion,
        candidateIndex: index,
        decision: decision,
        setupMode: item.setupMode,
        itemName: item.effectiveItemName,
        setupTracking: setup,
        logCompletedService: service,
        merchantName: review.parserResult.merchantName,
        evidenceLineNumbers: List.unmodifiable(
          item.source.evidence.map((evidence) => evidence.lineNumber).toSet(),
        ),
        detailA: item.effectiveDetailA,
        detailB: item.effectiveDetailB,
        serviceDate: service ? item.effectiveServiceDate : null,
        serviceOdometer: service ? serviceOdometer : null,
        intervalMiles: item.effectiveIntervalMiles,
        intervalMonths: item.effectiveIntervalMonths,
      ),
    );
  }

  return MaintenanceReceiptReviewOutcome(
    issues: List.unmodifiable(issues),
    commands: issues.isEmpty
        ? List.unmodifiable(commands)
        : const <MaintenanceReceiptConfirmedCommand>[],
    vehicleId: vehicleId,
    sourceFingerprintSha256: review.parserResult.sourceFingerprintSha256,
  );
}
