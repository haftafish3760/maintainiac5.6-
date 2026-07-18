import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_module_boundary_policy.dart';

void main() {
  test('trip module boundary blocks feature and screen imports', () {
    for (final path in const [
      '../screens/dashboard_screen.dart',
      '../expenses/expense_ledger_store.dart',
      '../materials/materials_store.dart',
      '../receipts/receipt_ocr.dart',
      '../fuel/fuel_store.dart',
      '../maintenance/maintenance_store.dart',
    ]) {
      final decision = TripModuleBoundaryPolicy.evaluateImport(path);
      expect(decision.status, TripModuleBoundaryStatus.blocked);
    }
  });

  test('trip module boundary allows shared infrastructure dependencies', () {
    for (final path in const [
      'trip_tracking_models.dart',
      '../odometer/live_odometer_display.dart',
      '../storage/app_storage_guard.dart',
      '../backup/cloud_backup_sync_attempt_store.dart',
      '../device_capabilities/device_capabilities.dart',
      '../firebase/hosted_usage_limits.dart',
      'package:flutter/widgets.dart',
      'dart:async',
    ]) {
      final decision = TripModuleBoundaryPolicy.evaluateImport(path);
      expect(decision.isAllowed, isTrue, reason: path);
    }
  });

  test('all current trip tracking imports stay inside the no-touch boundary', () {
    final violations = <String>[];
    for (final file
        in Directory('lib/shared/trip_tracking')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      for (final importPath in _importsFor(file)) {
        final decision = TripModuleBoundaryPolicy.evaluateImport(importPath);
        if (!decision.isAllowed) {
          violations.add(
            '${file.path}: $importPath -> ${decision.reason.name}',
          );
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Trip tracking may depend on shared infrastructure, but must not import or mutate receipt, materials, fuel, expense, maintenance, or screen internals.',
    );
  });

  test('safe summaries never expose private paths or credentials', () {
    final safe = TripModuleBoundaryPolicy.evaluateImport(
      '../screens/dashboard_screen.dart?token=sk.secret',
    ).toSafeSummary();

    expect(safe['tripTrackingBoundaryEnforced'], isTrue);
    expect(safe['tripTrackingMayMutateExpenses'], isFalse);
    expect(safe['tripTrackingMayMutateMaterials'], isFalse);
    expect(safe['tripTrackingMayMutateReceipts'], isFalse);
    expect(safe['tripTrackingMayMutateFuel'], isFalse);
    expect(safe['tripTrackingMayMutateMaintenance'], isFalse);
    expect(safe['odometerIsGlobalTruth'], isTrue);
    expect(safe['rawFeaturePayloadIncluded'], isFalse);
    expect(safe['privatePathIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
    expect(safe.toString(), isNot(contains('dashboard_screen')));
    expect(safe.toString(), isNot(contains('sk.secret')));
  });
}

Iterable<String> _importsFor(File file) {
  final importPattern = RegExp(r"^\s*import\s+'([^']+)';");
  return file
      .readAsLinesSync()
      .map(importPattern.firstMatch)
      .whereType<RegExpMatch>()
      .map((match) => match.group(1)!)
      .where(
        (path) => !path.startsWith('package:maintaniac/shared/trip_tracking/'),
      );
}
