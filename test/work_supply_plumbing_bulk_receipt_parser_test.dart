import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

class _ReceiptFixture {
  // ignore: unused_element_parameter
  const _ReceiptFixture(this.line, this.contains, {this.excludes = const []});

  final String line;
  final List<String> contains;
  final List<String> excludes;
}

void main() {
  test('plumbing US English bulk receipt parser sweep', () {
    final failures = <String>[];
    for (final fixture in _fixtures) {
      final match = matchReceiptLineToCatalog(
        fixture.line,
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      if (match == null) {
        failures.add('${fixture.line} -> no match');
        continue;
      }

      final name = match.item.name.toLowerCase();
      for (final term in fixture.contains) {
        if (!name.contains(term)) {
          failures.add('${fixture.line} -> "$name" missing "$term"');
        }
      }
      for (final term in fixture.excludes) {
        if (name.contains(term)) {
          failures.add('${fixture.line} -> "$name" should not contain "$term"');
        }
      }
      if (match.confidenceLevel != ReceiptConfidenceLevel.good) {
        failures.add('${fixture.line} -> ${match.confidenceLevel}');
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}

const _fixtures = <_ReceiptFixture>[
  _ReceiptFixture('LOWES 3/8 X 1/2 ANG STOP QTR TURN', ['angle stop']),
  _ReceiptFixture('HD 3/4 PRESS RED VALVE PRV', ['pressure reducing']),
  _ReceiptFixture('ACE 3/4 HOSE BIBB VAC BRKR', ['vacuum']),
  _ReceiptFixture('FERG WTR HTR 3/4 T&P RELIEF VALVE', ['relief valve']),
  _ReceiptFixture('SUPPLYHOUSE 42 IN MAG ANODE ROD WH', ['anode rod']),
  _ReceiptFixture('HD 4500W WTR HTR ELEMENT SCREW IN', ['element']),
  _ReceiptFixture('WALMART UNIV TOILET FILL VALVE', ['fill valve']),
  _ReceiptFixture('TRUE VALUE 3 IN TOILET FLAPPER', ['flapper']),
  _ReceiptFixture('LOWES SINGLE HANDLE FAUCET CARTRIDGE', ['cartridge']),
  _ReceiptFixture('HD EXTRA THICK WAX RING BOLTS', ['wax']),
  _ReceiptFixture('MENARDS PVC CEMENT CLEAR 8 OZ', ['cement']),
  _ReceiptFixture('ACE PTFE THREAD TAPE WHITE', ['tape']),
  _ReceiptFixture('HD PIPE DOPE THREAD SEALANT 4OZ', ['thread sealant']),
  _ReceiptFixture('LOWES YELLOW GAS PTFE TAPE', ['ptfe']),
  _ReceiptFixture('FERG PIPE LUBE GASKET LUBRICANT', ['lubricant']),
  _ReceiptFixture('LOWES 1/2 PEX MIP ADPT CRIMP', ['pex', 'male adapter']),
  _ReceiptFixture('HD 3/4 CPVC FIP ADAPT CTS', ['cpvc', 'female adapter']),
  _ReceiptFixture('ACE 3/8 X 1/2 FAUCET CONN BRAIDED', [
    'faucet',
    'supply line',
  ]),
  _ReceiptFixture('LOWES 1/2 PEX CRIMP TEE', ['pex', 'tee']),
  _ReceiptFixture('HD 1/2 PEX DROP EAR ELBOW', ['drop-ear']),
  _ReceiptFixture('HD SHARKBITE 1/2 SLIP REPAIR COUPLING', [
    'push-fit',
    'slip',
  ]),
  _ReceiptFixture('LOWES 1/2 PUSH MIP ADAPTER', ['push-fit', 'male adapter']),
  _ReceiptFixture('ACE 1/2 PUSH FIP ADAPTER', ['push-fit', 'female adapter']),
  _ReceiptFixture('HD 1/2 PUSH ANGLE STOP 3/8 OUTLET', [
    'push-fit',
    'supply stop',
  ]),
  _ReceiptFixture('LOWES 1/2 COPPER NO STOP REPAIR COUPLING', [
    'copper',
    'repair',
  ]),
  _ReceiptFixture('HD 3/4 COPPER MIP ADAPTER', ['copper', 'male adapter']),
  _ReceiptFixture('ACE 1/2 COPPER FIP ADAPTER', ['copper', 'female adapter']),
  _ReceiptFixture('HD 1/2 CPVC CTS TEE', ['cpvc', 'tee']),
  _ReceiptFixture('LOWES CPVC TRANSITION COUPLING', ['cpvc', 'transition']),
  _ReceiptFixture('ACE 3/4 CPVC BUSHING', ['cpvc', 'bushing']),
  _ReceiptFixture('HD 2 IN PVC S40 TEE', ['pvc schedule 40', 'tee']),
  _ReceiptFixture('LOWES 1-1/2 PVC SLIP X FIP ADAPTER', [
    'pvc schedule 40',
    'female adapter',
  ]),
  _ReceiptFixture('ACE PVC SPIGOT BUSHING 2 X 1-1/2', [
    'pvc schedule 40',
    'bushing',
  ]),
  _ReceiptFixture('HD 3 IN PVC DWV WYE', ['pvc dwv', 'wye']),
  _ReceiptFixture('LOWES PVC DWV REDUCING SAN TEE', [
    'pvc dwv',
    'sanitary tee',
  ]),
  _ReceiptFixture('ACE PVC DWV TEST TEE', ['pvc dwv', 'test tee']),
  _ReceiptFixture('HD ABS SAN TEE 1-1/2', ['abs dwv', 'sanitary tee']),
  _ReceiptFixture('LOWES ABS CLEANOUT PLUG', ['abs dwv', 'cleanout']),
  _ReceiptFixture('FERG NO HUB REDUCER 4 X 3', ['reducing no-hub']),
  _ReceiptFixture('HD CAST IRON DONUT GASKET 4 IN', ['compression gasket']),
  _ReceiptFixture('LOWES NO HUB BAND CLAMP 2 IN', ['band clamp']),
  _ReceiptFixture('ACE 3/4 BLACK IRON TEE', ['black iron', 'tee']),
  _ReceiptFixture('HD BLACK PIPE UNION 1/2', ['black iron', 'union']),
  _ReceiptFixture('LOWES BLACK IRON BUSHING 3/4 X 1/2', [
    'black iron',
    'bushing',
  ]),
  _ReceiptFixture('ACE TOILET CONN BRAIDED 3/8 X 7/8', [
    'toilet',
    'supply line',
  ]),
  _ReceiptFixture('HD ICE MAKER SUPPLY LINE 25 FT', ['ice maker']),
  _ReceiptFixture('LOWES WASHING MACHINE HOSE 2PK', ['washing machine']),
  _ReceiptFixture('ACE STRAIGHT STOP 1/2 X 3/8', ['straight stop']),
  _ReceiptFixture('HD COMP NUT FERRULE 3/8', ['ferrule']),
  _ReceiptFixture('LOWES ESCUTCHEON PLATE 1/2 CHROME', ['escutcheon']),
  _ReceiptFixture('LOWES 7/8 DISHWASHER DRAIN HOSE', ['dishwasher', 'hose']),
  _ReceiptFixture('HD DISHWASHER BRANCH TAILPIECE', [
    'dishwasher',
    'tailpiece',
  ]),
  _ReceiptFixture('ACE DISHWASHER AIR GAP CHROME CAP', ['air gap']),
  _ReceiptFixture('LOWES DISPOSAL ELBOW GASKET KIT', ['disposal', 'gasket']),
  _ReceiptFixture('HD 1-1/2 BEVELED TRAP WASHER', ['washer']),
  _ReceiptFixture('ACE RUBBER REDUCING WASHER 1-1/2 X 1-1/4', ['washer']),
  _ReceiptFixture('LOWES SLIP JOINT NUT AND WASHER KIT', ['nut', 'washer']),
  _ReceiptFixture('GRAINGER 3/8 STRUT NUT 25PK', ['strut nut']),
  _ReceiptFixture('HD 3/8 ROD COUPLING NUT 10PK', ['coupling nut']),
  _ReceiptFixture('LOWES 1/4 X 2-1/4 TAPCON BLUE SCREW', ['concrete screw']),
  _ReceiptFixture('FERG 3/8 WEDGE ANCHOR ROD HANGER', ['wedge anchor']),
  _ReceiptFixture('HD 2 IN PIPE RISER CLAMP', ['riser clamp']),
  _ReceiptFixture('LOWES 1/2 PIPE INSULATION FOAM', ['pipe insulation']),
  _ReceiptFixture('HD STUD GUARD NAIL PLATE 16GA', ['stud guard']),
  _ReceiptFixture('FERG 1/2 SPLIT RING PIPE HANGER', ['split ring']),
  _ReceiptFixture('ACE 3/4 BELL HANGER COPPER', ['bell hanger']),
  _ReceiptFixture('MENARDS 1/2 PEX J HOOK PIPE HANGER', ['j-hook']),
  _ReceiptFixture('LOWES 3/4 COPPER PIPE STRAP 2 HOLE', ['pipe strap']),
  _ReceiptFixture('HD 4 IN CO COVER CLEANOUT PLATE', ['cleanout', 'cover']),
  _ReceiptFixture('HD WATER HEATER DRAIN PAN 24 IN', ['drain pan']),
  _ReceiptFixture('LOWES THERMAL EXPANSION TANK 2 GAL', ['expansion tank']),
  _ReceiptFixture('ACE GAS WATER HEATER SEDIMENT TRAP KIT', ['sediment trap']),
  _ReceiptFixture('HD 1/3 HP SUMP PUMP', ['sump pump']),
  _ReceiptFixture('LOWES CONDENSATE REMOVAL PUMP', ['condensate pump']),
  _ReceiptFixture('ACE SUMP PUMP CHECK VALVE 1-1/2', ['check valve']),
  _ReceiptFixture('HD SUMP PUMP DISCHARGE HOSE KIT', ['discharge hose']),
  _ReceiptFixture('LOWES TETHERED FLOAT SWITCH SUMP', ['float switch']),
  _ReceiptFixture('ACE WATER HTR EARTHQUAKE STRAP KIT', ['strap']),
  _ReceiptFixture('LOWES 1/2 FIP HOSE BIBB', ['hose bibb']),
  _ReceiptFixture('HD 12IN FROST FREE SILLCOCK ANTI SIPHON', ['sillcock']),
  _ReceiptFixture('LOWES TOILET TANK LEVER CHROME', ['tank lever']),
  _ReceiptFixture('LOWES 3/4 DIELECTRIC UNION WTR HTR', ['dielectric']),
  _ReceiptFixture('HD 15/16 FAUCET AERATOR CHR', ['aerator']),
  _ReceiptFixture('ACE FAUCET O RING ASSORTMENT', ['o-ring']),
  _ReceiptFixture('FERG STEM PACKING VALVE REPAIR', ['stem packing']),
  _ReceiptFixture('HD 1-1/2 PVC DWV TRAP ADAPTER', ['trap adapter']),
  _ReceiptFixture('LOWES 1-1/2 MARVEL ADAPTER TUBULAR', ['marvel']),
  _ReceiptFixture('MENARDS 1/2 PEX ELB CRIMP', ['pex 90 elbow']),
  _ReceiptFixture('THE HOME DEPOT 3/4 SHARKBITE PUSH COUP', [
    'push-fit',
    'coupling',
  ]),
  _ReceiptFixture('GRAINGER 2 IN BRASS CO PLUG COUNTERSUNK', [
    'cleanout',
    'plug',
  ]),
  _ReceiptFixture('SUPPLYHOUSE 1/2 BI NIP 6 IN', ['black iron', 'nipple']),
  _ReceiptFixture('WINSUPPLY 1-1/2 ABS DWV WYE BLACK DRAIN', [
    'abs dwv',
    'wye',
  ]),
  _ReceiptFixture('HAJOCA 3/8 X 1/2 ANG STOP QTR TURN', ['angle stop']),
  _ReceiptFixture('REECE 2 GAL THERM EXP TANK WH', ['expansion tank']),
  _ReceiptFixture('F W WEBB 42 IN MAG ANODE ROD WTR HTR', ['anode rod']),
  _ReceiptFixture('LOWES PVC S40 3/4 SXF ADAPT', [
    'pvc schedule 40',
    'female adapter',
  ]),
  _ReceiptFixture('HD PRO 1/2 CPV C COUPLING', ['cpvc', 'coupling']),
  _ReceiptFixture('FERG 3 IN NH CPLG SHIELDED', ['no-hub']),
  _ReceiptFixture('CORE MAIN 4IN X 25FT CORR DRAIN PIPE', [
    'corrugated drain pipe',
  ]),
  _ReceiptFixture('SUPPLYHOUSE 4 X 3 PVC CLOSET FLG', ['closet flange']),
  _ReceiptFixture('REECE TUB WASTE OVERFLOW TRIP LEVER', ['waste']),
  _ReceiptFixture('HD 2 IN FLUSH VALVE KIT', ['flush valve']),
  _ReceiptFixture('LOWES DUAL FLUSH TOILET VALVE KIT', ['flush valve']),
  _ReceiptFixture('ACE TANK TO BOWL BOLT GASKET KIT', ['tank bolt']),
  _ReceiptFixture('HD CLOSET BOLTS EXTRA LONG JOHNNY BOLTS', ['closet bolt']),
  _ReceiptFixture('LOWES TOILET FLANGE SPACER 1/2 IN', ['flange spacer']),
  _ReceiptFixture('ACE SPLIT TOILET FLANGE REPAIR RING', ['flange repair']),
  _ReceiptFixture('HD WAX FREE TOILET SEAL', ['wax']),
  _ReceiptFixture('LOWES 2 IN TOILET FLAPPER UNIVERSAL', ['flapper']),
  _ReceiptFixture('HD 3/4 WATER HEATER VACUUM RELIEF VALVE', ['vacuum relief']),
  _ReceiptFixture('LOWES EXPANSION TANK MOUNTING BRACKET', ['expansion tank']),
  _ReceiptFixture('ACE 3/4 DIELECTRIC NIPPLE PAIR', ['dielectric nipple']),
  _ReceiptFixture('HD UPPER WATER HEATER THERMOSTAT', ['thermostat']),
  _ReceiptFixture('LOWES LOWER WTR HTR THERMOSTAT', ['thermostat']),
  _ReceiptFixture('ACE WATER HEATER TUNE UP KIT ELEMENT THERMOSTAT', [
    'tune-up',
  ]),
  _ReceiptFixture('FERG 3/4 BALL DRAIN VALVE WATER HEATER', ['drain valve']),
  _ReceiptFixture('HD 3/4 FIP X 3/4 FIP WATER HEATER CONNECTOR', [
    'water heater',
    'connector',
  ]),
  _ReceiptFixture('LOWES POP UP DRAIN ASSEMBLY CHROME', ['pop-up']),
  _ReceiptFixture('ACE LAV DRAIN WITH OVERFLOW', ['lavatory drain']),
  _ReceiptFixture('HD KITCHEN BASKET STRAINER DEEP CUP', ['basket strainer']),
  _ReceiptFixture('LOWES DISPOSAL FLANGE AND STOPPER', ['disposal flange']),
  _ReceiptFixture('ACE TUBULAR WALL TUBE CHROME 1-1/2', ['wall tube']),
  _ReceiptFixture('HD 1-1/2 P TRAP WHITE PLASTIC', ['p-trap']),
  _ReceiptFixture('LOWES J BEND SLIP JOINT 1-1/2', ['j-bend']),
  _ReceiptFixture('ACE FLANGED TAILPIECE 1-1/2 CHROME', ['tailpiece']),
  _ReceiptFixture('HD CONTINUOUS WASTE DISHWASHER BRANCH', [
    'continuous waste',
  ]),
  _ReceiptFixture('LOWES DISPOSAL INSTALL KIT WITH ELBOW', ['disposal']),
  _ReceiptFixture('ACE 5/8 COMPRESSION NUT FERRULE 2PK', ['ferrule']),
  _ReceiptFixture('HD STOP VALVE ESCUTCHEON SPLIT', ['escutcheon']),
  _ReceiptFixture('LOWES OVAL HANDLE STOP REPAIR', ['handle']),
  _ReceiptFixture('ACE COMPRESSION SLEEVE PULLER', ['sleeve puller']),
  _ReceiptFixture('HD 1/2 FIP X 3/8 OD ANGLE STOP LEVER HANDLE', [
    'angle stop',
  ]),
  _ReceiptFixture('LOWES 5/8 OD X 3/8 OD STRAIGHT STOP', ['straight stop']),
  _ReceiptFixture('ACE 1/2 PEX CRIMP X 3/8 STOP VALVE', ['angle stop']),
  _ReceiptFixture('HD 3/8 X 60 DISHWASHER SUPPLY LINE', [
    'appliance supply line',
  ]),
  _ReceiptFixture('LOWES 1/2 X 48 GAS FLEX CONNECTOR', [
    'gas appliance connector',
  ]),
  _ReceiptFixture('ACE 1/4 X 10 FT ICEMAKER POLY LINE', ['ice maker']),
  _ReceiptFixture('HD 3/4 X 5 FT WASHER SUPPLY HOSE', ['washing machine']),
  _ReceiptFixture('LOWES FAUCET SCREEN AERATOR 55/64', ['aerator']),
  _ReceiptFixture('ACE HOT FAUCET STEM ASSEMBLY', ['faucet stem']),
  _ReceiptFixture('HD COLD STEM FAUCET VALVE STEM', ['faucet stem']),
  _ReceiptFixture('LOWES DIVERTER FAUCET STEM', ['faucet stem']),
  _ReceiptFixture('HD PRESSURE BALANCE SHOWER CARTRIDGE', ['shower cartridge']),
  _ReceiptFixture('LOWES SHOWER TRIM KIT SINGLE HANDLE', ['shower valve trim']),
  _ReceiptFixture('ACE HANDHELD SHOWERHEAD', ['shower head']),
  _ReceiptFixture('HD 6 IN SHOWER ARM CHROME', ['shower arm']),
  _ReceiptFixture('LOWES TUB DRAIN KIT TOE TOUCH', ['waste and overflow']),
  _ReceiptFixture('ACE TUB DRAIN SHOE 1-1/2', ['tub drain shoe']),
  _ReceiptFixture('HD LIFT AND TURN TUB STOPPER', ['tub drain stopper']),
  _ReceiptFixture('LOWES ROUND CLEANOUT COVER 4 IN', ['cleanout', 'cover']),
  _ReceiptFixture('ACE SQUARE CLEANOUT COVER 3 IN', ['cleanout', 'cover']),
  _ReceiptFixture('HD BRASS CLEANOUT PLUG 2 IN', ['cleanout', 'plug']),
  _ReceiptFixture('LOWES FLOOR DRAIN GRATE ROUND 3 IN', ['floor drain']),
  _ReceiptFixture('ACE SNAP IN FLOOR DRAIN STRAINER', ['floor drain']),
  _ReceiptFixture('HD TRAP PRIMER ADAPTER FLOOR DRAIN', ['trap primer']),
  _ReceiptFixture('LOWES CLOSET FLANGE EXTENSION KIT', ['flange']),
  _ReceiptFixture('ACE CLOSET BOLT REPAIR KIT', ['closet bolt']),
  _ReceiptFixture('HD WHITE CLOSET BOLT CAPS', ['closet bolt caps']),
  _ReceiptFixture('LOWES SUPPLY LINE ESCUTCHEON CHROME', ['escutcheon']),
  _ReceiptFixture('ACE 3/8 ALL THREAD ROD 6 FT', ['threaded rod']),
  _ReceiptFixture('HD 3/8 THREADED ROD 10 FT', ['threaded rod']),
  _ReceiptFixture('LOWES 3/8 HEX NUT 100 PACK', ['hex nut']),
  _ReceiptFixture('ACE 3/8 FENDER WASHER 100PK', ['fender washer']),
  _ReceiptFixture('HD 3/8 DROP IN ANCHOR', ['drop-in anchor']),
  _ReceiptFixture('LOWES 3/8 BEAM CLAMP ROD HANGER', ['beam clamp']),
  _ReceiptFixture('ACE 3/8 CEILING FLANGE', ['ceiling flange']),
  _ReceiptFixture('HD 1/2 TYPE L COPPER PIPE 10FT', ['copper pipe']),
  _ReceiptFixture('LOWES 3/4 TYPE M COPPER STICK', ['copper pipe']),
  _ReceiptFixture('ACE 1/2 SOFT COPPER ROLL 20 FT', ['soft copper tubing']),
  _ReceiptFixture('HD 1/2 PEX B TUBING 100 FT', ['pex tubing']),
  _ReceiptFixture('LOWES 3/4 PEX A ROLL 100FT', ['pex tubing']),
  _ReceiptFixture('ACE 1/2 CPVC PIPE 10 FT', ['cpvc pipe']),
  _ReceiptFixture('HD 3/4 PVC SCH40 PRESSURE PIPE', ['pvc schedule 40 pipe']),
  _ReceiptFixture('LOWES 3 IN PVC DWV DRAIN PIPE', ['pvc dwv pipe']),
  _ReceiptFixture('ACE 2 IN ABS BLACK DRAIN PIPE', ['abs dwv pipe']),
  _ReceiptFixture('HD 4 IN X 50 FT CORRUGATED PIPE', ['corrugated drain pipe']),
  _ReceiptFixture('LOWES 1-1/4 TUBULAR P TRAP', ['p-trap']),
  _ReceiptFixture('ACE SINK TRAP 1-1/2 WHITE', ['p-trap']),
  _ReceiptFixture('HD 1-1/2 TAILPIECE EXTENSION TUBE', ['extension tube']),
  _ReceiptFixture('LOWES LAV TAILPIECE 1-1/4 CHROME', ['tailpiece']),
  _ReceiptFixture('ACE DISPOSAL DRAIN ELBOW 1-1/2', ['disposal drain elbow']),
  _ReceiptFixture('HD 1/2 HP SUBMERSIBLE SUMP PUMP', ['sump pump']),
  _ReceiptFixture('LOWES 3/4 HP SUMP PUMP', ['sump pump']),
  _ReceiptFixture('ACE VERTICAL SUMP FLOAT SWITCH', ['float switch']),
  _ReceiptFixture('HD PIGGYBACK PUMP FLOAT SWITCH', ['float switch']),
  _ReceiptFixture('LOWES CONDENSATE VINYL TUBING 3/8 X 20', [
    'condensate pump tubing',
  ]),
  _ReceiptFixture('ACE 1-1/4 PUMP CHECK VALVE', ['pump check valve']),
  _ReceiptFixture('HD 1-1/4 X 24 SUMP PUMP HOSE KIT', ['discharge hose']),
  _ReceiptFixture('LOWES PIPE JOINT COMPOUND 8 OZ', ['pipe joint compound']),
  _ReceiptFixture('ACE THREAD PASTE 4OZ', ['pipe joint compound']),
  _ReceiptFixture('HD TFE PASTE PIPE DOPE', ['pipe joint compound']),
  _ReceiptFixture('LOWES PURPLE PRIMER 8 OZ', ['pvc primer']),
  _ReceiptFixture('ACE PVC PRIMER 32OZ', ['pvc primer']),
  _ReceiptFixture('HD CPVC YELLOW GLUE 8 OZ', ['cpvc cement']),
  _ReceiptFixture('LOWES PVC SOLVENT CEMENT 16 OZ', ['pvc cement']),
  _ReceiptFixture('ACE PLUMBER PUTTY 14 OZ', ['plumber putty']),
  _ReceiptFixture('HD SINK PUTTY 32 OZ', ['plumber putty']),
  _ReceiptFixture('LOWES KITCHEN BATH SILICONE WHITE', ['silicone sealant']),
  _ReceiptFixture('ACE CLEAR SILICONE CAULK 10 OZ', ['silicone sealant']),
  _ReceiptFixture('HD 1 GAL PIPE LUBE', ['pipe lubricant']),
  _ReceiptFixture('LOWES 1 QT GASKET LUBRICANT', ['pipe lubricant']),
  _ReceiptFixture('ACE 1/2 TEFLON TAPE ROLL', ['ptfe thread tape']),
  _ReceiptFixture('HD 3/4 GAS THREAD TAPE YELLOW', ['ptfe thread tape']),
];
