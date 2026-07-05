import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_audit.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('hvac pack has expanded first-pass service coverage', () {
    final audit = auditWorkSupplyCatalog();
    final hvac = audit.tradeCoverage.singleWhere(
      (coverage) => coverage.tradeName == 'HVAC',
    );

    expect(hvac.itemCount, greaterThanOrEqualTo(550));
    expect(hvac.aliasCoverage, greaterThan(.70));
    expect(hvac.parserReadinessLabel, 'Strong');
  });

  test('hvac parser understands capacitor and contactor shorthand', () {
    final capacitor = matchReceiptLineToCatalog('DUAL RUN CAP 35/5 UF');
    expect(capacitor, isNotNull);
    expect(capacitor!.item.name, '35/5 MFD Run Capacitor');
    expect(capacitor.confidenceLevel, ReceiptConfidenceLevel.good);

    final contactor = matchReceiptLineToCatalog('COMPRESSOR CONTACTOR 40A');
    expect(contactor, isNotNull);
    expect(contactor!.item.name, '40 Amp Contactor');
  });

  test('hvac parser understands filters and thermostat wire', () {
    final filter = matchReceiptLineToCatalog('FURNACE FILTER 16X20X1');
    expect(filter, isNotNull);
    expect(filter!.item.name, '16 x 20 x 1 Pleated Air Filter');

    final statWire = matchReceiptLineToCatalog('STAT WIRE 18-5 50FT');
    expect(statWire, isNotNull);
    expect(statWire!.item.name, '18/5 Thermostat Wire');
  });

  test('hvac parser understands condensate and duct-seal supplies', () {
    final pump = matchReceiptLineToCatalog('LITTLE PUMP COND PUMP 115V');
    expect(pump, isNotNull);
    expect(pump!.item.name, '115V Condensate Pump');

    final foilTape = matchReceiptLineToCatalog('HVAC FOIL TAPE 2IN X 50YD');
    expect(foilTape, isNotNull);
    expect(foilTape!.item.name, '2 in x 50 yd Foil HVAC Tape');

    final mastic = matchReceiptLineToCatalog('DUCT MASTIC 1 GAL');
    expect(mastic, isNotNull);
    expect(mastic!.item.name, '1 gal Duct Mastic');
  });

  test('hvac parser understands line sets mini split and air distribution', () {
    final lineSet = matchReceiptLineToCatalog('1/4 X 3/8 X 25FT LINE SET');
    expect(lineSet, isNotNull);
    expect(lineSet!.item.trade, 'HVAC');
    expect(lineSet.item.name, contains('Line Set'));

    final lineHide = matchReceiptLineToCatalog('MINI SPLIT LINE HIDE 4IN');
    expect(lineHide, isNotNull);
    expect(lineHide!.item.trade, 'HVAC');
    expect(lineHide.item.name, contains('Mini Split Line Hide'));

    final grille = matchReceiptLineToCatalog('20X20 RETURN GRILLE');
    expect(grille, isNotNull);
    expect(grille!.item.trade, 'HVAC');
    expect(grille.item.name, contains('Return Grille'));
  });

  test('hvac parser understands ignition and service chemicals', () {
    final ignitor = matchReceiptLineToCatalog('UNIVERSAL HOT SURFACE IGNITOR');
    expect(ignitor, isNotNull);
    expect(ignitor!.item.trade, 'HVAC');
    expect(ignitor.item.name, contains('Hot Surface Ignitor'));

    final cleaner = matchReceiptLineToCatalog('NO RINSE EVAP COIL CLEANER');
    expect(cleaner, isNotNull);
    expect(cleaner!.item.trade, 'HVAC');
    expect(cleaner.item.name, contains('Coil Cleaner'));
  });

  test('hvac parser understands zoning iaq and duct fabrication', () {
    final damper = matchReceiptLineToCatalog('8IN ROUND ZONE DAMPER');
    expect(damper, isNotNull);
    expect(damper!.item.trade, 'HVAC');
    expect(damper.item.name, contains('Zone Damper'));

    final plenum = matchReceiptLineToCatalog('SUPPLY PLENUM 20X20X36');
    expect(plenum, isNotNull);
    expect(plenum!.item.trade, 'HVAC');
    expect(plenum.item.name, contains('Supply Plenum'));

    final vent = matchReceiptLineToCatalog('4IN DRYER VENT HOOD');
    expect(vent, isNotNull);
    expect(vent!.item.trade, 'HVAC');
    expect(vent.item.name, contains('Dryer Vent Hood'));
  });

  test('hvac parser understands refrigerant tools and install hardware', () {
    final pump = matchReceiptLineToCatalog('VACUUM PUMP 5 CFM');
    expect(pump, isNotNull);
    expect(pump!.item.trade, 'HVAC');
    expect(pump.item.name, contains('Vacuum Pump'));

    final gauge = matchReceiptLineToCatalog('MANIFOLD GAUGE SET');
    expect(gauge, isNotNull);
    expect(gauge!.item.trade, 'HVAC');
    expect(gauge.item.name, contains('Manifold Gauge'));

    final disconnect = matchReceiptLineToCatalog('60A AC DISCONNECT NON FUSED');
    expect(disconnect, isNotNull);
    expect(disconnect!.item.trade, 'HVAC');
    expect(disconnect.item.name, contains('AC Disconnect'));

    final whip = matchReceiptLineToCatalog('3/4IN X 6FT AC WHIP');
    expect(whip, isNotNull);
    expect(whip!.item.trade, 'HVAC');
    expect(whip.item.name, contains('AC Whip'));
  });

  test('hvac parser understands filter racks pans and install supports', () {
    final filterRack = matchReceiptLineToCatalog('20X25 RETURN FILTER GRILLE');
    expect(filterRack, isNotNull);
    expect(filterRack!.item.trade, 'HVAC');
    expect(filterRack.item.name, contains('Filter Rack or Return Grille'));

    final drainPan = matchReceiptLineToCatalog('30X36 SECONDARY DRAIN PAN');
    expect(drainPan, isNotNull);
    expect(drainPan!.item.trade, 'HVAC');
    expect(drainPan.item.name, contains('Condensate Service Material'));

    final cover = matchReceiptLineToCatalog('7FT WHITE LINE SET COVER');
    expect(cover, isNotNull);
    expect(cover!.item.trade, 'HVAC');
    expect(cover.item.name, contains('Outdoor Unit Install Material'));

    final pad = matchReceiptLineToCatalog('24X24 EQUIPMENT PAD');
    expect(pad, isNotNull);
    expect(pad!.item.trade, 'HVAC');
    expect(pad.item.name, contains('Outdoor Unit Install Material'));
  });

  test('hvac parser understands duct boots venting and furnace switches', () {
    final boot = matchReceiptLineToCatalog('4X10 X 6IN REGISTER BOOT');
    expect(boot, isNotNull);
    expect(boot!.item.trade, 'HVAC');
    expect(boot.item.name, contains('Duct Boot or Takeoff'));

    final bVent = matchReceiptLineToCatalog('4IN B VENT PIPE');
    expect(bVent, isNotNull);
    expect(bVent!.item.trade, 'HVAC');
    expect(bVent.item.name, contains('Duct Pipe or Vent Part'));

    final rollout = matchReceiptLineToCatalog('ROLLOUT SWITCH MANUAL RESET');
    expect(rollout, isNotNull);
    expect(rollout!.item.trade, 'HVAC');
    expect(rollout.item.name, contains('Furnace Diagnostic Part'));
  });

  test('hvac parser understands expanded detail pack receipts', () {
    final deepFilter = matchReceiptLineToCatalog(
      '20X25X5 MERV 13 MEDIA CABINET FILTER',
      tradeScope: 'HVAC',
      maxCandidates: 140,
    );
    expect(deepFilter, isNotNull);
    expect(deepFilter!.item.trade, 'HVAC');
    expect(deepFilter.item.name, contains('20 x 25 x 5 in'));
    expect(deepFilter.item.name, contains('MERV 13'));
    expect(deepFilter.item.name, contains('Media Cabinet Filter'));

    final roundDuct = matchReceiptLineToCatalog(
      '8IN 26GA MANUAL DAMPER',
      tradeScope: 'HVAC',
      maxCandidates: 140,
    );
    expect(roundDuct, isNotNull);
    expect(roundDuct!.item.trade, 'HVAC');
    expect(roundDuct.item.name, contains('8 in'));
    expect(roundDuct.item.name, contains('Manual Damper'));

    final register = matchReceiptLineToCatalog(
      '4X12 WHITE FLOOR REGISTER',
      tradeScope: 'HVAC',
      maxCandidates: 140,
    );
    expect(register, isNotNull);
    expect(register!.item.trade, 'HVAC');
    expect(register.item.name, contains('4 x 12'));
    expect(register.item.name, contains('Floor Register'));

    final lineHide = matchReceiptLineToCatalog(
      '4IN BLACK LINE HIDE ELBOW',
      tradeScope: 'HVAC',
      maxCandidates: 140,
    );
    expect(lineHide, isNotNull);
    expect(lineHide!.item.trade, 'HVAC');
    expect(lineHide.item.name, contains('4 in'));
    expect(lineHide.item.name, contains('Line Hide Elbow'));

    final pressureSwitch = matchReceiptLineToCatalog(
      'DUAL PORT .60 WC PRESSURE SWITCH',
      tradeScope: 'HVAC',
      maxCandidates: 140,
    );
    expect(pressureSwitch, isNotNull);
    expect(pressureSwitch!.item.trade, 'HVAC');
    expect(pressureSwitch.item.name, contains('Dual Port'));
    expect(pressureSwitch.item.name, contains('Pressure Switch'));
  });

  test('hvac parser understands expanded system material receipts', () {
    final plenum = matchReceiptLineToCatalog(
      '20X20X36 SUPPLY PLENUM',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(plenum, isNotNull);
    expect(plenum!.item.trade, 'HVAC');
    expect(plenum.item.name, contains('20 x 20 x 36'));
    expect(plenum.item.name, contains('Supply Plenum'));

    final bVent = matchReceiptLineToCatalog(
      '4IN B VENT ADJUSTABLE ELBOW',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(bVent, isNotNull);
    expect(bVent!.item.trade, 'HVAC');
    expect(bVent.item.name, contains('4 in'));
    expect(bVent.item.name, contains('B Vent Adjustable Elbow'));

    final drier = matchReceiptLineToCatalog(
      '3/8 LIQUID LINE FILTER DRIER',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(drier, isNotNull);
    expect(drier!.item.trade, 'HVAC');
    expect(drier.item.name, contains('3/8 in'));
    expect(drier.item.name, contains('Liquid Line Filter Drier'));

    final diffuser = matchReceiptLineToCatalog(
      '12X12 WHITE LAY IN DIFFUSER',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(diffuser, isNotNull);
    expect(diffuser!.item.trade, 'HVAC');
    expect(diffuser.item.name, contains('12 x 12'));
    expect(diffuser.item.name, contains('Lay In Diffuser'));

    final zoneDamper = matchReceiptLineToCatalog(
      '8IN 24V ROUND ZONE DAMPER',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(zoneDamper, isNotNull);
    expect(zoneDamper!.item.trade, 'HVAC');
    expect(zoneDamper.item.name, contains('8 in'));
    expect(zoneDamper.item.name, contains('Round Zone Damper'));

    final pad = matchReceiptLineToCatalog(
      '24X36 CONDENSER PAD',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(pad, isNotNull);
    expect(pad!.item.trade, 'HVAC');
    expect(pad.item.name, contains('24 x 36'));
    expect(
      pad.item.name,
      anyOf(contains('Condenser Pad'), contains('Equipment Pad')),
    );

    final cable = matchReceiptLineToCatalog(
      '14/4 50FT MINI SPLIT COMMUNICATION CABLE',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(cable, isNotNull);
    expect(cable!.item.trade, 'HVAC');
    expect(cable.item.name, contains('14/4 x 50 ft'));
    expect(cable.item.name, contains('Mini Split Communication Cable'));
  });

  test('hvac parser understands equipment and major install receipts', () {
    final condenser = matchReceiptLineToCatalog(
      '3 TON 16 SEER2 R454B AC CONDENSER',
      tradeScope: 'HVAC',
      maxCandidates: 180,
    );
    expect(condenser, isNotNull);
    expect(condenser!.item.trade, 'HVAC');
    expect(condenser.item.name, contains('3 Ton'));
    expect(condenser.item.name, contains('16 SEER2'));
    expect(condenser.item.name, contains('R454B'));
    expect(condenser.item.name, contains('AC Condenser'));

    final furnace = matchReceiptLineToCatalog(
      '80K BTU 96 AFUE UPFLOW NAT GAS FURNACE',
      tradeScope: 'HVAC',
      maxCandidates: 180,
    );
    expect(furnace, isNotNull);
    expect(furnace!.item.trade, 'HVAC');
    expect(furnace.item.name, contains('80K BTU'));
    expect(furnace.item.name, contains('96 AFUE'));
    expect(furnace.item.name, contains('Gas Furnace'));

    final coil = matchReceiptLineToCatalog(
      '2.5 TON 17.5IN R454B CASED EVAP COIL',
      tradeScope: 'HVAC',
      maxCandidates: 180,
    );
    expect(coil, isNotNull);
    expect(coil!.item.trade, 'HVAC');
    expect(coil.item.name, contains('2.5 Ton'));
    expect(coil.item.name, contains('17.5 in'));
    expect(coil.item.name, contains('Cased Evaporator Coil'));

    final airHandler = matchReceiptLineToCatalog(
      '4 TON 208-230V 10KW MULTI POSITION AIR HANDLER',
      tradeScope: 'HVAC',
      maxCandidates: 180,
    );
    expect(airHandler, isNotNull);
    expect(airHandler!.item.trade, 'HVAC');
    expect(airHandler.item.name, contains('4 Ton'));
    expect(airHandler.item.name, contains('10 kW Heat Kit'));
    expect(airHandler.item.name, contains('Multi Position Air Handler'));

    final miniSplit = matchReceiptLineToCatalog(
      '18K BTU 20 SEER2 MINI SPLIT WALL MOUNT INDOOR HEAD',
      tradeScope: 'HVAC',
      maxCandidates: 180,
    );
    expect(miniSplit, isNotNull);
    expect(miniSplit!.item.trade, 'HVAC');
    expect(miniSplit.item.name, contains('18K BTU'));
    expect(miniSplit.item.name, contains('20 SEER2'));
    expect(miniSplit.item.name, contains('Mini Split Wall Mount Indoor Head'));

    final economizer = matchReceiptLineToCatalog(
      '4 TON PACKAGE UNIT ECONOMIZER KIT',
      tradeScope: 'HVAC',
      maxCandidates: 180,
    );
    expect(economizer, isNotNull);
    expect(economizer!.item.trade, 'HVAC');
    expect(economizer.item.name, contains('4 Ton'));
    expect(economizer.item.name, contains('Economizer Kit'));

    final crankcase = matchReceiptLineToCatalog(
      '5 TON CRANKCASE HEATER KIT',
      tradeScope: 'HVAC',
      maxCandidates: 180,
    );
    expect(crankcase, isNotNull);
    expect(crankcase!.item.trade, 'HVAC');
    expect(crankcase.item.name, contains('5 Ton'));
    expect(crankcase.item.name, contains('Crankcase Heater Kit'));
  });

  test('hvac parser understands service truck electrical stock', () {
    final turboCap = matchReceiptLineToCatalog(
      'TURBO 45/5 MFD 440V DUAL RUN CAP',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(turboCap, isNotNull);
    expect(turboCap!.item.trade, 'HVAC');
    expect(turboCap.item.name, contains('45/5 MFD'));
    expect(turboCap.item.name, contains('Dual Run Capacitor'));

    final relay = matchReceiptLineToCatalog(
      '24V TIME DELAY RELAY',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(relay, isNotNull);
    expect(relay!.item.trade, 'HVAC');
    expect(relay.item.name, contains('Time Delay Relay'));

    final fuse = matchReceiptLineToCatalog(
      '5A LOW VOLTAGE BLADE FUSE 10PK',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(fuse, isNotNull);
    expect(fuse!.item.trade, 'HVAC');
    expect(fuse.item.name, contains('Low Voltage Blade Fuse'));
  });

  test('hvac parser understands furnace and motor truck stock', () {
    final switchPart = matchReceiptLineToCatalog(
      'DUAL PORT .50 WC PRESSURE SWITCH',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(switchPart, isNotNull);
    expect(switchPart!.item.trade, 'HVAC');
    expect(switchPart.item.name, contains('Pressure Switch'));

    final motor = matchReceiptLineToCatalog(
      '1/3 HP 1075 RPM 208/230V CONDENSER FAN MOTOR',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(motor, isNotNull);
    expect(motor!.item.trade, 'HVAC');
    expect(motor.item.name, contains('Condenser Fan Motor'));

    final belt = matchReceiptLineToCatalog(
      'A30 V BELT',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(belt, isNotNull);
    expect(belt!.item.trade, 'HVAC');
    expect(belt.item.name, contains('A30 V Belt'));
  });

  test('hvac parser understands refrigerant and condensate truck stock', () {
    final core = matchReceiptLineToCatalog(
      '10PK SCHRADER VALVE CORE',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(core, isNotNull);
    expect(core!.item.trade, 'HVAC');
    expect(core.item.name, contains('Schrader Valve Core'));

    final drier = matchReceiptLineToCatalog(
      '3/8 LIQUID LINE FILTER DRIER',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(drier, isNotNull);
    expect(drier!.item.trade, 'HVAC');
    expect(drier.item.name, contains('Liquid Line Filter Drier'));

    final tubing = matchReceiptLineToCatalog(
      '3/8 X 50FT CLEAR VINYL CONDENSATE TUBING',
      tradeScope: 'HVAC',
      maxCandidates: 160,
    );
    expect(tubing, isNotNull);
    expect(tubing!.item.trade, 'HVAC');
    expect(tubing.item.name, contains('Condensate Tubing'));
  });

  test(
    'hvac parser understands condensate safety and drain treatment stock',
    () {
      final floatSwitch = matchReceiptLineToCatalog(
        'SECONDARY PAN FLOAT SWITCH',
        tradeScope: 'HVAC',
        maxCandidates: 180,
      );
      expect(floatSwitch, isNotNull);
      expect(floatSwitch!.item.trade, 'HVAC');
      expect(floatSwitch.item.name, contains('Float Switch'));

      final wetSwitch = matchReceiptLineToCatalog(
        'WET SWITCH FLOOD DETECTOR',
        tradeScope: 'HVAC',
        maxCandidates: 180,
      );
      expect(wetSwitch, isNotNull);
      expect(wetSwitch!.item.trade, 'HVAC');
      expect(wetSwitch.item.name, contains('Wet Switch'));

      final tablets = matchReceiptLineToCatalog(
        'CONDENSATE DRAIN PAN TABLETS',
        tradeScope: 'HVAC',
        maxCandidates: 180,
      );
      expect(tablets, isNotNull);
      expect(tablets!.item.trade, 'HVAC');
      expect(tablets.item.name, contains('Condensate Drain Tablets'));
    },
  );

  test('hvac parser understands condensate PVC service fittings', () {
    final trap = matchReceiptLineToCatalog(
      '3/4IN PVC CONDENSATE TRAP',
      tradeScope: 'HVAC',
      maxCandidates: 180,
    );
    expect(trap, isNotNull);
    expect(trap!.item.trade, 'HVAC');
    expect(trap.item.name, contains('Condensate'));
    expect(trap.item.name, contains('Trap'));

    final cleanout = matchReceiptLineToCatalog(
      '1IN PVC TEE CLEANOUT CONDENSATE',
      tradeScope: 'HVAC',
      maxCandidates: 180,
    );
    expect(cleanout, isNotNull);
    expect(cleanout!.item.trade, 'HVAC');
    expect(cleanout.item.name, contains('Condensate'));
    expect(cleanout.item.name, contains('Tee Cleanout'));
  });

  test('hvac parser understands humidifier and condensate tool stock', () {
    final humidifierPad = matchReceiptLineToCatalog(
      'HUMIDIFIER PAD MODEL 10',
      tradeScope: 'HVAC',
      maxCandidates: 180,
    );
    expect(humidifierPad, isNotNull);
    expect(humidifierPad!.item.trade, 'HVAC');
    expect(humidifierPad.item.name, contains('Humidifier Pad'));

    final solenoid = matchReceiptLineToCatalog(
      'HUMIDIFIER SOLENOID VALVE',
      tradeScope: 'HVAC',
      maxCandidates: 180,
    );
    expect(solenoid, isNotNull);
    expect(solenoid!.item.trade, 'HVAC');
    expect(solenoid.item.name, contains('Humidifier Solenoid Valve'));

    final drainGun = matchReceiptLineToCatalog(
      'CONDENSATE DRAIN GUN',
      tradeScope: 'HVAC',
      maxCandidates: 180,
    );
    expect(drainGun, isNotNull);
    expect(drainGun!.item.trade, 'HVAC');
    expect(drainGun.item.name, contains('Condensate Drain Gun'));

    final cartridge = matchReceiptLineToCatalog(
      'CONDENSATE DRAIN GUN CARTRIDGE PACK',
      tradeScope: 'HVAC',
      maxCandidates: 180,
    );
    expect(cartridge, isNotNull);
    expect(cartridge!.item.trade, 'HVAC');
    expect(cartridge.item.name, contains('Drain Gun Cartridge'));
  });
}
