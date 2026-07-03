import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

class _CoreReceiptFixture {
  const _CoreReceiptFixture(
    this.line,
    this.contains, {
    this.requiredScope = WorkSupplyMarketScope.residential,
  });

  final String line;
  final List<String> contains;
  final WorkSupplyMarketScope requiredScope;
}

void main() {
  test('plumbing US English residential core pack receipt gate', () {
    final failures = <String>[];
    for (final fixture in _coreFixtures) {
      final match = matchReceiptLineToCatalog(
        fixture.line,
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      if (match == null) {
        failures.add('${fixture.line} -> no match');
        continue;
      }

      final item = match.item;
      final name = item.name.toLowerCase();
      final searchableName = '$name ${item.aliases.join(' ').toLowerCase()}';
      for (final term in fixture.contains) {
        if (!searchableName.contains(term)) {
          failures.add('${fixture.line} -> "$name" missing "$term"');
        }
      }
      if (match.confidenceLevel != ReceiptConfidenceLevel.good) {
        failures.add('${fixture.line} -> ${match.confidenceLevel}');
      }
      if (item.packTier != WorkSupplyPackTier.core) {
        failures.add(
          '${fixture.line} -> ${item.packTier.name} not core (${item.path} / ${item.name})',
        );
      }
      if (!item.marketScopes.contains(fixture.requiredScope)) {
        failures.add(
          '${fixture.line} -> missing ${fixture.requiredScope.name} scope',
        );
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}

const _coreFixtures = <_CoreReceiptFixture>[
  _CoreReceiptFixture('LOWES 3/8 X 1/2 ANG STOP QTR TURN', ['angle stop']),
  _CoreReceiptFixture('HD 1/2 PUSH ANGLE STOP 3/8 OUTLET', ['supply stop']),
  _CoreReceiptFixture('ACE 1/2 PEX CRIMP X 3/8 STOP VALVE', ['angle stop']),
  _CoreReceiptFixture('ACE 3/8 X 1/2 FAUCET CONN BRAIDED', [
    'faucet',
    'supply line',
  ]),
  _CoreReceiptFixture('ACE TOILET CONN BRAIDED 3/8 X 7/8', [
    'toilet',
    'supply line',
  ]),
  _CoreReceiptFixture('LOWES 1/2 PEX CRIMP TEE', ['pex', 'tee']),
  _CoreReceiptFixture('MENARDS 1/2 PEX ELB CRIMP', ['pex 90 elbow']),
  _CoreReceiptFixture('LOWES 1/2 PEX MIP ADPT CRIMP', ['pex', 'male adapter']),
  _CoreReceiptFixture('HD 1/2 PEX DROP EAR ELBOW', ['drop-ear']),
  _CoreReceiptFixture('HD SHARKBITE 1/2 SLIP REPAIR COUPLING', [
    'push-fit',
    'slip',
  ]),
  _CoreReceiptFixture('LOWES 1/2 PUSH MIP ADAPTER', ['push-fit', 'male']),
  _CoreReceiptFixture('HD 1/2 COPPER SWEAT MIP ADAPTER', ['copper', 'male']),
  _CoreReceiptFixture('LOWES 3/4 COPPER SWEAT FIP ADAPTER', [
    'copper',
    'female',
  ]),
  _CoreReceiptFixture('LOWES 3/4 CPVC FIP ADAPT CTS', ['cpvc', 'female']),
  _CoreReceiptFixture('HD 1/2 CPVC CTS TEE', ['cpvc', 'tee']),
  _CoreReceiptFixture('HD 1 IN PVC SCH40 TEE', ['pvc schedule 40', 'tee']),
  _CoreReceiptFixture('LOWES PVC S40 3/4 SXF ADAPT', [
    'pvc schedule 40',
    'female',
  ]),
  _CoreReceiptFixture('HD 3 IN PVC DWV WYE', ['pvc dwv', 'wye']),
  _CoreReceiptFixture('HD 3 X 2 PVC DWV REDUCING SAN TEE', [
    'pvc dwv',
    'sanitary tee',
  ]),
  _CoreReceiptFixture('HD 1-1/2 P TRAP WHITE PLASTIC', ['p-trap']),
  _CoreReceiptFixture('LOWES J BEND SLIP JOINT 1-1/2', ['j-bend']),
  _CoreReceiptFixture('HD 1-1/2 BEVELED TRAP WASHER', ['washer']),
  _CoreReceiptFixture('LOWES SLIP JOINT NUT AND WASHER KIT', ['nut', 'washer']),
  _CoreReceiptFixture('WALMART UNIV TOILET FILL VALVE', ['fill valve']),
  _CoreReceiptFixture('TRUE VALUE 3 IN TOILET FLAPPER', ['flapper']),
  _CoreReceiptFixture('HD EXTRA THICK WAX RING BOLTS', ['wax']),
  _CoreReceiptFixture('LOWES TOILET TANK LEVER CHROME', ['tank lever']),
  _CoreReceiptFixture('HD CLOSET BOLTS EXTRA LONG JOHNNY BOLTS', [
    'closet bolt',
  ]),
  _CoreReceiptFixture('LOWES SINGLE HANDLE FAUCET CARTRIDGE', ['cartridge']),
  _CoreReceiptFixture('HD 15/16 FAUCET AERATOR CHR', ['aerator']),
  _CoreReceiptFixture('ACE FAUCET O RING ASSORTMENT', ['o-ring']),
  _CoreReceiptFixture('ACE HOT FAUCET STEM ASSEMBLY', ['faucet stem']),
  _CoreReceiptFixture('FERG WTR HTR 3/4 T&P RELIEF VALVE', ['relief valve']),
  _CoreReceiptFixture('HD 4500W WTR HTR ELEMENT SCREW IN', ['element']),
  _CoreReceiptFixture('SUPPLYHOUSE 42 IN MAG ANODE ROD WH', ['anode rod']),
  _CoreReceiptFixture('LOWES 2 GAL THERMAL EXP TANK', ['expansion tank']),
  _CoreReceiptFixture('HD WATER HEATER DRAIN PAN 24 IN', ['drain pan']),
  _CoreReceiptFixture('HD 3/4 FIP X 3/4 FIP WATER HEATER CONNECTOR', [
    'water heater',
    'connector',
  ]),
  _CoreReceiptFixture('ACE 3/4 HOSE BIBB VAC BRKR', ['vacuum']),
  _CoreReceiptFixture('LOWES 1/2 FIP HOSE BIBB', ['hose bibb']),
  _CoreReceiptFixture('HD 12IN FROST FREE SILLCOCK ANTI SIPHON', ['sillcock']),
  _CoreReceiptFixture('HD PIPE DOPE THREAD SEALANT 4OZ', ['thread sealant']),
  _CoreReceiptFixture('ACE PTFE THREAD TAPE WHITE', ['tape']),
  _CoreReceiptFixture('MENARDS PVC CEMENT CLEAR 8 OZ', ['cement']),
  _CoreReceiptFixture('LOWES PURPLE PRIMER 8 OZ', ['pvc primer']),
  _CoreReceiptFixture('ACE PLUMBER PUTTY 14 OZ', ['plumber putty']),
  _CoreReceiptFixture('MENARDS 1/2 PEX J HOOK PIPE HANGER', ['j-hook']),
  _CoreReceiptFixture('LOWES 3/4 COPPER PIPE STRAP 2 HOLE', ['pipe strap']),
  _CoreReceiptFixture('HD STUD GUARD NAIL PLATE 16GA', ['stud guard']),
  _CoreReceiptFixture('LOWES 1/2 PIPE INSULATION FOAM', ['pipe insulation']),
  _CoreReceiptFixture('HD 1-1/2 FLANGED TAILPIECE CHROME', ['tailpiece']),
  _CoreReceiptFixture('LOWES 1-1/2 TAILPC EXT TUBE', ['extension tube']),
  _CoreReceiptFixture('ACE DISPOSAL DRAIN ELBOW KIT', ['disposal drain elbow']),
  _CoreReceiptFixture('HD DISHWASHER BRANCH TAILPIECE 1-1/2', [
    'dishwasher',
    'tailpiece',
  ]),
  _CoreReceiptFixture('LOWES CONT WASTE DBL BOWL 1-1/2', ['continuous waste']),
  _CoreReceiptFixture('ACE DISPOSAL INSTALL KIT W ELBOW', [
    'disposal',
    'install',
  ]),
  _CoreReceiptFixture('HD DISHWASHER DRAIN HOSE 7/8', ['dishwasher', 'hose']),
  _CoreReceiptFixture('LOWES DISHWASHER AIR GAP CHROME', ['air gap']),
  _CoreReceiptFixture('ACE DISPOSAL SPLASH GUARD RUBBER', ['splash guard']),
  _CoreReceiptFixture('HD DISPOSAL ELBOW GASKET KIT', ['disposal', 'gasket']),
  _CoreReceiptFixture('HD 1-1/2 TRAP ADAPTER PVC', ['trap adapter']),
  _CoreReceiptFixture('LOWES MARVEL ADAPTER 1-1/2', ['marvel adapter']),
  _CoreReceiptFixture('ACE COMPRESSION TRAP ADAPTER 1-1/2', ['trap adapter']),
  _CoreReceiptFixture('HD CLEANOUT PLUG BRASS 3 IN', ['cleanout']),
  _CoreReceiptFixture('LOWES ROUND CLEANOUT COVER', ['cleanout', 'cover']),
  _CoreReceiptFixture('ACE PVC CLEANOUT TEE 3 IN', ['test tee']),
  _CoreReceiptFixture('HD CLOSET FLANGE PVC 4X3', ['closet flange']),
  _CoreReceiptFixture('LOWES CLOSET FLANGE REPAIR RING', [
    'flange repair',
    'repair',
  ]),
  _CoreReceiptFixture('ACE CLOSET FLANGE SPACER 1/4', ['closet flange']),
  _CoreReceiptFixture('HD 3 IN FLUSH VALVE KIT', ['flush valve']),
  _CoreReceiptFixture('LOWES FLUSH VALVE SEAL 3 IN', ['flush valve']),
  _CoreReceiptFixture('ACE TANK TO BOWL BOLT KIT', ['tank bolt']),
  _CoreReceiptFixture('HD TANK TO BOWL GASKET', ['tank', 'gasket']),
  _CoreReceiptFixture('LOWES FILL VALVE SHANK WASHER', ['washer']),
  _CoreReceiptFixture('ACE TOILET SUPPLY SHANK WASHER', ['washer']),
  _CoreReceiptFixture('HD CLOSET BOLT CAP WHITE', ['closet bolt']),
  _CoreReceiptFixture('LOWES TOILET SEAT BOLT SET', ['seat bolt']),
  _CoreReceiptFixture('ACE 5/8 COMPRESSION NUT FERRULE', ['ferrule']),
  _CoreReceiptFixture('HD 3/8 COMP NUT AND SLEEVE', ['ferrule']),
  _CoreReceiptFixture('LOWES COMPRESSION SLEEVE PULLER', [
    'compression',
    'puller',
  ]),
  _CoreReceiptFixture('HD STOP VALVE ESCUTCHEON CHROME', ['escutcheon']),
  _CoreReceiptFixture('ACE SPLIT ESCUTCHEON 1/2 CHR', ['escutcheon']),
  _CoreReceiptFixture('LOWES SUPPLY LINE ESCUTCHEON PLATE', ['escutcheon']),
  _CoreReceiptFixture('HD TUB SPOUT DIVERTER CHROME', ['tub spout']),
  _CoreReceiptFixture('ACE ICE MAKER SUPPLY LINE 1/4', ['ice maker']),
  _CoreReceiptFixture('LOWES FRIDGE WATER LINE KIT', ['ice maker']),
  _CoreReceiptFixture('HD WASHER HOSE 3/4 X 60 IN', ['washing machine']),
  _CoreReceiptFixture('ACE DISHWASHER LINE 3/8 X 60', ['appliance supply']),
  _CoreReceiptFixture('HD PEX CRIMP RING 1/2 25PK', ['crimp ring']),
  _CoreReceiptFixture('LOWES PEX CLAMP RING 3/4 10PK', ['clamp ring']),
  _CoreReceiptFixture('ACE PEX CINCH RING 1/2', ['clamp ring']),
  _CoreReceiptFixture('HD PEX CRIMP TOOL 1/2 3/4', ['crimp tool']),
  _CoreReceiptFixture('LOWES MINI TUBING CUTTER', ['tubing cutter']),
  _CoreReceiptFixture('ACE PVC PIPE CUTTER RATCHET', ['pipe cutter']),
  _CoreReceiptFixture('HD PVC DEBURRING TOOL', ['deburring']),
  _CoreReceiptFixture('LOWES 1/2 CPVC COUPLING CTS', ['cpvc', 'coupling']),
  _CoreReceiptFixture('ACE 3/4 CPVC MIP ADAPTER', ['cpvc', 'male']),
  _CoreReceiptFixture('HD 1/2 PVC SCH40 COUPLING', [
    'pvc schedule 40',
    'coupling',
  ]),
  _CoreReceiptFixture('LOWES 2 IN PVC DWV COUPLING', ['pvc dwv', 'coupling']),
  _CoreReceiptFixture('ACE 1-1/2 PVC DWV TRAP ADAPTER', ['trap adapter']),
];
