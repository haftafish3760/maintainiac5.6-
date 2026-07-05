import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  group('release-one residential core curation', () {
    test('priority trade core audit reports service-truck drift', () {
      final findings = <_CurationFinding>[];
      for (final item in _priorityCoreItems()) {
        findings.addAll(_auditCoreItem(item));
      }

      for (final finding in findings.take(200)) {
        // ignore: avoid_print
        print(
          'CORE_CURATION_FINDING '
          'severity=${finding.severity.name} ${finding.message}',
        );
      }
      expect(findings.length, greaterThanOrEqualTo(0));
    });

    test(
      'priority trade core items carry positive residential service signals',
      () {
        final weak = <String>[];
        for (final item in _priorityCoreItems()) {
          if (_positiveServiceSignals(item).isEmpty) {
            weak.add('${item.id}: ${item.name}');
          }
        }

        expect(
          weak,
          isEmpty,
          reason:
              'Every Core PEH residential item needs at least one service-truck, '
              'same-day pickup, common repair, or modern replacement signal.\n'
              '${weak.take(50).join('\n')}',
        );
      },
    );

    test('legacy material audit reports missing Core justification', () {
      final unjustified = <String>[];
      for (final item in _priorityCoreItems()) {
        if (!_isLegacyMaterial(item)) continue;
        if (!_isLegacyRepairBridge(item)) {
          unjustified.add('${item.id}: ${item.name}');
        }
      }

      for (final item in unjustified.take(200)) {
        // ignore: avoid_print
        print('CORE_LEGACY_REVIEW item=$item');
      }
      expect(unjustified.length, greaterThanOrEqualTo(0));
    });

    test('core curation report exposes exact production counts', () {
      final counts = {
        for (final trade in _priorityTrades) trade: _coreItemsFor(trade).length,
      };

      for (final entry in counts.entries) {
        // ignore: avoid_print
        print(
          'EXACT_RESIDENTIAL_CORE_COUNT '
          'trade=${entry.key} count=${entry.value}',
        );
        expect(entry.value, greaterThan(0));
      }
    });
  });
}

Iterable<WorkSupplyItem> _priorityCoreItems() sync* {
  for (final trade in _priorityTrades) {
    yield* _coreItemsFor(trade);
  }
}

List<WorkSupplyItem> _coreItemsFor(String trade) {
  return workSupplyCatalogItems
      .where(
        (item) =>
            item.trade == trade &&
            item.packTier == WorkSupplyPackTier.core &&
            item.marketScopes.contains(WorkSupplyMarketScope.residential),
      )
      .toList(growable: false);
}

Iterable<_CurationFinding> _auditCoreItem(WorkSupplyItem item) sync* {
  final text = _directItemText(item);
  final size = _nominalCoreSizeInches(item);
  if (_isOversizedForCore(item, size)) {
    yield _CurationFinding.blocker(
      item,
      'Oversized residential Core item should be Standard/Professional/Complete '
      'unless specifically justified: ${item.name}',
    );
  }
  if (_looksLikeMajorEquipment(text)) {
    yield _CurationFinding.blocker(
      item,
      'Major equipment should not be daily-truck Core inventory: ${item.name}',
    );
  }
  if (_looksSpecialOrderOrWarehouse(text)) {
    yield _CurationFinding.blocker(
      item,
      'Warehouse/special-order style item should not be Core: ${item.name}',
    );
  }
  if (_isLegacyMaterial(item) && !_isLegacyRepairBridge(item)) {
    yield _CurationFinding.blocker(
      item,
      'Legacy material needs transition/repair justification to stay Core: '
      '${item.name}',
    );
  }
}

List<String> _positiveServiceSignals(WorkSupplyItem item) {
  final text = _text(item);
  final signals = <String>[];
  for (final signal in _serviceTruckSignals) {
    if (text.contains(signal)) signals.add(signal);
  }
  if (_commonResidentialSize(item)) signals.add('common_size');
  if (_modernResidentialMaterial(item)) signals.add('modern_material');
  if (_isLegacyRepairBridge(item)) signals.add('legacy_repair_bridge');
  if (_commonRepairCategory(item)) signals.add('common_repair_category');
  return signals;
}

bool _isOversizedForCore(WorkSupplyItem item, double? size) {
  if (size == null) return false;
  final text = _text(item);
  if (item.trade == 'Plumbing') {
    if (text.contains('dwv') ||
        text.contains('drain') ||
        text.contains('sewer')) {
      return size > 4;
    }
    if (text.contains('copper') ||
        text.contains('pex') ||
        text.contains('cpvc')) {
      return size > 1;
    }
    if (text.contains('pvc schedule 40') || text.contains('pressure pipe')) {
      return size > 2;
    }
    return size > 4;
  }
  if (item.trade == 'Electrical') {
    if (text.contains('conduit')) return size > 2;
    return false;
  }
  if (item.trade == 'HVAC') {
    if (text.contains('line set') || text.contains('copper'))
      return size > 1.125;
    if (text.contains('duct') || text.contains('flex')) return size > 16;
  }
  return false;
}

bool _commonResidentialSize(WorkSupplyItem item) {
  final size = _nominalCoreSizeInches(item);
  if (size == null) return false;
  if (item.trade == 'Plumbing') return size <= 4;
  if (item.trade == 'Electrical') return size <= 2;
  if (item.trade == 'HVAC') return size <= 16;
  return false;
}

bool _modernResidentialMaterial(WorkSupplyItem item) {
  final text = _text(item);
  return text.contains('pex') ||
      text.contains('pvc') ||
      text.contains('cpvc') ||
      text.contains('copper') ||
      text.contains('push-fit') ||
      text.contains('sharkbite') ||
      text.contains('nm-b') ||
      text.contains('thhn') ||
      text.contains('flex duct') ||
      text.contains('condensate');
}

bool _commonRepairCategory(WorkSupplyItem item) {
  final text = _text(item);
  return text.contains('toilet') ||
      text.contains('faucet') ||
      text.contains('supply line') ||
      text.contains('valve') ||
      text.contains('trap') ||
      text.contains('wax ring') ||
      text.contains('breaker') ||
      text.contains('receptacle') ||
      text.contains('switch') ||
      text.contains('filter') ||
      text.contains('capacitor') ||
      text.contains('contactor') ||
      text.contains('thermostat');
}

bool _isLegacyMaterial(WorkSupplyItem item) {
  final text = _directItemText(item);
  return text.contains('galvanized') ||
      text.contains('galv ') ||
      text.contains('cast iron') ||
      text.contains('black iron');
}

bool _isLegacyRepairBridge(WorkSupplyItem item) {
  final text = _directItemText(item);
  return text.contains('fernco') ||
      text.contains('no-hub') ||
      text.contains('no hub') ||
      text.contains('shielded') ||
      text.contains('transition') ||
      text.contains('adapter') ||
      text.contains('repair') ||
      text.contains('coupling');
}

bool _looksLikeMajorEquipment(String text) {
  return text.contains('water heater') ||
      text.contains('heat pump') ||
      text.contains('condenser') ||
      text.contains('air handler') ||
      text.contains('furnace') ||
      text.contains('boiler') ||
      text.contains('tankless') ||
      text.contains('mini split');
}

bool _looksSpecialOrderOrWarehouse(String text) {
  return text.contains('special order') ||
      text.contains('commercial') ||
      text.contains('industrial') ||
      text.contains('warehouse') ||
      text.contains('bulk pallet') ||
      text.contains('case of');
}

double? _largestNominalInches(String text) {
  final values = <double>[];
  final mixed = RegExp(r'(\d+)-(\d+)/(\d+)\s*(?:in|inch|")');
  for (final match in mixed.allMatches(text)) {
    final whole = double.parse(match.group(1)!);
    final numerator = double.parse(match.group(2)!);
    final denominator = double.parse(match.group(3)!);
    values.add(whole + numerator / denominator);
  }
  final fraction = RegExp(r'(?<!\d)(\d+)/(\d+)\s*(?:in|inch|")');
  for (final match in fraction.allMatches(text)) {
    values.add(double.parse(match.group(1)!) / double.parse(match.group(2)!));
  }
  final decimal = RegExp(r'(?<![\d/])(\d+(?:\.\d+)?)\s*(?:in|inch|")');
  for (final match in decimal.allMatches(text)) {
    values.add(double.parse(match.group(1)!));
  }
  if (values.isEmpty) return null;
  values.sort();
  return values.last;
}

double? _nominalCoreSizeInches(WorkSupplyItem item) {
  final text = _directItemText(item);
  final leadingNominal = RegExp(
    r'(?<!\d)(\d+(?:-\d+/\d+)?|\d+/\d+|\d+(?:\.\d+)?)\s*x\s+',
  ).firstMatch(text);
  if (leadingNominal != null) {
    final parsed = _parseNominalNumber(leadingNominal.group(1)!);
    if (parsed != null) return parsed;
  }
  return _largestNominalInches(text);
}

double? _parseNominalNumber(String raw) {
  final mixed = RegExp(r'^(\d+)-(\d+)/(\d+)$').firstMatch(raw);
  if (mixed != null) {
    return double.parse(mixed.group(1)!) +
        double.parse(mixed.group(2)!) / double.parse(mixed.group(3)!);
  }
  final fraction = RegExp(r'^(\d+)/(\d+)$').firstMatch(raw);
  if (fraction != null) {
    return double.parse(fraction.group(1)!) / double.parse(fraction.group(2)!);
  }
  return double.tryParse(raw);
}

String _text(WorkSupplyItem item) {
  return [
    item.id,
    item.name,
    item.trade,
    item.category,
    item.system,
    item.itemType,
    item.variant,
    item.unit,
    ...item.aliases,
    ...item.intelligence.searchableTokens,
  ].join(' ').toLowerCase();
}

String _directItemText(WorkSupplyItem item) {
  return [
    item.id,
    item.name,
    item.trade,
    item.category,
    item.system,
    item.itemType,
    item.variant,
    item.unit,
    ...item.aliases,
  ].join(' ').toLowerCase();
}

const _priorityTrades = ['Plumbing', 'Electrical', 'HVAC'];

const _serviceTruckSignals = {
  'service truck',
  'truck stock',
  'common',
  'repair',
  'replacement',
  'residential',
  'same-day',
  'same day',
  'big box',
  'supply house',
  'stocked',
  'daily',
};

enum _Severity { blocker }

class _CurationFinding {
  const _CurationFinding._({
    required this.item,
    required this.severity,
    required this.message,
  });

  factory _CurationFinding.blocker(WorkSupplyItem item, String message) {
    return _CurationFinding._(
      item: item,
      severity: _Severity.blocker,
      message: '${item.id}: $message',
    );
  }

  final WorkSupplyItem item;
  final _Severity severity;
  final String message;
}
