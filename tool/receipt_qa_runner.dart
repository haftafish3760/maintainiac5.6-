import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/receipts/receipt_text_quality_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

part 'receipt_qa_fixtures.dart';
part 'receipt_qa_fixtures_adjustment_retail.dart';
part 'receipt_qa_fixtures_contractor_supply.dart';
part 'receipt_qa_fixtures_damaged_ocr.dart';
part 'receipt_qa_fixtures_device_tiers.dart';
part 'receipt_qa_fixtures_fuel.dart';
part 'receipt_qa_fixtures_long_receipt.dart';
part 'receipt_qa_fixtures_maintenance.dart';
part 'receipt_qa_fixtures_privacy_admin.dart';
part 'receipt_qa_fixture_manifest.dart';
part 'receipt_qa_report_models.dart';
part 'receipt_qa_scoring_matchers.dart';
part 'receipt_qa_scoring_privacy.dart';
part 'receipt_qa_scoring_review.dart';
part 'receipt_qa_scoring_checks.dart';
part 'receipt_qa_scoring.dart';

const _defaultFailUnder = 0.95;

void main(List<String> args) {
  final config = _ReceiptQaConfig.fromArgs(args);
  final report = _runReceiptQa(config);
  final blockers = report.blockersFor(config.failUnder);

  if (config.summaryJson) {
    stdout.writeln(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(report.toSummaryJson(failUnder: config.failUnder)),
    );
  } else if (config.json) {
    stdout.writeln(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(report.toJson(failUnder: config.failUnder)),
    );
  } else {
    stdout.writeln(report.summary);
    for (final fixture in report.fixtures) {
      stdout.writeln(fixture.summary);
      for (final issue in fixture.issues) {
        stdout.writeln('  - $issue');
      }
    }
    if (blockers.isNotEmpty) {
      stdout.writeln('Blockers:');
      for (final blocker in blockers) {
        stdout.writeln('  - $blocker');
      }
    }
  }

  if (blockers.isNotEmpty) exitCode = 1;
}

_ReceiptQaReport _runReceiptQa(_ReceiptQaConfig config) {
  final availablePacks = _availableFixturePacks();
  final selectedFixtures = _fixtures
      .where((fixture) => config.pack == 'all' || fixture.pack == config.pack)
      .toList(growable: false);
  final fixtureReports = selectedFixtures.map(_scoreFixture).toList();
  final score = fixtureReports.isEmpty
      ? 0.0
      : fixtureReports.map((fixture) => fixture.score).reduce((a, b) => a + b) /
            fixtureReports.length;

  return _ReceiptQaReport(
    pack: config.pack,
    availablePacks: availablePacks,
    score: score,
    fixtures: fixtureReports,
    fixtureFieldCoverage: _fixtureFieldCoverageToJson(selectedFixtures),
    blockers: [
      if (selectedFixtures.isEmpty)
        'No receipt QA fixtures matched pack `${config.pack}`. Available packs: '
            '${availablePacks.join(', ')}.',
      if (!_appReceiptParserIsPureDartReady())
        'Current app receipt parser/OCR code is still Flutter-bound. '
            'Extract line roles, amount recovery, and parser handoff into pure '
            'Dart libraries before this runner can score production logic.',
      ..._fixtureManifestBlockers(availablePacks),
    ],
  );
}

List<String> _availableFixturePacks() {
  return (_fixtures.map((fixture) => fixture.pack).toSet().toList()..sort())
    ..insert(0, 'all');
}

bool _appReceiptParserIsPureDartReady() {
  final parser = File('lib/screens/expenses/data/expense_receipt_parser.dart');
  final ocrContract = File('lib/shared/receipts/receipt_ocr_contract.dart');
  if (!parser.existsSync() || !ocrContract.existsSync()) return false;
  final parserText = parser.readAsStringSync();
  final contractText = ocrContract.readAsStringSync();
  return !parserText.contains('receipt_ocr_service.dart') &&
      !contractText.contains("package:flutter/");
}

class _ReceiptQaConfig {
  const _ReceiptQaConfig({
    required this.pack,
    required this.failUnder,
    required this.json,
    required this.summaryJson,
  });

  factory _ReceiptQaConfig.fromArgs(List<String> args) {
    var pack = 'all';
    var failUnder = _defaultFailUnder;
    var json = false;
    var summaryJson = false;
    for (final arg in args) {
      if (arg == '--json') {
        json = true;
      } else if (arg == '--summary-json') {
        summaryJson = true;
      } else if (arg.startsWith('--pack=')) {
        pack = arg.substring('--pack='.length);
      } else if (arg.startsWith('--fail-under=')) {
        failUnder = double.parse(arg.substring('--fail-under='.length));
      }
    }
    return _ReceiptQaConfig(
      pack: pack,
      failUnder: failUnder,
      json: json,
      summaryJson: summaryJson,
    );
  }

  final String pack;
  final double failUnder;
  final bool json;
  final bool summaryJson;
}

class _ReceiptQaFixture {
  const _ReceiptQaFixture({
    required this.pack,
    required this.name,
    required this.merchantNeedle,
    required this.text,
    this.expectedMerchantName,
    this.expectFuel = false,
    this.expectDate = true,
    this.expectTotal = true,
    this.expectBottomCoverage = true,
    this.expectTax = false,
    this.expectLineItems = false,
    this.expectMaintenance = false,
    this.allowTenderAmountRows = false,
    this.expectedDateIso,
    this.expectedSubtotal,
    this.expectedTax,
    this.expectedTotal,
    this.expectedLineCount,
    this.expectedLineSubtotals = const [],
    this.expectedLineDescriptionNeedles = const [],
    this.expectedLineCategories = const [],
    this.expectedLineFamilies = const [],
    this.expectedLineUses = const [],
    this.expectedLineReviewModes = const [],
    this.expectedLineNumberLabels = const [],
    this.expectedNegativeLineCount,
    this.expectedAdjustmentLineCount,
    this.expectReconciled,
    this.expectedFuelQuantity,
    this.expectedFuelUnitPrice,
    this.expectedFuelType,
    this.expectedFuelUnit,
    this.expectedFuelOdometer,
    this.expectedMaintenanceServiceType,
    this.expectedMaintenanceOilWeight,
    this.expectedMaintenanceServiceOdometer,
    this.expectedMaintenanceDueOdometer,
    this.expectedMaintenanceIntervalMiles,
    this.expectedMaintenanceIntervalMonths,
    this.expectedBusinessTotal,
    this.expectedPersonalTotal,
    this.expectedReviewLineCount,
    this.expectedDownstreamReadinessStatus,
    this.expectedDownstreamReadinessSummary,
    this.expectedDownstreamReadinessCounts = const {},
    this.expectedParserTaskCounts = const {},
    this.deviceCapability,
    this.expectedCapabilityTier,
    this.expectedParserDepth,
    this.expectedDataSaverLevel,
    this.expectedMaxLocalPhotoCount,
    this.expectedMaxLocalPhotoBytes,
    this.expectedAssistedCameraShotCount,
    this.expectedBestShotCandidateCount,
    this.expectedMaxStitchOutputPixels,
    this.expectedMaxStitchOutputHeight,
    this.expectedOptionalLocalPackBytes,
    this.expectedCloudOcrOptional,
    this.expectedCloudInventoryOptional,
    this.expectedAutoCaptureEnabled,
    this.photoQuality,
    this.expectedPhotoPrimaryIssueLabel,
    this.expectedPhotoReviewActionCode,
    this.expectedPhotoShouldRetakeBeforeOcr,
    this.expectedPhotoCanContinueWithReview,
    this.expectedPhotoNeedsReview,
    this.expectedSensitiveLineCount,
    this.expectedTenderPrivacyLineCount,
    this.expectedAddressContactLineCount,
    this.expectedPrivateNameLineCount,
    this.expectedSensitiveNeedlesExcluded = const [],
  });

  final String pack;
  final String name;
  final String merchantNeedle;
  final String text;
  final String? expectedMerchantName;
  final bool expectFuel;
  final bool expectDate;
  final bool expectTotal;
  final bool expectBottomCoverage;
  final bool expectTax;
  final bool expectLineItems;
  final bool expectMaintenance;
  final bool allowTenderAmountRows;
  final String? expectedDateIso;
  final double? expectedSubtotal;
  final double? expectedTax;
  final double? expectedTotal;
  final int? expectedLineCount;
  final List<double> expectedLineSubtotals;
  final List<String> expectedLineDescriptionNeedles;
  final List<String> expectedLineCategories;
  final List<String> expectedLineFamilies;
  final List<String> expectedLineUses;
  final List<String> expectedLineReviewModes;
  final List<String> expectedLineNumberLabels;
  final int? expectedNegativeLineCount;
  final int? expectedAdjustmentLineCount;
  final bool? expectReconciled;
  final double? expectedFuelQuantity;
  final double? expectedFuelUnitPrice;
  final String? expectedFuelType;
  final String? expectedFuelUnit;
  final int? expectedFuelOdometer;
  final String? expectedMaintenanceServiceType;
  final String? expectedMaintenanceOilWeight;
  final int? expectedMaintenanceServiceOdometer;
  final int? expectedMaintenanceDueOdometer;
  final int? expectedMaintenanceIntervalMiles;
  final int? expectedMaintenanceIntervalMonths;
  final double? expectedBusinessTotal;
  final double? expectedPersonalTotal;
  final int? expectedReviewLineCount;
  final String? expectedDownstreamReadinessStatus;
  final String? expectedDownstreamReadinessSummary;
  final Map<String, int> expectedDownstreamReadinessCounts;
  final Map<String, int> expectedParserTaskCounts;
  final ReceiptDeviceCapability? deviceCapability;
  final ReceiptCapabilityTier? expectedCapabilityTier;
  final ReceiptParserDepth? expectedParserDepth;
  final ReceiptDataSaverLevel? expectedDataSaverLevel;
  final int? expectedMaxLocalPhotoCount;
  final int? expectedMaxLocalPhotoBytes;
  final int? expectedAssistedCameraShotCount;
  final int? expectedBestShotCandidateCount;
  final int? expectedMaxStitchOutputPixels;
  final int? expectedMaxStitchOutputHeight;
  final int? expectedOptionalLocalPackBytes;
  final bool? expectedCloudOcrOptional;
  final bool? expectedCloudInventoryOptional;
  final bool? expectedAutoCaptureEnabled;
  final ReceiptPhotoQualityCheck? photoQuality;
  final String? expectedPhotoPrimaryIssueLabel;
  final String? expectedPhotoReviewActionCode;
  final bool? expectedPhotoShouldRetakeBeforeOcr;
  final bool? expectedPhotoCanContinueWithReview;
  final bool? expectedPhotoNeedsReview;
  final int? expectedSensitiveLineCount;
  final int? expectedTenderPrivacyLineCount;
  final int? expectedAddressContactLineCount;
  final int? expectedPrivateNameLineCount;
  final List<String> expectedSensitiveNeedlesExcluded;
}
