part of 'receipt_qa_runner.dart';

_ReceiptFixtureReport _scoreFixture(_ReceiptQaFixture fixture) {
  final issues = <String>[];
  final signals = evaluateReceiptTextQuality(
    text: fixture.text,
    merchantNeedle: fixture.merchantNeedle,
  );
  final parsed = parseExpenseReceiptText(fixture.text);
  final fuelLine = parsed.lines.where(_isParsedFuelLine).firstOrNull;
  final maintenanceHint = parsed.maintenanceHints.firstOrNull;
  final hasExpectedFuel = fixture.expectFuel ? signals.hasFuelQuantity : true;
  final hasExpectedDate = fixture.expectDate ? signals.hasDate : true;
  final hasExpectedTotal = fixture.expectTotal ? signals.hasTotal : true;
  final hasExpectedBottomCoverage =
      signals.hasBottomTotalCoverage == fixture.expectBottomCoverage;
  final hasExpectedTax = fixture.expectTax ? signals.hasTax : true;
  final hasLineItemAmount = fixture.expectLineItems
      ? signals.hasLineItemAmount
      : true;
  final hasMaintenanceSignal = fixture.expectMaintenance
      ? signals.hasMaintenanceService
      : true;
  final hasMaintenanceInterval = fixture.expectMaintenance
      ? signals.hasMaintenanceInterval
      : true;

  if (!signals.hasMerchant) {
    issues.add('merchant_not_detectable_by_text_contract');
  }
  if (!hasExpectedTotal) {
    issues.add('total_not_detectable_by_text_contract');
  }
  if (!hasExpectedDate) issues.add('date_not_detectable_by_text_contract');
  if (!hasExpectedBottomCoverage) {
    issues.add('bottom_total_coverage_expectation_mismatch');
  }
  if (!hasExpectedFuel) {
    issues.add('fuel_quantity_not_detectable_by_text_contract');
  }
  if (!hasExpectedTax) issues.add('tax_not_detectable_by_text_contract');
  if (!hasLineItemAmount) issues.add('line_item_amount_not_detectable');
  if (!hasMaintenanceSignal) issues.add('maintenance_service_not_detectable');
  if (!hasMaintenanceInterval) {
    issues.add('maintenance_interval_not_detectable');
  }
  if (signals.hasTenderLineWithAmount && !fixture.allowTenderAmountRows) {
    issues.add('tender_rows_need_exclusion_guard');
  }
  if (!_matchesMerchant(parsed.merchantName, fixture.merchantNeedle)) {
    issues.add('production_parser_merchant_mismatch');
  }
  if (fixture.expectedMerchantName != null &&
      parsed.merchantName != fixture.expectedMerchantName) {
    issues.add(
      'production_parser_merchant_name_mismatch'
      '(expected=${fixture.expectedMerchantName}, actual=${parsed.merchantName})',
    );
  }
  if (fixture.expectTotal && parsed.enteredTotal == null) {
    issues.add('production_parser_total_missing');
  }
  if (fixture.expectDate && parsed.receiptDate == null) {
    issues.add('production_parser_date_missing');
  }
  if (fixture.expectLineItems && parsed.lines.isEmpty) {
    issues.add('production_parser_line_items_missing');
  }
  if (fixture.expectFuel && fuelLine == null) {
    issues.add('production_parser_fuel_line_missing');
  }
  if (fixture.expectedFuelQuantity != null &&
      !_nearMoney(fuelLine?.quantity, fixture.expectedFuelQuantity!)) {
    issues.add('production_parser_fuel_quantity_mismatch');
  }
  if (fixture.expectedFuelUnitPrice != null &&
      !_nearMoney(fuelLine?.unitPrice, fixture.expectedFuelUnitPrice!)) {
    issues.add('production_parser_fuel_unit_price_mismatch');
  }
  if (fixture.expectedFuelType != null &&
      fuelLine?.fuelType != fixture.expectedFuelType) {
    issues.add('production_parser_fuel_type_mismatch');
  }
  if (fixture.expectedFuelUnit != null &&
      fuelLine?.unit != fixture.expectedFuelUnit) {
    issues.add('production_parser_fuel_unit_mismatch');
  }
  if (fixture.expectedFuelOdometer != null &&
      fuelLine?.odometerReading != fixture.expectedFuelOdometer) {
    issues.add('production_parser_fuel_odometer_mismatch');
  }
  if (fixture.expectedMaintenanceServiceType != null &&
      maintenanceHint?.serviceType != fixture.expectedMaintenanceServiceType) {
    issues.add('production_parser_maintenance_service_type_mismatch');
  }
  if (fixture.expectedMaintenanceOilWeight != null &&
      maintenanceHint?.oilWeight != fixture.expectedMaintenanceOilWeight) {
    issues.add('production_parser_maintenance_oil_weight_mismatch');
  }
  if (fixture.expectedMaintenanceServiceOdometer != null &&
      maintenanceHint?.serviceOdometer !=
          fixture.expectedMaintenanceServiceOdometer) {
    issues.add('production_parser_maintenance_service_odometer_mismatch');
  }
  if (fixture.expectedMaintenanceDueOdometer != null &&
      maintenanceHint?.dueOdometer != fixture.expectedMaintenanceDueOdometer) {
    issues.add('production_parser_maintenance_due_odometer_mismatch');
  }
  if (fixture.expectedMaintenanceIntervalMiles != null &&
      maintenanceHint?.intervalMiles !=
          fixture.expectedMaintenanceIntervalMiles) {
    issues.add('production_parser_maintenance_interval_miles_mismatch');
  }
  if (fixture.expectedMaintenanceIntervalMonths != null &&
      maintenanceHint?.intervalMonths !=
          fixture.expectedMaintenanceIntervalMonths) {
    issues.add('production_parser_maintenance_interval_months_mismatch');
  }
  _addBusinessReviewIssues(fixture: fixture, parsed: parsed, issues: issues);
  if (fixture.expectedDateIso != null &&
      _dateIso(parsed.receiptDate) != fixture.expectedDateIso) {
    issues.add('production_parser_date_value_mismatch');
  }
  if (fixture.expectedSubtotal != null &&
      !_nearMoney(parsed.enteredSubtotal, fixture.expectedSubtotal!)) {
    issues.add('production_parser_subtotal_value_mismatch');
  }
  if (fixture.expectedTax != null &&
      !_nearMoney(parsed.enteredTax, fixture.expectedTax!)) {
    issues.add('production_parser_tax_value_mismatch');
  }
  if (fixture.expectedTotal != null &&
      !_nearMoney(parsed.enteredTotal, fixture.expectedTotal!)) {
    issues.add('production_parser_total_value_mismatch');
  }
  if (fixture.expectedLineCount != null &&
      parsed.lines.length != fixture.expectedLineCount) {
    issues.add('production_parser_line_count_mismatch');
  }
  if (fixture.expectedLineSubtotals.isNotEmpty &&
      !_lineSubtotalsMatch(parsed.lines, fixture.expectedLineSubtotals)) {
    issues.add('production_parser_line_subtotals_mismatch');
  }
  if (fixture.expectedLineDescriptionNeedles.isNotEmpty &&
      !_lineDescriptionNeedlesMatch(
        parsed.lines,
        fixture.expectedLineDescriptionNeedles,
      )) {
    issues.add(
      'production_parser_line_descriptions_mismatch'
      '(${_lineDescriptionNeedlesDebugSummary(parsed.lines, fixture.expectedLineDescriptionNeedles)})',
    );
  }
  if (fixture.expectedLineCategories.isNotEmpty &&
      !_lineCategoriesMatch(parsed.lines, fixture.expectedLineCategories)) {
    issues.add(
      'production_parser_line_categories_mismatch'
      '(${_lineCategoriesDebugSummary(parsed.lines, fixture.expectedLineCategories)})',
    );
  }
  if (fixture.expectedLineFamilies.isNotEmpty &&
      !_lineFamiliesMatch(parsed.lines, fixture.expectedLineFamilies)) {
    issues.add(
      'production_parser_line_families_mismatch'
      '(${_lineFamiliesDebugSummary(parsed.lines, fixture.expectedLineFamilies)})',
    );
  }
  if (fixture.expectedLineUses.isNotEmpty &&
      !_lineUsesMatch(parsed.lines, fixture.expectedLineUses)) {
    issues.add(
      'production_parser_line_uses_mismatch'
      '(${_lineUsesDebugSummary(parsed.lines, fixture.expectedLineUses)})',
    );
  }
  if (fixture.expectedLineReviewModes.isNotEmpty &&
      !_lineReviewModesMatch(parsed.lines, fixture.expectedLineReviewModes)) {
    issues.add(
      'production_parser_line_review_modes_mismatch'
      '(${_lineReviewModesDebugSummary(parsed.lines, fixture.expectedLineReviewModes)})',
    );
  }
  if (fixture.expectedLineNumberLabels.isNotEmpty &&
      !_lineNumberLabelsMatch(parsed.lines, fixture.expectedLineNumberLabels)) {
    issues.add(
      'production_parser_line_number_labels_mismatch'
      '(${_lineNumberLabelsDebugSummary(parsed.lines, fixture.expectedLineNumberLabels)})',
    );
  }
  if (fixture.expectedNegativeLineCount != null &&
      parsed.diagnostics.negativeLineCount !=
          fixture.expectedNegativeLineCount) {
    issues.add('production_parser_negative_line_count_mismatch');
  }
  if (fixture.expectedAdjustmentLineCount != null &&
      parsed.diagnostics.adjustmentLineCount !=
          fixture.expectedAdjustmentLineCount) {
    issues.add('production_parser_adjustment_line_count_mismatch');
  }
  if (fixture.expectReconciled != null &&
      parsed.diagnostics.reconciled != fixture.expectReconciled) {
    issues.add('production_parser_reconciliation_mismatch');
  }
  _addPrivacyAdminIssues(fixture: fixture, parsed: parsed, issues: issues);

  final checks = _buildReceiptQaChecks(
    fixture: fixture,
    parsed: parsed,
    signals: signals,
    fuelLine: fuelLine,
    maintenanceHint: maintenanceHint,
    hasExpectedBottomCoverage: hasExpectedBottomCoverage,
    hasExpectedDate: hasExpectedDate,
    hasExpectedFuel: hasExpectedFuel,
    hasExpectedTax: hasExpectedTax,
    hasExpectedTotal: hasExpectedTotal,
    hasLineItemAmount: hasLineItemAmount,
    hasMaintenanceInterval: hasMaintenanceInterval,
    hasMaintenanceSignal: hasMaintenanceSignal,
  );
  final score = checks.where((check) => check.passed).length / checks.length;

  return _ReceiptFixtureReport(
    name: fixture.name,
    pack: fixture.pack,
    score: score,
    issues: issues,
    checks: checks,
  );
}
