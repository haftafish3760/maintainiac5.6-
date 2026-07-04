part of 'receipt_qa_runner.dart';

List<_ReceiptQaCheck> _buildReceiptQaChecks({
  required _ReceiptQaFixture fixture,
  required ExpenseReceiptParseResult parsed,
  required ReceiptTextQualitySignals signals,
  required ExpenseReceiptLineRecord? fuelLine,
  required ExpenseReceiptMaintenanceHint? maintenanceHint,
  required bool hasExpectedBottomCoverage,
  required bool hasExpectedDate,
  required bool hasExpectedFuel,
  required bool hasExpectedTax,
  required bool hasExpectedTotal,
  required bool hasLineItemAmount,
  required bool hasMaintenanceInterval,
  required bool hasMaintenanceSignal,
}) {
  final checks = <_ReceiptQaCheck>[];

  void addCheck(String dimension, String name, bool passed) {
    checks.add(
      _ReceiptQaCheck(dimension: dimension, name: name, passed: passed),
    );
  }

  addCheck('capture', 'bottom_total_coverage', hasExpectedBottomCoverage);
  addCheck('ocr_text', 'merchant_present', signals.hasMerchant);
  addCheck('ocr_text', 'date_expectation_met', hasExpectedDate);
  addCheck('ocr_text', 'total_expectation_met', hasExpectedTotal);
  addCheck(
    'production_parser',
    'merchant_matched',
    _matchesMerchant(parsed.merchantName, fixture.merchantNeedle),
  );
  if (fixture.expectedMerchantName != null) {
    addCheck(
      'production_parser',
      'merchant_name_matched',
      parsed.merchantName == fixture.expectedMerchantName,
    );
  }
  addCheck(
    'production_parser',
    'date_expectation_met',
    !fixture.expectDate || parsed.receiptDate != null,
  );
  addCheck(
    'production_parser',
    'total_expectation_met',
    !fixture.expectTotal || parsed.enteredTotal != null,
  );
  addCheck(
    'business_personal',
    'line_allocation_reconciles',
    _lineAllocationReconciles(parsed),
  );
  _addBusinessReviewChecks(fixture: fixture, parsed: parsed, checks: checks);
  if (fixture.expectFuel) {
    addCheck('parser', 'fuel_quantity_ready', hasExpectedFuel);
    addCheck('production_parser', 'fuel_line_parsed', fuelLine != null);
  }
  if (fixture.expectedFuelQuantity != null) {
    addCheck(
      'production_parser',
      'fuel_quantity_matched',
      _nearMoney(fuelLine?.quantity, fixture.expectedFuelQuantity!),
    );
  }
  if (fixture.expectedFuelUnitPrice != null) {
    addCheck(
      'production_parser',
      'fuel_unit_price_matched',
      _nearMoney(fuelLine?.unitPrice, fixture.expectedFuelUnitPrice!),
    );
  }
  if (fixture.expectedFuelType != null) {
    addCheck(
      'production_parser',
      'fuel_type_matched',
      fuelLine?.fuelType == fixture.expectedFuelType,
    );
  }
  if (fixture.expectedFuelUnit != null) {
    addCheck(
      'production_parser',
      'fuel_unit_matched',
      fuelLine?.unit == fixture.expectedFuelUnit,
    );
  }
  if (fixture.expectedFuelOdometer != null) {
    addCheck(
      'production_parser',
      'fuel_odometer_matched',
      fuelLine?.odometerReading == fixture.expectedFuelOdometer,
    );
  }
  if (fixture.expectedMaintenanceServiceType != null) {
    addCheck(
      'maintenance',
      'maintenance_service_type_matched',
      maintenanceHint?.serviceType == fixture.expectedMaintenanceServiceType,
    );
  }
  if (fixture.expectedMaintenanceOilWeight != null) {
    addCheck(
      'maintenance',
      'maintenance_oil_weight_matched',
      maintenanceHint?.oilWeight == fixture.expectedMaintenanceOilWeight,
    );
  }
  if (fixture.expectedMaintenanceServiceOdometer != null) {
    addCheck(
      'maintenance',
      'maintenance_service_odometer_matched',
      maintenanceHint?.serviceOdometer ==
          fixture.expectedMaintenanceServiceOdometer,
    );
  }
  if (fixture.expectedMaintenanceDueOdometer != null) {
    addCheck(
      'maintenance',
      'maintenance_due_odometer_matched',
      maintenanceHint?.dueOdometer == fixture.expectedMaintenanceDueOdometer,
    );
  }
  if (fixture.expectedMaintenanceIntervalMiles != null) {
    addCheck(
      'maintenance',
      'maintenance_interval_miles_matched',
      maintenanceHint?.intervalMiles ==
          fixture.expectedMaintenanceIntervalMiles,
    );
  }
  if (fixture.expectedMaintenanceIntervalMonths != null) {
    addCheck(
      'maintenance',
      'maintenance_interval_months_matched',
      maintenanceHint?.intervalMonths ==
          fixture.expectedMaintenanceIntervalMonths,
    );
  }
  if (fixture.expectTax) addCheck('parser', 'tax_ready', hasExpectedTax);
  if (fixture.expectedDateIso != null) {
    addCheck(
      'production_parser',
      'date_value_matched',
      _dateIso(parsed.receiptDate) == fixture.expectedDateIso,
    );
  }
  if (fixture.expectedSubtotal != null) {
    addCheck(
      'production_parser',
      'subtotal_value_matched',
      _nearMoney(parsed.enteredSubtotal, fixture.expectedSubtotal!),
    );
  }
  if (fixture.expectedTax != null) {
    addCheck(
      'production_parser',
      'tax_value_matched',
      _nearMoney(parsed.enteredTax, fixture.expectedTax!),
    );
  }
  if (fixture.expectedTotal != null) {
    addCheck(
      'production_parser',
      'total_value_matched',
      _nearMoney(parsed.enteredTotal, fixture.expectedTotal!),
    );
  }
  if (fixture.expectLineItems) {
    addCheck('parser', 'line_item_amount_ready', hasLineItemAmount);
    addCheck('production_parser', 'line_items_parsed', parsed.lines.isNotEmpty);
  }
  if (fixture.expectedLineCount != null) {
    addCheck(
      'production_parser',
      'line_count_matched',
      parsed.lines.length == fixture.expectedLineCount,
    );
  }
  if (fixture.expectedLineSubtotals.isNotEmpty) {
    addCheck(
      'production_parser',
      'line_subtotals_matched',
      _lineSubtotalsMatch(parsed.lines, fixture.expectedLineSubtotals),
    );
  }
  if (fixture.expectedLineUses.isNotEmpty) {
    addCheck(
      'business_personal',
      'line_uses_matched',
      _lineUsesMatch(parsed.lines, fixture.expectedLineUses),
    );
  }
  if (fixture.expectedLineReviewModes.isNotEmpty) {
    addCheck(
      'business_personal',
      'line_review_modes_matched',
      _lineReviewModesMatch(parsed.lines, fixture.expectedLineReviewModes),
    );
  }
  if (fixture.expectedLineNumberLabels.isNotEmpty) {
    addCheck(
      'production_parser',
      'line_number_labels_matched',
      _lineNumberLabelsMatch(parsed.lines, fixture.expectedLineNumberLabels),
    );
  }
  if (fixture.expectedLineFamilies.isNotEmpty) {
    addCheck(
      'production_parser',
      'line_families_matched',
      _lineFamiliesMatch(parsed.lines, fixture.expectedLineFamilies),
    );
  }
  if (fixture.expectedLineDescriptionNeedles.isNotEmpty) {
    addCheck(
      'production_parser',
      'line_descriptions_matched',
      _lineDescriptionNeedlesMatch(
        parsed.lines,
        fixture.expectedLineDescriptionNeedles,
      ),
    );
  }
  if (fixture.expectedLineCategories.isNotEmpty) {
    addCheck(
      'production_parser',
      'line_categories_matched',
      _lineCategoriesMatch(parsed.lines, fixture.expectedLineCategories),
    );
  }
  if (fixture.expectedNegativeLineCount != null) {
    addCheck(
      'production_parser',
      'negative_line_count_matched',
      parsed.diagnostics.negativeLineCount == fixture.expectedNegativeLineCount,
    );
  }
  if (fixture.expectedAdjustmentLineCount != null) {
    addCheck(
      'production_parser',
      'adjustment_line_count_matched',
      parsed.diagnostics.adjustmentLineCount ==
          fixture.expectedAdjustmentLineCount,
    );
  }
  if (fixture.expectReconciled != null) {
    addCheck(
      'production_parser',
      'reconciliation_expectation_met',
      parsed.diagnostics.reconciled == fixture.expectReconciled,
    );
  }
  if (fixture.expectMaintenance) {
    addCheck('maintenance', 'maintenance_service_ready', hasMaintenanceSignal);
    addCheck(
      'maintenance',
      'maintenance_interval_ready',
      hasMaintenanceInterval,
    );
  }
  addCheck(
    'privacy_admin',
    'tender_reference_exclusion_ready',
    !signals.hasTenderLineWithAmount || fixture.allowTenderAmountRows,
  );
  _addBarcodeScannerChecks(fixture: fixture, checks: checks);
  _addPrivacyAdminChecks(fixture: fixture, parsed: parsed, checks: checks);
  addCheck(
    'device_storage',
    'fixture_text_within_local_budget',
    signals.lines.length < 80,
  );
  _addPhotoQualityChecks(fixture: fixture, checks: checks);
  _addDeviceStorageBudgetChecks(fixture: fixture, checks: checks);
  return checks;
}

void _addPhotoQualityChecks({
  required _ReceiptQaFixture fixture,
  required List<_ReceiptQaCheck> checks,
}) {
  final quality = fixture.photoQuality;
  if (quality == null) return;

  void addCheck(String name, bool passed) {
    checks.add(
      _ReceiptQaCheck(dimension: 'capture', name: name, passed: passed),
    );
  }

  if (fixture.expectedPhotoPrimaryIssueLabel != null) {
    addCheck(
      'photo_quality_primary_issue_matched',
      quality.primaryIssueLabel == fixture.expectedPhotoPrimaryIssueLabel,
    );
  }
  if (fixture.expectedPhotoReviewActionCode != null) {
    addCheck(
      'photo_quality_action_matched',
      quality.reviewActionCode == fixture.expectedPhotoReviewActionCode,
    );
  }
  if (fixture.expectedPhotoShouldRetakeBeforeOcr != null) {
    addCheck(
      'photo_quality_retake_gate_matched',
      quality.shouldRetakeBeforeOcr ==
          fixture.expectedPhotoShouldRetakeBeforeOcr,
    );
  }
  if (fixture.expectedPhotoCanContinueWithReview != null) {
    addCheck(
      'photo_quality_continue_gate_matched',
      quality.canContinueWithReview ==
          fixture.expectedPhotoCanContinueWithReview,
    );
  }
  if (fixture.expectedPhotoNeedsReview != null) {
    addCheck(
      'photo_quality_review_gate_matched',
      quality.needsReview == fixture.expectedPhotoNeedsReview,
    );
  }
  if (fixture.expectedPhotoLightLabel != null) {
    addCheck(
      'photo_quality_light_label_matched',
      quality.lightLabel == fixture.expectedPhotoLightLabel,
    );
  }
  if (fixture.expectedPhotoFocusLabel != null) {
    addCheck(
      'photo_quality_focus_label_matched',
      quality.focusLabel == fixture.expectedPhotoFocusLabel,
    );
  }
  for (final needle in fixture.expectedPhotoWarningNeedles) {
    addCheck(
      'photo_quality_warning_text_matched',
      _containsTextNeedle(quality.qualityWarnings.join(' '), needle),
    );
  }
  for (final needle in fixture.expectedPhotoGuidanceNeedles) {
    addCheck(
      'photo_quality_guidance_text_matched',
      _containsTextNeedle(quality.reviewGuidance, needle),
    );
  }
  addCheck('photo_quality_warning_present', quality.qualityWarnings.isNotEmpty);
}

bool _containsTextNeedle(String haystack, String needle) {
  return haystack.toLowerCase().contains(needle.toLowerCase());
}

void _addDeviceStorageBudgetChecks({
  required _ReceiptQaFixture fixture,
  required List<_ReceiptQaCheck> checks,
}) {
  final capability = fixture.deviceCapability;
  if (capability == null) return;
  final cloudPlan = capability.cloudAssistPlan;
  final runtimeProfile = capability.cameraRuntimeProfileFor(
    guidanceRequested: true,
    startAssistedRequested: true,
    autoCaptureRequested: true,
    longReceiptTipsRequested: true,
  );

  void addCheck(String name, bool passed) {
    checks.add(
      _ReceiptQaCheck(dimension: 'device_storage', name: name, passed: passed),
    );
  }

  if (fixture.expectedCapabilityTier != null) {
    addCheck(
      'device_tier_matched',
      capability.tier == fixture.expectedCapabilityTier,
    );
  }
  if (fixture.expectedParserDepth != null) {
    addCheck(
      'parser_depth_budget_matched',
      capability.parserDepth == fixture.expectedParserDepth,
    );
  }
  if (fixture.expectedDataSaverLevel != null) {
    addCheck(
      'data_saver_budget_matched',
      capability.recommendedDataSaverLevel == fixture.expectedDataSaverLevel,
    );
  }
  if (fixture.expectedMaxLocalPhotoCount != null) {
    addCheck(
      'local_photo_count_budget_matched',
      capability.maxLocalPhotoCount == fixture.expectedMaxLocalPhotoCount,
    );
  }
  if (fixture.expectedMaxLocalPhotoBytes != null) {
    addCheck(
      'local_photo_byte_budget_matched',
      capability.maxLocalPhotoBytes == fixture.expectedMaxLocalPhotoBytes,
    );
  }
  if (fixture.expectedAssistedCameraShotCount != null) {
    addCheck(
      'assisted_shot_budget_matched',
      capability.assistedCameraShotCount ==
          fixture.expectedAssistedCameraShotCount,
    );
  }
  if (fixture.expectedBestShotCandidateCount != null) {
    addCheck(
      'best_shot_budget_matched',
      capability.bestShotCandidateCount ==
          fixture.expectedBestShotCandidateCount,
    );
  }
  if (fixture.expectedMaxStitchOutputPixels != null) {
    addCheck(
      'stitch_pixel_budget_matched',
      capability.stitchLimits.maxOutputPixels ==
          fixture.expectedMaxStitchOutputPixels,
    );
  }
  if (fixture.expectedMaxStitchOutputHeight != null) {
    addCheck(
      'stitch_height_budget_matched',
      capability.stitchLimits.maxOutputHeight ==
          fixture.expectedMaxStitchOutputHeight,
    );
  }
  if (fixture.expectedOptionalLocalPackBytes != null) {
    addCheck(
      'optional_local_pack_budget_matched',
      cloudPlan.estimatedOptionalLocalPackBytes ==
          fixture.expectedOptionalLocalPackBytes,
    );
  }
  if (fixture.expectedCloudOcrOptional != null) {
    addCheck(
      'cloud_ocr_option_matched',
      cloudPlan.cloudOcrOptional == fixture.expectedCloudOcrOptional,
    );
  }
  if (fixture.expectedCloudInventoryOptional != null) {
    addCheck(
      'cloud_inventory_option_matched',
      cloudPlan.cloudInventoryOptional ==
          fixture.expectedCloudInventoryOptional,
    );
  }
  if (fixture.expectedAutoCaptureEnabled != null) {
    addCheck(
      'auto_capture_budget_matched',
      runtimeProfile.autoCaptureEnabled == fixture.expectedAutoCaptureEnabled,
    );
  }
}
