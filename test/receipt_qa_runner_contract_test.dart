import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_qa_external_fixture_expectations.dart';

const _runnerProcessTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'pure Dart receipt QA runner reports required dimensions and fixtures',
    () async {
      final result = await Process.run('dart', [
        'run',
        'tool/receipt_qa_runner.dart',
        '--fail-under=1.0',
        '--json',
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

      final report =
          jsonDecode(_extractJsonObject(result.stdout as String))
              as Map<String, Object?>;
      final fixtures = report['fixtures']! as List<Object?>;
      final dimensions = report['dimensionScores']! as Map<String, Object?>;
      final fieldOutcomes =
          report['fieldOutcomeCounts']! as Map<String, Object?>;
      final manifest = report['fixtureManifest']! as Map<String, Object?>;
      final fieldCoverage =
          report['fixtureFieldCoverage']! as Map<String, Object?>;
      final packScores = report['packScores']! as Map<String, Object?>;
      final checks = fixtures
          .cast<Map<String, Object?>>()
          .expand((fixture) => fixture['checks']! as List<Object?>)
          .cast<Map<String, Object?>>();
      final checkNames = fixtures
          .cast<Map<String, Object?>>()
          .expand((fixture) => fixture['checks']! as List<Object?>)
          .map((check) => (check! as Map<String, Object?>)['name']);

      expect(report['pack'], 'all');
      expect(
        report['availablePacks'],
        containsAll([
          'all',
          'adjustment',
          'contractor_supply',
          'damaged_ocr',
          'device_tiers',
          'fuel',
          'maintenance',
          'long_receipt',
          'privacy_admin',
        ]),
      );
      expect(report['score'], greaterThanOrEqualTo(1.0));
      expect(report['fixtureCount'], fixtures.length);
      expect(report['checkCount'], checkNames.length);
      expect(report['passedCheckCount'], checkNames.length);
      expect(report['failedCheckCount'], 0);
      expect(report['blockers'], isEmpty);
      expect(manifest['version'], 'receipt_qa_fixture_manifest_v1');
      expect(manifest['format'], 'external_json_v1');
      expect(
        manifest['externallyLoadedPacks'],
        containsAll([
          'adjustment',
          'contractor_supply',
          'damaged_ocr',
          'device_tiers',
          'fuel',
          'long_receipt',
          'maintenance',
          'noisy',
          'privacy_admin',
          'retail',
        ]),
      );
      expect(manifest['externalFixtureFilesReady'], isTrue);
      expect(
        manifest['requiredFields'],
        containsAll([
          'pack',
          'name',
          'merchantNeedle',
          'text',
          'expectedMerchantName',
          'expectedDateIso',
          'expectedTotal',
          'expectedLineCount',
          'expectedLineCategories',
          'expectedLineFamilies',
          'expectedLineUses',
          'expectedBarcodeCodeCount',
          'expectedQrCodeCount',
          'expectedInventoryLookupCandidateCount',
          'expectedBarcodeFormatBuckets',
          'expectedBarcodeWarningBuckets',
        ]),
      );
      final packSources = manifest['packSources']! as Map<String, Object?>;
      expect(packSources.keys, containsAll(packScores.keys));
      for (final entry in packSources.entries) {
        expect(entry.value, isA<String>());
        expect(File(entry.value! as String).existsSync(), isTrue);
      }
      final externalFixturePlan =
          manifest['externalFixturePlan']! as Map<String, Object?>;
      expect(
        externalFixturePlan['requiredBeforeReady'],
        containsAll([
          contains('external JSON/CSV fixture files'),
          contains('runner loads external fixtures'),
        ]),
      );
      final fixtureSchemaFile = File(
        externalFixturePlan['schemaFile']! as String,
      );
      expect(fixtureSchemaFile.existsSync(), isTrue);
      final fixtureInventoryFile = File(
        externalFixturePlan['inventoryFile']! as String,
      );
      expect(fixtureInventoryFile.existsSync(), isTrue);
      expectReceiptQaExternalFixtureContract(
        manifest: manifest,
        fieldCoverage: fieldCoverage,
        packScores: packScores,
      );
      expect(
        fieldOutcomes.keys,
        containsAll([
          'merchant',
          'date',
          'total',
          'line_items',
          'fuel',
          'maintenance',
          'business_personal',
          'privacy_admin',
          'device_storage',
          'barcode_qr_scanning',
          'capture_quality',
          'parser_readiness',
        ]),
      );
      for (final entry in fieldOutcomes.entries) {
        final counts = entry.value! as Map<String, Object?>;
        expect(counts['exact_match'], isA<int>());
        expect(counts['acceptable_normalized_match'], isA<int>());
        expect(counts['missed'], 0);
        expect(counts['false_positive'], 0);
        expect(counts['privacy_violation'], 0);
      }
      for (final check in checks) {
        expect(check['field'], isA<String>());
        expect(check['outcome'], isA<String>());
      }
      expect(fixtures, hasLength(greaterThanOrEqualTo(7)));
      expect(
        fixtures.map((fixture) {
          return (fixture! as Map<String, Object?>)['name'];
        }),
        containsAll([
          'top section without bottom total asks for continuation',
          'middle section overlap still needs bottom total',
          'bottom section without repeated date still captures totals',
          'oil change interval baseline',
          'oil change odometer due interval',
          'home center material quantities and packs',
          'split OCR material description rows rejoin cleanly',
          'blurry receipt source requires retake guidance',
          'glare washed receipt source requires retake guidance',
          'partial crop source stays in crop or retake review',
          'weak low contrast text asks for review before OCR',
          'wrinkled long receipt top section still asks for continuation',
          'smudged long receipt overlap keeps duplicate review diagnostics',
          'card auth address and phone stay privacy metadata',
          'fleet card and reference rows never become purchase lines',
          'older phone keeps receipt OCR workload lean',
          'critical storage defers optional packs and cloud assists',
        ]),
      );
      expect(
        dimensions.keys,
        containsAll([
          'capture',
          'ocr_text',
          'production_parser',
          'business_personal',
          'parser',
          'privacy_admin',
          'device_storage',
          'maintenance',
        ]),
      );
      expect(
        packScores.keys,
        containsAll([
          'fuel',
          'noisy',
          'retail',
          'maintenance',
          'long_receipt',
          'contractor_supply',
          'damaged_ocr',
          'privacy_admin',
          'device_tiers',
        ]),
      );
      expect(
        checkNames,
        containsAll([
          'date_value_matched',
          'merchant_name_matched',
          'subtotal_value_matched',
          'tax_value_matched',
          'total_value_matched',
          'line_count_matched',
          'line_subtotals_matched',
          'line_descriptions_matched',
          'line_categories_matched',
          'line_uses_matched',
          'line_review_modes_matched',
          'line_number_labels_matched',
          'line_families_matched',
          'negative_line_count_matched',
          'adjustment_line_count_matched',
          'reconciliation_expectation_met',
          'fuel_quantity_matched',
          'fuel_unit_price_matched',
          'fuel_type_matched',
          'fuel_unit_matched',
          'fuel_odometer_matched',
          'maintenance_service_type_matched',
          'maintenance_oil_weight_matched',
          'maintenance_service_odometer_matched',
          'maintenance_due_odometer_matched',
          'maintenance_interval_miles_matched',
          'maintenance_interval_months_matched',
          'business_total_matched',
          'personal_total_matched',
          'review_line_count_matched',
          'downstream_readiness_status_matched',
          'downstream_readiness_summary_matched',
          'downstream_readiness_counts_matched',
          'device_tier_matched',
          'parser_depth_budget_matched',
          'data_saver_budget_matched',
          'local_photo_count_budget_matched',
          'local_photo_byte_budget_matched',
          'assisted_shot_budget_matched',
          'best_shot_budget_matched',
          'stitch_pixel_budget_matched',
          'stitch_height_budget_matched',
          'optional_local_pack_budget_matched',
          'cloud_ocr_option_matched',
          'cloud_inventory_option_matched',
          'auto_capture_budget_matched',
          'photo_quality_primary_issue_matched',
          'photo_quality_action_matched',
          'photo_quality_retake_gate_matched',
          'photo_quality_continue_gate_matched',
          'photo_quality_review_gate_matched',
          'photo_quality_light_label_matched',
          'photo_quality_focus_label_matched',
          'photo_quality_warning_text_matched',
          'photo_quality_guidance_text_matched',
          'photo_quality_warning_present',
          'barcode_code_count_matched',
          'qr_code_count_matched',
          'inventory_lookup_candidate_count_matched',
          'barcode_format_buckets_matched',
          'barcode_warning_buckets_matched',
          'sensitive_line_count_matched',
          'tender_privacy_line_count_matched',
          'address_contact_line_count_matched',
          'private_name_line_count_matched',
          'sensitive_needles_excluded_from_purchase_lines',
        ]),
      );
      for (final score in dimensions.values) {
        expect(score, greaterThanOrEqualTo(1.0));
      }
      for (final score in packScores.values) {
        expect(score, greaterThanOrEqualTo(1.0));
      }
      for (final fixture in fixtures.cast<Map<String, Object?>>()) {
        expect(fixture['score'], greaterThanOrEqualTo(1.0));
        expect(fixture['issues'], isEmpty);
        final fixtureCheckNames = (fixture['checks']! as List<Object?>)
            .map((check) => (check! as Map<String, Object?>)['name'])
            .toSet();
        if (fixture['pack'] == 'contractor_supply') {
          expect(
            fixtureCheckNames,
            containsAll([
              'line_review_modes_matched',
              'line_number_labels_matched',
            ]),
            reason:
                'Contractor supply fixtures must protect numbered detailed '
                'receipt lines for inventory and job proof workflows.',
          );
        }
        if (fixture['name'] == 'home center material quantities and packs') {
          expect(
            fixtureCheckNames,
            containsAll([
              'barcode_code_count_matched',
              'qr_code_count_matched',
              'inventory_lookup_candidate_count_matched',
              'barcode_format_buckets_matched',
              'barcode_warning_buckets_matched',
            ]),
            reason:
                'The synthetic scanner fixture must prove privacy-safe barcode '
                'and QR summaries without requiring them on every receipt.',
          );
        }
        expect(
          fixtureCheckNames,
          contains('merchant_name_matched'),
          reason:
              'Every receipt QA fixture must pin exact merchant normalization.',
        );
        if (fixtureCheckNames.contains('line_count_matched')) {
          expect(
            fixtureCheckNames,
            containsAll([
              'line_descriptions_matched',
              'line_categories_matched',
              'line_families_matched',
              'line_uses_matched',
            ]),
            reason:
                'Line-item fixtures must pin descriptions, categories, '
                'families, and business/personal use.',
          );
        }
      }
    },
    timeout: _runnerProcessTimeout,
  );

  test(
    'pure Dart receipt QA runner emits compact summary JSON for quiet gates',
    () async {
      final result = await Process.run('dart', [
        'run',
        'tool/receipt_qa_runner.dart',
        '--pack=long_receipt',
        '--fail-under=1.0',
        '--summary-json',
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

      final report =
          jsonDecode(_extractJsonObject(result.stdout as String))
              as Map<String, Object?>;

      expect(report['pack'], 'long_receipt');
      expect(report['fixtureCount'], 4);
      expect(report['checkCount'], 113);
      expect(report['passedCheckCount'], report['checkCount']);
      expect(report['failedCheckCount'], 0);
      expect(report['fixtureManifest'], isA<Map<String, Object?>>());
      expect(report['fixtureFieldCoverage'], isA<Map<String, Object?>>());
      expect(report['fieldOutcomeCounts'], isA<Map<String, Object?>>());
      expect(report['failedFixtures'], isEmpty);
      expect(report['blockers'], isEmpty);
      expect(report, isNot(contains('fixtures')));
    },
    timeout: _runnerProcessTimeout,
  );

  test(
    'pure Dart receipt QA runner rejects unknown fixture packs',
    () async {
      final result = await Process.run('dart', [
        'run',
        'tool/receipt_qa_runner.dart',
        '--pack=unknown_pack',
        '--fail-under=0',
        '--json',
      ]);

      expect(result.exitCode, isNot(0));

      final report =
          jsonDecode(_extractJsonObject(result.stdout as String))
              as Map<String, Object?>;
      final blockers = report['blockers']! as List<Object?>;

      expect(report['pack'], 'unknown_pack');
      expect(report['fixtures'], isEmpty);
      expect(report['availablePacks'], contains('long_receipt'));
      expect(blockers.single, contains('No receipt QA fixtures matched pack'));
    },
    timeout: _runnerProcessTimeout,
  );

  test(
    'pure Dart receipt QA runner fails weak gate dimensions directly',
    () async {
      final result = await Process.run('dart', [
        'run',
        'tool/receipt_qa_runner.dart',
        '--fail-under=1.01',
        '--json',
      ]);

      expect(result.exitCode, isNot(0));

      final report =
          jsonDecode(_extractJsonObject(result.stdout as String))
              as Map<String, Object?>;
      final blockers = (report['blockers']! as List<Object?>).join('\n');

      expect(blockers, contains('overall `all` scored'));
      expect(blockers, contains('pack `'));
      expect(blockers, contains('dimension `'));
      expect(blockers, contains('fixture `'));
      expect(blockers, contains('below required 101.0%'));
    },
    timeout: _runnerProcessTimeout,
  );

  test(
    'receipt QA mismatch output includes expected and actual line details',
    () {
      final scoring = File('tool/receipt_qa_scoring.dart').readAsStringSync();
      final matchers = File(
        'tool/receipt_qa_scoring_matchers.dart',
      ).readAsStringSync();

      expect(scoring, contains('_lineCategoriesDebugSummary'));
      expect(scoring, contains('_lineDescriptionNeedlesDebugSummary'));
      expect(scoring, contains('_lineFamiliesDebugSummary'));
      expect(scoring, contains('_lineUsesDebugSummary'));
      expect(matchers, contains('expected=['));
      expect(matchers, contains('actual=['));
    },
  );
}

String _extractJsonObject(String output) {
  final start = output.indexOf('{');
  final end = output.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw FormatException('Receipt QA runner did not emit JSON.', output);
  }
  return output.substring(start, end + 1);
}
