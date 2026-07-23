import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';

void main() {
  final fixtures = _loadFixtures();

  test('layout corpus has explicit layout and damage classifications', () {
    expect(fixtures, isNotEmpty);
    expect(
      fixtures.map((fixture) => fixture.id).toSet(),
      hasLength(fixtures.length),
    );
    expect(
      fixtures,
      everyElement(
        isA<_LayoutFixture>()
            .having(
              (fixture) => fixture.layoutClass,
              'layout class',
              isNotEmpty,
            )
            .having(
              (fixture) => fixture.damageClass,
              'damage class',
              isNotEmpty,
            ),
      ),
    );
  });

  for (final fixture in fixtures) {
    test('layout corpus ${fixture.id}', () {
      final result = parseMaintenanceReceipt(
        MaintenanceReceiptParserInput(
          activeVehicleId: 'layout_vehicle',
          activeVehicleName: 'Layout Vehicle',
          currentOdometer: 200000,
          sourceText: fixture.sourceText,
        ),
      );

      expect(result.merchantName, fixture.merchant, reason: fixture.id);
      expect(result.kind.name, fixture.kind, reason: fixture.id);
      final candidates = {
        for (final candidate in result.candidates)
          candidate.itemName: candidate,
      };
      expect(
        candidates.keys,
        unorderedEquals(fixture.items.keys),
        reason: '${fixture.id} exact candidate set',
      );
      for (final entry in fixture.items.entries) {
        final candidate = candidates[entry.key];
        expect(candidate, isNotNull, reason: '${fixture.id} ${entry.key}');
        final expected = entry.value;
        expect(
          candidate!.action.name,
          expected.action,
          reason: '${fixture.id} ${entry.key} action',
        );
        expect(
          candidate.detailA,
          expected.detailA,
          reason: '${fixture.id} ${entry.key} detailA',
        );
        expect(
          candidate.detailB,
          expected.detailB,
          reason: '${fixture.id} ${entry.key} detailB',
        );
        expect(
          candidate.serviceOdometer,
          expected.serviceOdometer,
          reason: '${fixture.id} ${entry.key} service odometer',
        );
        expect(
          candidate.dueOdometer,
          expected.dueOdometer,
          reason: '${fixture.id} ${entry.key} due odometer',
        );
        expect(
          candidate.intervalMiles,
          expected.intervalMiles,
          reason: '${fixture.id} ${entry.key} interval',
        );
        expect(candidate.requiresUserConfirmation, isTrue);
      }
      for (final forbidden in fixture.forbiddenItems) {
        expect(
          candidates,
          isNot(contains(forbidden)),
          reason: '${fixture.id} unexpectedly found $forbidden',
        );
      }
      expect(result.mayMutateMaintenance, isFalse);
    });
  }
}

List<_LayoutFixture> _loadFixtures() {
  final decoded =
      jsonDecode(
            File(
              'test/fixtures/maintenance_receipts/layout_corpus.json',
            ).readAsStringSync(),
          )
          as List<dynamic>;
  return [
    for (final value in decoded)
      _LayoutFixture.fromJson((value as Map).cast<String, dynamic>()),
  ];
}

class _LayoutFixture {
  const _LayoutFixture({
    required this.id,
    required this.layoutClass,
    required this.damageClass,
    required this.merchant,
    required this.kind,
    required this.sourceText,
    required this.items,
    required this.forbiddenItems,
  });

  final String id;
  final String layoutClass;
  final String damageClass;
  final String merchant;
  final String kind;
  final String sourceText;
  final Map<String, _ExpectedItem> items;
  final List<String> forbiddenItems;

  factory _LayoutFixture.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key,
        _ExpectedItem.fromJson((value as Map).cast<String, dynamic>()),
      ),
    );
    final fixture = _LayoutFixture(
      id: '${json['id'] ?? ''}'.trim(),
      layoutClass: '${json['layoutClass'] ?? ''}'.trim(),
      damageClass: '${json['damageClass'] ?? ''}'.trim(),
      merchant: '${json['merchant'] ?? ''}'.trim(),
      kind: '${json['kind'] ?? ''}'.trim(),
      sourceText: '${json['sourceText'] ?? ''}',
      items: Map.unmodifiable(items),
      forbiddenItems: List.unmodifiable(
        (json['forbiddenItems'] as List<dynamic>).cast<String>(),
      ),
    );
    if (fixture.id.isEmpty ||
        fixture.layoutClass.isEmpty ||
        fixture.damageClass.isEmpty ||
        fixture.merchant.isEmpty ||
        fixture.kind.isEmpty ||
        fixture.sourceText.trim().isEmpty) {
      throw FormatException('Layout fixture is incomplete: ${fixture.id}');
    }
    return fixture;
  }
}

class _ExpectedItem {
  const _ExpectedItem({
    required this.action,
    this.detailA,
    this.detailB,
    this.serviceOdometer,
    this.dueOdometer,
    this.intervalMiles,
  });

  final String action;
  final String? detailA;
  final String? detailB;
  final int? serviceOdometer;
  final int? dueOdometer;
  final int? intervalMiles;

  factory _ExpectedItem.fromJson(Map<String, dynamic> json) {
    final action = '${json['action'] ?? ''}'.trim();
    if (action.isEmpty) {
      throw const FormatException('Layout fixture item action is missing.');
    }
    return _ExpectedItem(
      action: action,
      detailA: json['detailA'] as String?,
      detailB: json['detailB'] as String?,
      serviceOdometer: json['serviceOdometer'] as int?,
      dueOdometer: json['dueOdometer'] as int?,
      intervalMiles: json['intervalMiles'] as int?,
    );
  }
}
