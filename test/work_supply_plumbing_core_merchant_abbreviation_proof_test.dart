import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('plumbing core parses merchant-style copper fitting abbreviations', () {
    _expectGoodPlumbingCore('HD 1/2 COP 90 CXC', ['copper', '90']);
    _expectGoodPlumbingCore('LOWES 3/4 CU CPLG WROT', ['copper', 'coupling']);
    _expectGoodPlumbingCore('MENARDS 1/2 COP FIP ADPT', ['copper', 'female']);
    _expectGoodPlumbingCore('FERG 3/4 C X M ADAPTER', ['copper', 'male']);
    _expectGoodPlumbingCore('ACE 1/2 SWEAT TEE COPPER', ['copper', 'tee']);
    _expectGoodPlumbingCore('LOCAL SUPPLY 1 IN COP REPAIR CPLG', [
      'copper',
      'repair',
    ]);
  });

  test('plumbing core parses merchant-style PEX fitting abbreviations', () {
    _expectGoodPlumbingCore('LOWES 1/2 PEX ELB CRMP', ['pex', 'elbow']);
    _expectGoodPlumbingCore('HD 3/4 PEX CPLG POLY', ['pex', 'coupling']);
    _expectGoodPlumbingCore('MENARDS 1/2 PEX TEE CRIMP', ['pex', 'tee']);
    _expectGoodPlumbingCore('FERG 1/2 PEX MIP ADPT', ['pex', 'male']);
    _expectGoodPlumbingCore('WINSUPPLY 3/4 PEX FIP ADPT', ['pex', 'female']);
    _expectGoodPlumbingCore('SUPPLYHOUSE 1/2 PEX DROP EAR ELL', ['drop-ear']);
  });

  test('plumbing core parses merchant-style PVC and CPVC abbreviations', () {
    _expectGoodPlumbingCore('HD 3/4 PVC CPL 3/4 SCH40', [
      'pvc schedule 40',
      'coupling',
    ]);
    _expectGoodPlumbingCore('LOWES PVC S40 1/2 MIP ADPT', [
      'pvc schedule 40',
      'male',
    ]);
    _expectGoodPlumbingCore('MENARDS 1 IN PVC SCH40 TEE', [
      'pvc schedule 40',
      'tee',
    ]);
    _expectGoodPlumbingCore('ACE 1/2 CPVC CTS CPL', ['cpvc', 'coupling']);
    _expectGoodPlumbingCore('FERG 3/4 CPVC FIP ADPT', ['cpvc', 'female']);
    _expectGoodPlumbingCore('LOCAL SUPPLY 1/2 CPVC MIP ADPT', ['cpvc', 'male']);
  });

  test('plumbing core parses merchant-style DWV and ABS abbreviations', () {
    _expectGoodPlumbingCore('HD 2 PVC DWV SAN TEE', ['pvc dwv', 'sanitary']);
    _expectGoodPlumbingCore('LOWES 3 X 2 PVC DWV WYE', ['pvc dwv', 'wye']);
    _expectGoodPlumbingCore('MENARDS 1-1/2 PVC DWV TRAP ADPT', [
      'trap adapter',
    ]);
    _expectGoodPlumbingCore('ACE 2 ABS DWV 90 ELB', ['abs dwv', 'elbow']);
    _expectGoodPlumbingCore('FERG 3 ABS DWV COUPLING', ['abs dwv', 'coupling']);
  });

  test(
    'plumbing core parses merchant-style brass, black iron, and valve abbreviations',
    () {
      _expectGoodPlumbingCore('ACE 3/8 BRASS COMP UN', ['brass', 'union']);
      _expectGoodPlumbingCore('FERG 1/2 BRS MIP ADPT', ['brass', 'male']);
      _expectGoodPlumbingCore('GRAINGER 3/4 BLK IRON NIPPLE', ['black iron']);
      _expectGoodPlumbing('LOCAL SUPPLY 1/2 GALV CPLG', ['galvanized']);
      _expectGoodPlumbingCore('LOWES 3/4 BALL VALVE FIP', ['ball valve']);
      _expectGoodPlumbingCore('HD 3/4 CHECK VALV', ['check valve']);
    },
  );

  test('plumbing core parses merchant-style P-trap and tubular kit lines', () {
    _expectGoodPlumbingCore('LOWES 1-1/2 P-TRAP KIT WHITE', ['p-trap']);
    _expectGoodPlumbingCore('HD 1-1/2 TUBULAR P TRAP', ['p-trap']);
    _expectGoodPlumbingCore('MENARDS 1-1/4 LAV P TRAP', ['p-trap']);
    _expectGoodPlumbingCore('FERG 1-1/2 SJ P TRAP PVC', ['p-trap']);
    _expectGoodPlumbingCore('ACE 1-1/2 SLIP JOINT P TRAP KIT', ['p-trap']);
    _expectGoodPlumbingCore('LOCAL HARDWARE 1-1/2 J BEND TUBULAR', ['j-bend']);
  });

  test('plumbing core parses merchant-style faucet repair kit lines', () {
    _expectGoodPlumbingCore('LOWES SINGLE HANDLE FAUCET CART', ['cartridge']);
    _expectGoodPlumbingCore('HD FAUCET STEM HOT REPAIR', ['faucet stem']);
    _expectGoodPlumbingCore('MENARDS FAUCET O RING ASSORT', ['o-ring']);
    _expectGoodPlumbingCore('ACE FAUCET SEAT WASHER KIT', ['washer']);
    _expectGoodPlumbingCore('TRUE VALUE 15/16 FCT AERATOR CHR', ['aerator']);
    _expectGoodPlumbingCore('LOCAL SUPPLY LAV POP UP ROD KIT', ['pop-up']);
  });

  test(
    'plumbing core parses farm-ranch and tool-store plumbing-adjacent lines',
    () {
      _expectGoodPlumbingCore('TRACTOR SUPPLY WELL PRESSURE GAUGE 100 PSI', [
        'pressure gauge',
      ]);
      _expectGoodPlumbingCore('TSC 1 IN POLY BARB ADAPTER', ['barb']);
      _expectGoodPlumbingCore('NORTHERN TOOL PVC PIPE CUTTER RATCHET', [
        'pipe cutter',
      ]);
      _expectGoodPlumbingCore('N TOOL MINI TUBING CUTTER', ['tubing cutter']);
    },
  );

  test(
    'plumbing core parses supply-house valve and pressure-control lines',
    () {
      _expectGoodPlumbingCore('FERG 3/4 PRV PRESS RED VALVE', [
        'pressure reducing valve',
      ]);
      _expectGoodPlumbingCore('WINSUPPLY 1/2 ANG STOP COMP X OD', [
        'angle stop',
      ]);
      _expectGoodPlumbingCore('SUPPLYHOUSE 3/4 VAC BREAKER HOSE BIBB', [
        'vacuum',
      ]);
      _expectGoodPlumbingCore('LOCAL SUPPLY 3/4 GATE VALV FIP', ['gate valve']);
      _expectGoodPlumbingCore('TRUE VALUE 1/2 BOILER DRAIN VALVE', [
        'drain valve',
      ]);
    },
  );

  test('plumbing core parses local supply drain and no-hub repair lines', () {
    _expectGoodPlumbingCore('LOCAL SUPPLY 2IN NO HUB COUPLING', ['no-hub']);
    _expectGoodPlumbingCore('FERG 3 X 2 FERNCO RED CPLG', ['fernco']);
    _expectGoodPlumbingCore('WINSUPPLY 4 PVC DWV CLEANOUT PLUG', ['cleanout']);
    _expectGoodPlumbingCore('ACE 1-1/2 TRAP ADAPTER SJ PVC', ['trap adapter']);
    _expectGoodPlumbingCore('TRUE VALUE 2IN RUBBER COUPLING', ['rubber']);
  });

  test('plumbing core parses water treatment and well-service local lines', () {
    _expectGoodPlumbingCore('LOCAL SUPPLY WATER SOFTENER SALT 40LB', [
      'softener',
    ]);
    _expectGoodPlumbingCore('RURAL KING WELL PRESSURE SWITCH 40/60', [
      'pressure switch',
    ]);
    _expectGoodPlumbingCore('TRACTOR SUPPLY 1IN POLY INSERT COUPLING', [
      'poly',
    ]);
    _expectGoodPlumbingCore('FERG 10IN SEDIMENT FILTER CART', ['sediment']);
    _expectGoodPlumbingCore('SUPPLYHOUSE 3/4 WELL CHECK VALVE', [
      'check valve',
    ]);
  });

  test('plumbing core handles OCR-damaged local supply abbreviations', () {
    _expectGoodPlumbingCore('L0CAL SUPPLY 1/2 C0P 90 ELL CXC', [
      'copper',
      '90',
    ]);
    _expectGoodPlumbingCore('FERG 3/4 PEX C0UP CR1MP', ['pex', 'coupling']);
    _expectGoodPlumbingCore('WINSUPPLY 1/2 CPVC F1P ADPT', ['cpvc', 'female']);
    _expectGoodPlumbingCore('ACE 1 1/2 P TRAP K1T', ['p-trap']);
    _expectGoodPlumbingCore('TRUE VALUE 3/4 BALL VALV FlP', ['ball valve']);
  });

  test('plumbing core parses toilet repair and flange service lines', () {
    _expectGoodPlumbingCore('ACE UNIV TOILET FILL VALVE', ['fill valve']);
    _expectGoodPlumbingCore('TRUE VALUE 3IN TOILET FLAPPER', ['flapper']);
    _expectGoodPlumbingCore('LOCAL HW CLOSET WAX RING BOLTS', ['wax ring']);
    _expectGoodPlumbingCore('FERG TOILET TANK BOLT KIT', ['tank bolt']);
    _expectGoodPlumbingCore('WINSUPPLY TOILET FLANGE REPAIR RING', ['flange']);
  });

  test('plumbing core parses sealant and tape receipt lines', () {
    _expectGoodPlumbingCore('ACE PIPE DOPE PTFE PASTE', ['thread sealant']);
    _expectGoodPlumbingCore('TRUE VALUE WHITE PTFE THREAD TAPE', ['ptfe']);
    _expectGoodPlumbingCore('LOCAL SUPPLY GAS LINE THREAD SEALANT', [
      'thread sealant',
    ]);
    _expectGoodPlumbingCore('FERG YELLOW GAS PTFE TAPE', ['ptfe']);
    _expectGoodPlumbingCore('WINSUPPLY PIPE JOINT COMPOUND', [
      'thread sealant',
    ]);
  });

  test('plumbing core parses water-heater service receipt lines', () {
    _expectGoodPlumbingCore('ACE 4500W WH ELEMENT', ['element']);
    _expectGoodPlumbingCore('TRUE VALUE WATER HTR ANODE ROD', ['anode']);
    _expectGoodPlumbingCore('LOCAL SUPPLY WTR HTR DIELECTRIC NIPPLE', [
      'dielectric',
    ]);
    _expectGoodPlumbingCore('FERG WTR HTR SUPPLY CONNECTOR 3/4X18', [
      'water heater',
    ]);
    _expectGoodPlumbingCore('WINSUPPLY T&P RELIEF VALVE 3/4', ['relief valve']);
  });

  test('plumbing core parses supply-line and appliance connector receipts', () {
    _expectGoodPlumbingCore('ACE 3/8X16 FAUCET SUPPLY LINE', ['faucet']);
    _expectGoodPlumbingCore('TRUE VALUE 3/8X12 TOILET CONN', ['toilet']);
    _expectGoodPlumbingCore('LOCAL SUPPLY ICEMAKER LINE 1/4X10FT', [
      'ice maker',
    ]);
    _expectGoodPlumbingCore('FERG WASHER HOSE 3/4X5FT', ['washing machine']);
    _expectGoodPlumbingCore('WINSUPPLY GAS FLEX CONN 1/2X36', [
      'gas appliance',
    ]);
  });

  test('plumbing core parses solvent, putty, and silicone receipts', () {
    _expectGoodPlumbingCore('ACE PVC GLUE 8OZ', ['pvc cement']);
    _expectGoodPlumbingCore('TRUE VALUE PURPLE PRIMER 4OZ', ['pvc primer']);
    _expectGoodPlumbingCore('LOCAL SUPPLY CPVC YELLOW GLUE 8OZ', [
      'cpvc cement',
    ]);
    _expectGoodPlumbingCore('FERG PLUMBERS PUTTY 14OZ', ['putty']);
    _expectGoodPlumbingCore('WINSUPPLY CLEAR SILICONE KITCHEN BATH 10OZ', [
      'silicone',
    ]);
  });

  test('plumbing core parses Spanish and mixed-language receipt lines', () {
    _expectGoodPlumbingCore('FERRETERIA 1/2 COBRE CODO 90', ['copper', '90']);
    _expectGoodPlumbingCore('SUMINISTRO VALVULA LLENADO WC UNIVERSAL', [
      'fill valve',
    ]);
    _expectGoodPlumbingCore('LOCAL TRAMPA P LAVABO 1-1/2', ['p-trap']);
    _expectGoodPlumbingCore('FERG CINTA TEFLON ROSCA BLANCA', ['ptfe']);
    _expectGoodPlumbingCore('WINSUPPLY VALVULA ALIVIO T&P 3/4', [
      'relief valve',
    ]);
  });

  test('plumbing core parses POS noise with quantities and prices', () {
    _expectGoodPlumbingCore('HD 188742 2 @ 1.98 1/2 COP 90 CXC 3.96', [
      'copper',
      '90',
    ]);
    _expectGoodPlumbingCore('LOWES 32144 3/4 PVC SCH40 CPLG 2EA 4.28', [
      'pvc schedule 40',
      'coupling',
    ]);
    _expectGoodPlumbingCore('MENARDS SKU 8812 1-1/2 PVC DWV P TRAP 8.99', [
      'p-trap',
    ]);
    _expectGoodPlumbingCore('FERG QTY1 3/4 PRV PRESS RED VALVE 89.00', [
      'pressure reducing valve',
    ]);
    _expectGoodPlumbingCore('ACE DISC -1.00 3/8X12 TOILET CONN 6.49', [
      'toilet',
    ]);
  });

  test(
    'plumbing core keeps ultra-vague merchant abbreviations out of good confidence',
    () {
      _expectNotGoodPlumbing('LOWES 1/2 C X C');
      _expectNotGoodPlumbing('HD 3/4 ADPT');
      _expectNotGoodPlumbing('MENARDS REPAIR KIT');
    },
  );
}

void _expectGoodPlumbingCore(String line, List<String> expectedTerms) {
  final match = _expectGoodPlumbing(line, expectedTerms);
  expect(
    match.item.packTier,
    WorkSupplyPackTier.core,
    reason: '$line -> ${match.item.name}',
  );
}

ReceiptLineMatch _expectGoodPlumbing(String line, List<String> expectedTerms) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'Plumbing',
    maxCandidates: 420,
  );
  expect(match, isNotNull, reason: line);
  expect(
    match!.confidenceLevel,
    ReceiptConfidenceLevel.good,
    reason: '$line -> ${match.item.name} (${match.confidence})',
  );
  expect(match.item.trade, 'Plumbing', reason: line);

  final searchable = [
    match.item.name,
    match.item.system,
    match.item.itemType,
    match.item.variant,
    ...match.item.aliases,
  ].join(' ').toLowerCase();
  for (final term in expectedTerms) {
    expect(searchable, contains(term), reason: '$line -> ${match.item.name}');
  }
  return match;
}

void _expectNotGoodPlumbing(String line) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'Plumbing',
    maxCandidates: 420,
  );
  if (match == null) {
    return;
  }
  expect(
    match.confidenceLevel,
    isNot(ReceiptConfidenceLevel.good),
    reason: line,
  );
}
