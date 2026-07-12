import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  test('Plumbing Core rows carry professional parser metadata', () {
    final failures = <String>[];
    final coreRows = workSupplyCatalogItems
        .where(
          (item) =>
              item.trade == 'Plumbing' &&
              item.packTier == WorkSupplyPackTier.core &&
              item.marketScopes.contains(WorkSupplyMarketScope.residential),
        )
        .toList(growable: false);

    for (final item in coreRows) {
      final intelligence = item.intelligence;
      final searchable = item.searchableText;
      _expect(
        failures,
        item,
        item.aliases.length >= 4,
        'needs at least four aliases',
      );
      _expect(
        failures,
        item,
        intelligence.receiptPatterns.length >= 8,
        'needs rich receipt patterns',
      );
      _expect(
        failures,
        item,
        intelligence.negativeMatchTokens.length >= 3,
        'needs negative-match ambiguity tokens',
      );
      _expect(
        failures,
        item,
        intelligence.highImportanceTokens.length >= 4,
        'needs high-importance parser tokens',
      );
      _expect(
        failures,
        item,
        intelligence.attributeTokens.contains('plumbing-core'),
        'needs plumbing-core attribute token',
      );
      _expect(
        failures,
        item,
        intelligence.attributeTokens.contains('residential-service'),
        'needs residential-service attribute token',
      );
      _expect(
        failures,
        item,
        searchable.contains('spanish') || searchable.contains('es-us'),
        'needs Spanish metadata',
      );
      _expect(
        failures,
        item,
        intelligence.classification.inventoryCategory.isNotEmpty &&
            intelligence.classification.expenseCategory.isNotEmpty &&
            intelligence.classification.jobMaterialCategory.isNotEmpty,
        'needs classification metadata',
      );
      _expect(
        failures,
        item,
        intelligence.catalogVersion.isNotEmpty &&
            intelligence.parserVersion.isNotEmpty,
        'needs catalog/parser versions',
      );
      _expect(
        failures,
        item,
        intelligence.sourceConfidence.isNotEmpty,
        'needs source confidence metadata',
      );
    }

    expect(coreRows.length, greaterThan(1000));
    expect(failures, isEmpty, reason: failures.take(80).join('\n'));
  });

  test('Plumbing Core service families carry family-specific metadata', () {
    final failures = <String>[];
    final coreRows = workSupplyCatalogItems
        .where(
          (item) =>
              item.trade == 'Plumbing' &&
              item.packTier == WorkSupplyPackTier.core &&
              item.marketScopes.contains(WorkSupplyMarketScope.residential),
        )
        .toList(growable: false);

    for (final family in _requiredFamilies) {
      final matches = coreRows
          .where((item) => family.selector(item.searchableText))
          .toList(growable: false);
      if (matches.isEmpty) {
        failures.add('${family.name}: missing Core items');
        continue;
      }
      final familyText = matches
          .map((item) => item.searchableText)
          .join(' ')
          .toLowerCase();
      for (final term in family.englishTerms) {
        if (!familyText.contains(term)) {
          failures.add('${family.name}: missing English term "$term"');
        }
      }
      for (final term in family.compactReceiptTerms) {
        if (!familyText.contains(term.toLowerCase())) {
          failures.add('${family.name}: missing compact term "$term"');
        }
      }
      for (final term in family.spanishTerms) {
        if (!familyText.contains(term)) {
          failures.add('${family.name}: missing Spanish term "$term"');
        }
      }
      for (final term in family.negativeTerms) {
        if (!familyText.contains(term)) {
          failures.add('${family.name}: missing negative term "$term"');
        }
      }
    }

    expect(failures, isEmpty, reason: failures.take(120).join('\n'));
  });
}

class _RequiredFamily {
  const _RequiredFamily({
    required this.name,
    required this.selector,
    required this.englishTerms,
    required this.compactReceiptTerms,
    required this.spanishTerms,
    required this.negativeTerms,
  });

  final String name;
  final bool Function(String searchableText) selector;
  final List<String> englishTerms;
  final List<String> compactReceiptTerms;
  final List<String> spanishTerms;
  final List<String> negativeTerms;
}

final _requiredFamilies = <_RequiredFamily>[
  _RequiredFamily(
    name: 'tubular p-trap',
    selector: (text) => text.contains('tubular p-trap'),
    englishTerms: const ['p trap', 'sink trap', 'lav trap'],
    compactReceiptTerms: const ['P TRAP'],
    spanishTerms: const ['trampa p', 'trampa lavabo'],
    negativeTerms: const ['electrical conduit', 'hvac air filter'],
  ),
  _RequiredFamily(
    name: 'toilet fill valve',
    selector: (text) => text.contains('toilet fill valve'),
    englishTerms: const ['fill valve', 'ballcock'],
    compactReceiptTerms: const ['FILL VALVE'],
    spanishTerms: const ['valvula llenado'],
    negativeTerms: const ['electrical conduit', 'hvac air filter'],
  ),
  _RequiredFamily(
    name: 'toilet tank lever',
    selector: (text) => text.contains('toilet tank lever'),
    englishTerms: const ['tank lever', 'flush lever'],
    compactReceiptTerms: const ['TANK LEVER'],
    spanishTerms: const ['palanca tanque'],
    negativeTerms: const ['electrical conduit', 'hvac air filter'],
  ),
  _RequiredFamily(
    name: 'faucet aerator',
    selector: (text) => text.contains('faucet aerator'),
    englishTerms: const ['aerator', 'faucet screen'],
    compactReceiptTerms: const ['AERATOR'],
    spanishTerms: const ['aireador'],
    negativeTerms: const ['electrical conduit', 'hvac air filter'],
  ),
  _RequiredFamily(
    name: 'faucet o-ring',
    selector: (text) => text.contains('faucet o-ring'),
    englishTerms: const ['o ring', 'seal kit'],
    compactReceiptTerms: const ['O RING'],
    spanishTerms: const ['empaque llave'],
    negativeTerms: const ['electrical conduit', 'hvac air filter'],
  ),
  _RequiredFamily(
    name: 'disposal drain elbow',
    selector: (text) => text.contains('disposal drain elbow'),
    englishTerms: const ['disposal elbow', 'garbage disposal elbow'],
    compactReceiptTerms: const ['DISP DRAIN ELB'],
    spanishTerms: const ['codo triturador'],
    negativeTerms: const ['electrical conduit', 'hvac air filter'],
  ),
  _RequiredFamily(
    name: 'disposal install kit',
    selector: (text) => text.contains('disposal install kit'),
    englishTerms: const ['disposal kit', 'garbage disposal connector'],
    compactReceiptTerms: const ['DISP INSTALL KIT'],
    spanishTerms: const ['kit triturador'],
    negativeTerms: const ['electrical conduit', 'hvac air filter'],
  ),
  _RequiredFamily(
    name: 'continuous waste',
    selector: (text) => text.contains('continuous waste'),
    englishTerms: const ['cont waste', 'double bowl waste'],
    compactReceiptTerms: const ['CONTINUOUS WASTE'],
    spanishTerms: const ['plomeria residencial'],
    negativeTerms: const ['electrical conduit', 'hvac air filter'],
  ),
  _RequiredFamily(
    name: 'pvc reducing coupling',
    selector: (text) =>
        text.contains('pvc schedule 40 reducing coupling') ||
        text.contains('pvc dwv reducing coupling'),
    englishTerms: const ['reducing coupling', 'reducer coupling'],
    compactReceiptTerms: const ['REDUCING CPLG'],
    spanishTerms: const ['cople'],
    negativeTerms: const ['electrical conduit', 'hvac condensate drain'],
  ),
  _RequiredFamily(
    name: 'pvc sanitary tee',
    selector: (text) => text.contains('pvc dwv sanitary tee'),
    englishTerms: const ['sanitary tee', 'san tee'],
    compactReceiptTerms: const ['SANITARY TEE'],
    spanishTerms: const ['tee sanitaria'],
    negativeTerms: const ['electrical conduit', 'hvac condensate drain'],
  ),
  _RequiredFamily(
    name: 'angle stop and supply stop',
    selector: (text) =>
        text.contains('angle stop') || text.contains('supply stop'),
    englishTerms: const ['angle stop', 'supply stop', 'quarter turn stop'],
    compactReceiptTerms: const ['ANGLE STOP'],
    spanishTerms: const ['llave escuadra', 'valvula cierre'],
    negativeTerms: const ['electrical conduit', 'hvac air filter'],
  ),
  _RequiredFamily(
    name: 'fixture supply lines',
    selector: (text) => text.contains('supply line'),
    englishTerms: const ['supply line', 'faucet supply', 'toilet supply'],
    compactReceiptTerms: const ['SUPPLY LINE'],
    spanishTerms: const ['linea suministro'],
    negativeTerms: const ['electrical conduit', 'hvac air filter'],
  ),
  _RequiredFamily(
    name: 'closet flange repair',
    selector: (text) => text.contains('closet flange'),
    englishTerms: const ['closet flange', 'toilet flange', 'flange repair'],
    compactReceiptTerms: const ['CLOSET FLANGE'],
    spanishTerms: const ['brida sanitario'],
    negativeTerms: const ['electrical conduit', 'hvac air filter'],
  ),
  _RequiredFamily(
    name: 'cleanout access',
    selector: (text) => text.contains('cleanout'),
    englishTerms: const ['cleanout', 'clean out', 'cleanout plug'],
    compactReceiptTerms: const ['CLEANOUT'],
    spanishTerms: const ['registro limpieza'],
    negativeTerms: const ['electrical conduit', 'hvac air filter'],
  ),
  _RequiredFamily(
    name: 'trap adapters',
    selector: (text) => text.contains('trap adapter'),
    englishTerms: const ['trap adapter', 'trap adpt'],
    compactReceiptTerms: const ['TRAP ADPT'],
    spanishTerms: const ['adaptador trampa'],
    negativeTerms: const ['electrical conduit', 'hvac condensate drain'],
  ),
  _RequiredFamily(
    name: 'dwv wyes',
    selector: (text) => text.contains('dwv wye'),
    englishTerms: const ['wye', 'dwv wye'],
    compactReceiptTerms: const ['DWV WYE'],
    spanishTerms: const ['yee sanitaria'],
    negativeTerms: const ['electrical conduit', 'hvac condensate drain'],
  ),
  _RequiredFamily(
    name: 'pex service fittings',
    selector: (text) => text.contains('pex') && text.contains('fitting'),
    englishTerms: const ['pex', 'pex crimp', 'pex fitting'],
    compactReceiptTerms: const ['PEX'],
    spanishTerms: const ['conexion pex'],
    negativeTerms: const ['electrical conduit', 'hvac refrigerant copper'],
  ),
  _RequiredFamily(
    name: 'push-fit service fittings',
    selector: (text) => text.contains('push-fit') || text.contains('sharkbite'),
    englishTerms: const ['push fit', 'push connect', 'sharkbite'],
    compactReceiptTerms: const ['PUSH FIT'],
    spanishTerms: const ['conexion rapida'],
    negativeTerms: const ['electrical connector', 'hvac refrigerant copper'],
  ),
  _RequiredFamily(
    name: 'push-fit ball valves',
    selector: (text) => text.contains('push-fit ball valve'),
    englishTerms: const ['push fit', 'push connect', 'sharkbite', 'valve'],
    compactReceiptTerms: const ['PUSH FIT'],
    spanishTerms: const ['conexion rapida', 'valvula'],
    negativeTerms: const ['electrical connector', 'hvac refrigerant copper'],
  ),
  _RequiredFamily(
    name: 'cpvc service fittings',
    selector: (text) => text.contains('cpvc') && text.contains('fitting'),
    englishTerms: const ['cpvc', 'cpvc flowguard'],
    compactReceiptTerms: const ['CPVC'],
    spanishTerms: const ['cpvc'],
    negativeTerms: const ['electrical conduit', 'hvac condensate drain'],
  ),
  _RequiredFamily(
    name: 'water heater service',
    selector: (text) => text.contains('water heater'),
    englishTerms: const ['water heater', 'heater connector'],
    compactReceiptTerms: const ['WATER HEATER'],
    spanishTerms: const ['calentador agua'],
    negativeTerms: const ['electrical conduit', 'hvac air filter'],
  ),
  _RequiredFamily(
    name: 'well pressure service',
    selector: (text) =>
        text.contains('pressure tank') || text.contains('tank tee'),
    englishTerms: const ['pressure tank', 'tank tee', 'pressure gauge'],
    compactReceiptTerms: const ['PRESSURE TANK'],
    spanishTerms: const ['tanque presion'],
    negativeTerms: const ['electrical conduit', 'hvac air filter'],
  ),
  _RequiredFamily(
    name: 'pipe supports',
    selector: (text) =>
        text.contains('j hook') ||
        text.contains('pipe hook') ||
        text.contains('pipe hanger'),
    englishTerms: const ['j hook', 'pipe hook', 'pipe hanger'],
    compactReceiptTerms: const ['J HOOK'],
    spanishTerms: const ['soporte tubo'],
    negativeTerms: const ['electrical conduit', 'hvac air filter'],
  ),
];

void _expect(
  List<String> failures,
  WorkSupplyItem item,
  bool condition,
  String message,
) {
  if (condition) return;
  failures.add('${item.id} / ${item.path} / ${item.name}: $message');
}
