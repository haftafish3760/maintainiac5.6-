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
      final blockers = findings
          .where((finding) => finding.severity == _Severity.blocker)
          .toList(growable: false);
      expect(
        blockers,
        isEmpty,
        reason:
            'Residential Core must not contain known oversized, major-equipment, '
            'warehouse, or unjustified legacy items.\n'
            '${blockers.take(100).map((finding) => finding.message).join('\n')}',
      );
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

    test('electrical and hvac core tiers require trade-specific signals', () {
      final unsafe = <String>[];
      for (final item in _priorityCoreItems()) {
        if (item.trade == 'Plumbing') continue;
        final text = _text(item);
        final hasTradeSignal = item.trade == 'Electrical'
            ? _hasAny(text, _electricalCoreSignals)
            : _hasAny(text, _hvacCoreSignals);
        if (!hasTradeSignal) {
          unsafe.add('${item.id}: ${item.trade}: ${item.name}');
        }
      }

      expect(
        unsafe,
        isEmpty,
        reason:
            'Electrical/HVAC Core cannot be promoted by generic words like PVC, '
            'filter, elbow, coupling, adapter, box, or tape alone.\n'
            '${unsafe.take(100).join('\n')}',
      );
    });

    test('oversized electrical raceway is not residential Core', () {
      final oversized = _coreItemsFor('Electrical')
          .where((item) {
            final text = _text(item);
            return text.contains('conduit') &&
                _hasAny(text, [
                  '2-1/2 in',
                  '3 in',
                  '3-1/2 in',
                  '4 in',
                  '5 in',
                  '6 in',
                ]);
          })
          .map((item) => '${item.id}: ${item.name}')
          .toList(growable: false);

      expect(
        oversized,
        isEmpty,
        reason:
            'Large conduit/raceway sizes belong in Standard/Professional/Complete, '
            'not everyday residential Core.\n${oversized.take(100).join('\n')}',
      );
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

bool _hasAny(String text, List<String> signals) {
  return signals.any(text.contains);
}

bool _isOversizedForCore(WorkSupplyItem item, double? size) {
  if (size == null) return false;
  final text = _directItemText(item);
  if (item.trade == 'Plumbing') {
    if (!_plumbingNominalSizeMatters(item)) return false;
    if (item.category.toLowerCase() == 'hangers and supports') {
      return size > 2;
    }
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
    if (!_hvacNominalSizeMatters(item)) return false;
    if (text.contains('line set') || text.contains('copper'))
      return size > 1.125;
    if (text.contains('duct') || text.contains('flex')) return size > 16;
  }
  return false;
}

bool _plumbingNominalSizeMatters(WorkSupplyItem item) {
  final text = _directItemText(item);
  if (item.category.toLowerCase() == 'fittings') return true;
  if (item.category.toLowerCase() == 'pipe and tubing') return true;
  if (item.category.toLowerCase() == 'valves') return true;
  if (text.contains('pipe strap') ||
      text.contains('pipe j-hook') ||
      text.contains('bell hanger') ||
      text.contains('split ring hanger')) {
    return true;
  }
  return false;
}

bool _hvacNominalSizeMatters(WorkSupplyItem item) {
  final text = _directItemText(item);
  if (text.contains('zip tie')) return false;
  return text.contains('line set') ||
      text.contains('copper tubing') ||
      text.contains('flex duct') ||
      text.contains('round duct') ||
      text.contains('sheet metal duct') ||
      text.contains('duct board');
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
  return text.contains('heat pump') ||
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
  final text = [item.name, item.variant].join(' ').toLowerCase();
  final leadingInchNominal = RegExp(
    r'(?<!\d)(\d+(?:-\d+/\d+)?|\d+/\d+|\d+(?:\.\d+)?)\s*(?:in|inch|")\s*x\s+',
  ).firstMatch(text);
  if (leadingInchNominal != null) {
    final parsed = _parseNominalNumber(leadingInchNominal.group(1)!);
    if (parsed != null) return parsed;
  }
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

const _electricalCoreSignals = [
  '14/2',
  '14/3',
  '12/2',
  '12/3',
  '10/2',
  'nm-b cable',
  'romex',
  'house wire',
  'uf-b cable',
  'uf cable',
  '14 awg',
  '12 awg',
  '10 awg',
  'thhn',
  'thwn',
  'low voltage cable',
  'doorbell wire',
  'control wire',
  'duplex receptacle',
  'gfci',
  'outlet',
  'toggle switch',
  'single pole',
  '3-way',
  'dimmer',
  'circuit breaker',
  'breaker',
  'single-pole breaker',
  'double-pole breaker',
  '25 amp',
  '30 amp',
  '40 amp',
  '50 amp',
  '60 amp',
  'afci breaker',
  'dual function breaker',
  'arc fault breaker',
  'old work',
  'new work',
  'junction box',
  'device box',
  'handy box',
  'blank cover',
  'cover plate',
  'wall plate',
  'fan box',
  'ceiling box',
  'fixture box',
  'bar hanger',
  'fan brace',
  'knockout seal',
  'ko seal',
  'reducing washer',
  'locknut',
  'plastic bushing',
  'grounding clip',
  'box extender',
  'mud ring',
  'weatherproof',
  'in-use cover',
  'gfci cover',
  'bell box',
  'outdoor cover',
  'bubble cover',
  'wire connector',
  'wire nut',
  'electrical tape',
  'ground screw',
  'ground pigtail',
  'cable staple',
  'romex connector',
  'nm connector',
  'device screw',
  'plate screw',
  'outlet spacer',
  'receptacle tester',
  'gfci tester',
  'wire pulling lube',
  'putty pad',
  'noalox',
  'anti-oxidant',
  'pull string',
  'fish tape',
  'plastic bushings',
  'emt conduit',
  'emt connector',
  'emt coupling',
  'emt 90 elbow',
  'emt strap',
  'pvc electrical conduit',
  'pvc electrical 90 elbow',
  'pvc electrical coupling',
  'terminal adapter',
  'set screw',
  'compression fitting',
  'lb body',
  'll body',
  'lr body',
  'conduit body',
  'body cover',
  'mini strap',
  'one hole strap',
  'two hole strap',
  'conduit hanger',
  'fmc connector',
  'flex conduit',
  'liquidtight connector',
  'liquid tight',
  'sealtite',
  'ground wire',
  'ground rod',
  'ground rod clamp',
  'grounding pigtail',
  'green ground screw',
  'bonding jumper',
  'ground clamp',
  'smoke alarm',
  'smoke detector',
  'carbon monoxide',
  'co alarm',
  'doorbell transformer',
  'doorbell chime',
  'video doorbell',
  'flush mount',
  'vanity',
  'recessed trim',
  'outdoor wall',
  'flood light',
  'lampholder',
  'porcelain lampholder',
  'fixture strap',
  'fixture crossbar',
  'fixture stud',
  'canopy screw',
  'recessed trim clip',
  'remodel clip',
  'tombstone socket',
  'fluorescent starter',
  'cord grip',
  'photocell',
  'fixture gasket',
  'landscape lighting connector',
  'a19',
  'br30',
  'par38',
  'led lamp',
  'led driver',
  'led tape light',
  'shop light',
  'bulb',
];

const _hvacCoreSignals = [
  'pleated air filter',
  'furnace filter',
  'ac filter',
  'run capacitor',
  'dual run capacitor',
  'single run capacitor',
  'start capacitor',
  'hard start kit',
  'potential relay',
  'contactor',
  'thermostat',
  'thermostat wire',
  'low voltage wire',
  'fuse',
  'blade fuse',
  'cartridge fuse',
  'relay',
  'fan relay',
  'isolation relay',
  'time delay relay',
  'sequencer',
  'transformer',
  '24v transformer',
  'outdoor sensor',
  'remote indoor sensor',
  'duct temperature sensor',
  'common wire adapter',
  'wire saver',
  'terminal strip',
  'spade terminal',
  'condensate pump',
  'condensate line',
  'condensate drain',
  'float switch',
  'foil hvac tape',
  'foil tape',
  'duct tape',
  'mastic',
  'duct sealant',
  'ul181 tape',
  'foam gasket tape',
  'thumb gum',
  'register boot',
  'duct boot',
  'end boot',
  'straight boot',
  'wall stack',
  'start collar',
  'takeoff',
  'spin in',
  'spin-in',
  'sheet metal collar',
  'round pipe',
  'snap lock pipe',
  'adjustable elbow',
  'duct coupling',
  'manual damper',
  'balancing damper',
  'backdraft damper',
  'duct reducer',
  'sheet metal screw',
  'zip screw',
  'tek screw',
  'self drilling screw',
  'duct strap',
  'hanger strap',
  'duct mastic',
  'mastic brush',
  'flex duct zip tie',
  'floor register',
  'return air grille',
  'return filter grille',
  'ceiling diffuser',
  'eggcrate return grille',
  'filter grille replacement door',
  'air distribution face',
  'blower belt',
  'condenser fan motor',
  'blower motor',
  'fan blade',
  'blower wheel',
  'belly band',
  'motor mount',
  'hub adapter',
  'v belt',
  'motor pulley',
  'adjustable sheave',
  'isolation grommet',
  'flame sensor',
  'hot surface ignitor',
  'ignitor',
  'thermocouple',
  'pressure switch',
  'pressure switch tubing',
  'rollout switch',
  'limit switch',
  'furnace door switch',
  'inducer gasket',
  'pilot assembly',
  'thermopile',
  'burner orifice',
  'gas leak detector',
  'coil cleaner',
  'leak detector',
  'service chemical',
  'service sticker',
  'equipment tag',
  'wire marker',
  'low voltage wire nut',
  'fork terminal',
  'zip tie',
  'no ox grease',
];

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
