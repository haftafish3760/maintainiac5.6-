import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_audit.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('low voltage pack is broad enough for first-pass trade coverage', () {
    final audit = auditWorkSupplyCatalog();
    final lowVoltage = audit.tradeCoverage.singleWhere(
      (coverage) => coverage.tradeName == 'Low Voltage and Data',
    );
    final tools = audit.tradeCoverage.singleWhere(
      (coverage) => coverage.tradeName == 'Tools and Safety',
    );

    expect(lowVoltage.itemCount, greaterThanOrEqualTo(500));
    expect(lowVoltage.aliasCoverage, greaterThan(.70));
    expect(lowVoltage.parserReadinessLabel, 'Strong');
    expect(tools.itemCount, greaterThanOrEqualTo(500));
    expect(tools.aliasCoverage, greaterThan(.70));
    expect(tools.parserReadinessLabel, 'Strong');
  });

  test('low voltage parser understands data cable and coax receipts', () {
    final cat6 = matchReceiptLineToCatalog('CAT6 PLENUM 1000FT CMP DATA CABLE');
    expect(cat6, isNotNull);
    expect(cat6!.item.trade, 'Low Voltage and Data');
    expect(cat6.item.name.toLowerCase(), contains('cat6'));
    expect(cat6.item.name.toLowerCase(), contains('plenum'));
    expect(cat6.confidenceLevel, ReceiptConfidenceLevel.good);

    final coax = matchReceiptLineToCatalog('RG6 QUAD SHIELD COAX 500FT');
    expect(coax, isNotNull);
    expect(coax!.item.trade, 'Low Voltage and Data');
    expect(coax.item.name, contains('RG6'));
    expect(coax.item.name, contains('Coax'));

    final speaker = matchReceiptLineToCatalog('16/2 500FT SPEAKER WIRE');
    expect(speaker, isNotNull);
    expect(speaker!.item.trade, 'Low Voltage and Data');
    expect(speaker.item.name, contains('Speaker Wire'));
  });

  test('low voltage parser understands terminations boxes and testers', () {
    final rj45 = matchReceiptLineToCatalog('CAT6 RJ45 PASS THROUGH CONNECTOR');
    expect(rj45, isNotNull);
    expect(rj45!.item.trade, 'Low Voltage and Data');
    expect(rj45.item.name, contains('Cat6 RJ45'));

    final bracket = matchReceiptLineToCatalog('2 GANG LV BRACKET MUD RING');
    expect(bracket, isNotNull);
    expect(bracket!.item.trade, 'Low Voltage and Data');
    expect(
      bracket.item.name.toLowerCase(),
      contains('2 gang low voltage mounting bracket'),
    );

    final toner = matchReceiptLineToCatalog('TONE GENERATOR PROBE FOX HOUND');
    expect(toner, isNotNull);
    expect(toner!.item.trade, 'Low Voltage and Data');
    expect(toner.item.name, contains('Tone Generator'));
  });

  test('low voltage parser understands camera access and alarm materials', () {
    final camera = matchReceiptLineToCatalog('4MP POE DOME CAMERA');
    expect(camera, isNotNull);
    expect(camera!.item.trade, 'Low Voltage and Data');
    expect(camera.item.name, contains('PoE Dome Camera'));

    final doorbell = matchReceiptLineToCatalog('VIDEO DOORBELL TRANSFORMER');
    expect(doorbell, isNotNull);
    expect(doorbell!.item.trade, 'Low Voltage and Data');
    expect(doorbell.item.name, contains('Doorbell Transformer'));

    final access = matchReceiptLineToCatalog('ACCESS CONTROL RFID CARD READER');
    expect(access, isNotNull);
    expect(access!.item.trade, 'Low Voltage and Data');
    expect(access.item.name, contains('RFID Card Reader'));

    final contact = matchReceiptLineToCatalog('RECESSED DOOR CONTACT SENSOR');
    expect(contact, isNotNull);
    expect(contact!.item.trade, 'Low Voltage and Data');
    expect(contact.item.name, contains('Recessed Door Contact'));

    final hdmi = matchReceiptLineToCatalog('WHITE HDMI KEYSTONE INSERT');
    expect(hdmi, isNotNull);
    expect(hdmi!.item.trade, 'Low Voltage and Data');
    expect(hdmi.item.name, contains('HDMI Keystone Insert'));

    final cableTies = matchReceiptLineToCatalog('11 IN BLACK CABLE TIE PACK');
    expect(cableTies, isNotNull);
    expect(cableTies!.item.trade, 'Low Voltage and Data');
    expect(cableTies.item.name, contains('Cable Tie Pack'));
  });

  test('low voltage parser understands AV cable and audio distribution', () {
    final hdmiCable = matchReceiptLineToCatalog('25FT HIGH SPEED HDMI CABLE');
    expect(hdmiCable, isNotNull);
    expect(hdmiCable!.item.trade, 'Low Voltage and Data');
    expect(hdmiCable.item.name, contains('High Speed HDMI Cable'));

    final volumeControl = matchReceiptLineToCatalog(
      'WHITE IN-WALL VOLUME CONTROL',
    );
    expect(volumeControl, isNotNull);
    expect(volumeControl!.item.trade, 'Low Voltage and Data');
    expect(volumeControl.item.name, contains('In-Wall Volume Control'));

    final irRepeater = matchReceiptLineToCatalog('IR REPEATER KIT');
    expect(irRepeater, isNotNull);
    expect(irRepeater!.item.trade, 'Low Voltage and Data');
    expect(irRepeater.item.name, contains('IR Repeater Kit'));
  });

  test('low voltage parser understands smart home and rack hardware', () {
    final smartLock = matchReceiptLineToCatalog('Z-WAVE SMART LOCK');
    expect(smartLock, isNotNull);
    expect(smartLock!.item.trade, 'Low Voltage and Data');
    expect(smartLock.item.name, contains('Smart Lock'));

    final cWire = matchReceiptLineToCatalog('THERMOSTAT C-WIRE ADAPTER');
    expect(cWire, isNotNull);
    expect(cWire!.item.trade, 'Low Voltage and Data');
    expect(cWire.item.name, contains('C-Wire Adapter'));

    final pdu = matchReceiptLineToCatalog('8 OUTLET RACK PDU');
    expect(pdu, isNotNull);
    expect(pdu!.item.trade, 'Low Voltage and Data');
    expect(pdu.item.name, contains('Rack PDU'));

    final poeExtender = matchReceiptLineToCatalog('POE EXTENDER');
    expect(poeExtender, isNotNull);
    expect(poeExtender!.item.trade, 'Low Voltage and Data');
    expect(poeExtender.item.name, contains('PoE Extender'));

    final fiberBox = matchReceiptLineToCatalog('FIBER DISTRIBUTION BOX');
    expect(fiberBox, isNotNull);
    expect(fiberBox!.item.trade, 'Low Voltage and Data');
    expect(fiberBox.item.name, contains('Fiber Distribution Box'));
  });

  test(
    'low voltage parser understands patch cords speakers camera power and rack service',
    () {
      final patchCord = matchReceiptLineToCatalog('CAT6 7FT BLUE PATCH CORD');
      expect(patchCord, isNotNull);
      expect(patchCord!.item.trade, 'Low Voltage and Data');
      expect(patchCord.item.name, contains('Patch'));

      final speakerPair = matchReceiptLineToCatalog(
        'IN CEILING SPEAKER PAIR 8IN',
      );
      expect(speakerPair, isNotNull);
      expect(speakerPair!.item.trade, 'Low Voltage and Data');
      expect(speakerPair.item.name, contains('Speaker Pair'));

      final cameraMount = matchReceiptLineToCatalog(
        'SECURITY CAMERA JUNCTION BOX',
      );
      expect(cameraMount, isNotNull);
      expect(cameraMount!.item.trade, 'Low Voltage and Data');
      expect(cameraMount.item.name, contains('Security Camera Junction Box'));

      final doorbellPower = matchReceiptLineToCatalog('DOORBELL POWER KIT');
      expect(doorbellPower, isNotNull);
      expect(doorbellPower!.item.trade, 'Low Voltage and Data');
      expect(doorbellPower.item.name, contains('Doorbell Power Kit'));

      final exitButton = matchReceiptLineToCatalog('EXIT BUTTON STAINLESS');
      expect(exitButton, isNotNull);
      expect(exitButton!.item.trade, 'Low Voltage and Data');
      expect(exitButton.item.name, contains('Exit Button'));

      final rackUps = matchReceiptLineToCatalog('RACK MOUNT UPS 1500VA');
      expect(rackUps, isNotNull);
      expect(rackUps!.item.trade, 'Low Voltage and Data');
      expect(rackUps.item.name, contains('Rack Mount UPS'));

      final blankPanel = matchReceiptLineToCatalog('1U BLANK PANEL');
      expect(blankPanel, isNotNull);
      expect(blankPanel!.item.trade, 'Low Voltage and Data');
      expect(blankPanel.item.name, contains('Blank Panel'));

      final cageNut = matchReceiptLineToCatalog('CAGE NUT 50PK');
      expect(cageNut, isNotNull);
      expect(cageNut!.item.trade, 'Low Voltage and Data');
      expect(cageNut.item.name, contains('Cage Nut'));
    },
  );

  test(
    'low voltage parser understands rough-in pathway and enclosure detail',
    () {
      final smurfTube = matchReceiptLineToCatalog(
        '3/4IN 100FT SMURF TUBE FLEXIBLE RACEWAY',
      );
      expect(smurfTube, isNotNull);
      expect(smurfTube!.item.trade, 'Low Voltage and Data');
      expect(smurfTube.item.name, contains('Smurf Tube Flexible Raceway'));

      final bridleRing = matchReceiptLineToCatalog(
        'BRIDLE RING CABLE SUPPORT 50PK',
      );
      expect(bridleRing, isNotNull);
      expect(bridleRing!.item.trade, 'Low Voltage and Data');
      expect(bridleRing.item.name, contains('Bridle Ring Cable Support'));

      final mediaPower = matchReceiptLineToCatalog(
        '28IN STRUCTURED MEDIA POWER MODULE',
      );
      expect(mediaPower, isNotNull);
      expect(mediaPower!.item.trade, 'Low Voltage and Data');
      expect(mediaPower.item.name, contains('Structured Media Power Module'));
    },
  );

  test('low voltage parser understands network fiber and PoE detail', () {
    final slimJack = matchReceiptLineToCatalog('CAT6 BLUE SLIM KEYSTONE JACK');
    expect(slimJack, isNotNull);
    expect(slimJack!.item.trade, 'Low Voltage and Data');
    expect(slimJack.item.name, contains('Slim Keystone Jack'));

    final pigtail = matchReceiptLineToCatalog(
      'LC SINGLE MODE FIBER PIGTAIL 6PK',
    );
    expect(pigtail, isNotNull);
    expect(pigtail!.item.trade, 'Low Voltage and Data');
    expect(pigtail.item.name, contains('Fiber Pigtail'));

    final sfp = matchReceiptLineToCatalog('SFP PLUS TRANSCEIVER 10G');
    expect(sfp, isNotNull);
    expect(sfp!.item.trade, 'Low Voltage and Data');
    expect(sfp.item.name, contains('SFP Plus Transceiver'));
  });

  test('low voltage parser understands alarm and AV smart home detail', () {
    final alarmBattery = matchReceiptLineToCatalog('ALARM BACKUP BATTERY');
    expect(alarmBattery, isNotNull);
    expect(alarmBattery!.item.trade, 'Low Voltage and Data');
    expect(alarmBattery.item.name, contains('Alarm Backup Battery'));

    final electricStrike = matchReceiptLineToCatalog('ELECTRIC DOOR STRIKE');
    expect(electricStrike, isNotNull);
    expect(electricStrike!.item.trade, 'Low Voltage and Data');
    expect(electricStrike.item.name, contains('Electric Door Strike'));

    final hdmi = matchReceiptLineToCatalog('25FT 8K HDMI CABLE');
    expect(hdmi, isNotNull);
    expect(hdmi!.item.trade, 'Low Voltage and Data');
    expect(hdmi.item.name, contains('8K HDMI Cable'));

    final passThrough = matchReceiptLineToCatalog(
      'WHITE BRUSH PASS THROUGH PLATE',
    );
    expect(passThrough, isNotNull);
    expect(passThrough!.item.trade, 'Low Voltage and Data');
    expect(passThrough.item.name, contains('Brush Pass Through Plate'));
  });

  test('low voltage parser understands expanded field detail stock', () {
    final cat6a = matchReceiptLineToCatalog(
      'CAT6A BLACK PLENUM 1000FT DATA CABLE',
    );
    expect(cat6a, isNotNull);
    expect(cat6a!.item.trade, 'Low Voltage and Data');
    expect(cat6a.item.name, contains('Cat6A 1000 ft Black CMP Plenum'));

    final securityCable = matchReceiptLineToCatalog(
      '22/4 500FT CL2 SECURITY CABLE',
    );
    expect(securityCable, isNotNull);
    expect(securityCable!.item.trade, 'Low Voltage and Data');
    expect(securityCable.item.name, contains('22/4 500 ft CL2 Security Cable'));

    final jack = matchReceiptLineToCatalog('CAT6 WHITE TOOLLESS KEYSTONE JACK');
    expect(jack, isNotNull);
    expect(jack!.item.trade, 'Low Voltage and Data');
    expect(jack.item.name, contains('Cat6 White Toolless Keystone Jack'));

    final jHook = matchReceiptLineToCatalog('J-HOOK CABLE SUPPORT 50PK');
    expect(jHook, isNotNull);
    expect(jHook!.item.trade, 'Low Voltage and Data');
    expect(jHook.item.name, contains('J-Hook Cable Support 50 Pack'));

    final nvr = matchReceiptLineToCatalog('16 PORT NVR RECORDER');
    expect(nvr, isNotNull);
    expect(nvr!.item.trade, 'Low Voltage and Data');
    expect(nvr.item.name, contains('16 Port NVR Recorder'));

    final noTouch = matchReceiptLineToCatalog('NO TOUCH EXIT BUTTON');
    expect(noTouch, isNotNull);
    expect(noTouch!.item.trade, 'Low Voltage and Data');
    expect(noTouch.item.name, contains('No Touch Exit Button'));

    final plate = matchReceiptLineToCatalog('BLACK USB-C KEYSTONE INSERT');
    expect(plate, isNotNull);
    expect(plate!.item.trade, 'Low Voltage and Data');
    expect(plate.item.name, contains('Black USB-C Keystone Insert'));

    final rack = matchReceiptLineToCatalog('12 OUTLET RACK PDU');
    expect(rack, isNotNull);
    expect(rack!.item.trade, 'Low Voltage and Data');
    expect(rack.item.name, contains('12 Outlet Rack PDU'));
  });

  test('tools parser understands hand tools blades and bits', () {
    final wrench = matchReceiptLineToCatalog('10 IN CRESCENT WRENCH');
    expect(wrench, isNotNull);
    expect(wrench!.item.trade, 'Tools and Safety');
    expect(wrench.item.name, contains('10 in Adjustable Wrench'));

    final blade = matchReceiptLineToCatalog('7-1/4 24T CIRCULAR SAW BLADE');
    expect(blade, isNotNull);
    expect(blade!.item.trade, 'Tools and Safety');
    expect(blade.item.name, contains('7-1/4 in 24T Circular Saw Blade'));

    final bits = matchReceiptLineToCatalog('MASONRY DRILL BIT SET');
    expect(bits, isNotNull);
    expect(bits!.item.trade, 'Tools and Safety');
    expect(bits.item.name, contains('Masonry Drill Bit Set'));
  });

  test('tools parser understands PPE measuring and jobsite consumables', () {
    final mask = matchReceiptLineToCatalog('N95 DUST MASK PACK');
    expect(mask, isNotNull);
    expect(mask!.item.trade, 'Tools and Safety');
    expect(mask.item.name, contains('N95 Dust Mask'));
    expect(mask.confidenceLevel, ReceiptConfidenceLevel.good);

    final tapeMeasure = matchReceiptLineToCatalog('25FT TAPE MEASURE');
    expect(tapeMeasure, isNotNull);
    expect(tapeMeasure!.item.trade, 'Tools and Safety');
    expect(tapeMeasure.item.name, contains('25 ft Tape Measure'));

    final trashBags = matchReceiptLineToCatalog('42 GAL CONTRACTOR TRASH BAGS');
    expect(trashBags, isNotNull);
    expect(trashBags!.item.trade, 'Tools and Safety');
    expect(trashBags.item.name, contains('42 gal Contractor Trash Bags'));

    final cord = matchReceiptLineToCatalog('12/3 50FT EXTENSION CORD');
    expect(cord, isNotNull);
    expect(cord!.item.trade, 'Tools and Safety');
    expect(cord.item.name, contains('Extension Cord'));

    final ladder = matchReceiptLineToCatalog('6FT FIBERGLASS STEP LADDER');
    expect(ladder, isNotNull);
    expect(ladder!.item.trade, 'Tools and Safety');
    expect(ladder.item.name, contains('6 ft Fiberglass Step Ladder'));

    final tarp = matchReceiptLineToCatalog('8X10 POLY TARP');
    expect(tarp, isNotNull);
    expect(tarp!.item.trade, 'Tools and Safety');
    expect(tarp.item.name, contains('Poly Tarp'));

    final paint = matchReceiptLineToCatalog('MARKING PAINT ORANGE');
    expect(paint, isNotNull);
    expect(paint!.item.trade, 'Tools and Safety');
    expect(paint.item.name, contains('Marking Paint Orange'));

    final clamp = matchReceiptLineToCatalog('24 IN BAR CLAMP');
    expect(clamp, isNotNull);
    expect(clamp!.item.trade, 'Tools and Safety');
    expect(clamp.item.name, contains('24 in Bar Clamp'));

    final fan = matchReceiptLineToCatalog('20 IN BOX FAN');
    expect(fan, isNotNull);
    expect(fan!.item.trade, 'Tools and Safety');
    expect(fan.item.name, contains('20 in Box Fan'));

    final spillKit = matchReceiptLineToCatalog('SMALL SPILL KIT');
    expect(spillKit, isNotNull);
    expect(spillKit!.item.trade, 'Tools and Safety');
    expect(spillKit.item.name, contains('Spill Kit Small'));
  });

  test('tools parser understands specialty trade tools', () {
    final fishTape = matchReceiptLineToCatalog('100FT FISH TAPE');
    expect(fishTape, isNotNull);
    expect(fishTape!.item.trade, 'Tools and Safety');
    expect(fishTape.item.name, contains('Fish Tape'));

    final pipeWrench = matchReceiptLineToCatalog('18 IN PIPE WRENCH');
    expect(pipeWrench, isNotNull);
    expect(pipeWrench!.item.trade, 'Tools and Safety');
    expect(pipeWrench.item.name, contains('18 in Pipe Wrench'));

    final pexCrimp = matchReceiptLineToCatalog('1/2 IN PEX CRIMP TOOL');
    expect(pexCrimp, isNotNull);
    expect(pexCrimp!.item.trade, 'Tools and Safety');
    expect(pexCrimp.item.name, contains('PEX Crimp Tool'));

    final thermalCamera = matchReceiptLineToCatalog('INFRARED THERMAL CAMERA');
    expect(thermalCamera, isNotNull);
    expect(thermalCamera!.item.trade, 'Tools and Safety');
    expect(thermalCamera.item.name, contains('Thermal Camera'));
  });

  test(
    'tools parser understands pipe electrical finish dust and roof safety tools',
    () {
      final threadingDie = matchReceiptLineToCatalog('3/4 PIPE THREADING DIE');
      expect(threadingDie, isNotNull);
      expect(threadingDie!.item.trade, 'Tools and Safety');
      expect(threadingDie.item.name, contains('Pipe Threading Die'));

      final basinWrench = matchReceiptLineToCatalog('BASIN WRENCH');
      expect(basinWrench, isNotNull);
      expect(basinWrench!.item.trade, 'Tools and Safety');
      expect(basinWrench.item.name, contains('Basin Wrench'));

      final emtBender = matchReceiptLineToCatalog('1/2 IN EMT BENDER');
      expect(emtBender, isNotNull);
      expect(emtBender!.item.trade, 'Tools and Safety');
      expect(emtBender.item.name, contains('EMT Bender'));

      final pullString = matchReceiptLineToCatalog('500FT PULL STRING BUCKET');
      expect(pullString, isNotNull);
      expect(pullString!.item.trade, 'Tools and Safety');
      expect(pullString.item.name, contains('Pull String'));

      final concreteTrowel = matchReceiptLineToCatalog(
        '12 IN CONCRETE FINISHING TROWEL',
      );
      expect(concreteTrowel, isNotNull);
      expect(concreteTrowel!.item.trade, 'Tools and Safety');
      expect(concreteTrowel.item.name, contains('Concrete Finishing Trowel'));

      final roofShovel = matchReceiptLineToCatalog('ROOFING TEAR OFF SHOVEL');
      expect(roofShovel, isNotNull);
      expect(roofShovel!.item.trade, 'Tools and Safety');
      expect(roofShovel.item.name, contains('Roofing Tear Off Shovel'));

      final safetyKit = matchReceiptLineToCatalog('ROOF SAFETY KIT');
      expect(safetyKit, isNotNull);
      expect(safetyKit!.item.trade, 'Tools and Safety');
      expect(safetyKit.item.name, contains('Roof Safety Kit'));

      final hepaFilter = matchReceiptLineToCatalog('HEPA VAC FILTER');
      expect(hepaFilter, isNotNull);
      expect(hepaFilter!.item.trade, 'Tools and Safety');
      expect(hepaFilter.item.name, contains('HEPA'));
    },
  );

  test('tools parser understands install helpers and fastening tools', () {
    final screwSetter = matchReceiptLineToCatalog(
      'DRYWALL SCREW SETTER BIT PACK',
    );
    expect(screwSetter, isNotNull);
    expect(screwSetter!.item.trade, 'Tools and Safety');
    expect(screwSetter.item.name, contains('Screw Setter'));

    final nutSetter = matchReceiptLineToCatalog('3/8 IN NUT SETTER SET');
    expect(nutSetter, isNotNull);
    expect(nutSetter!.item.trade, 'Tools and Safety');
    expect(nutSetter.item.name, contains('Nut Setter'));

    final rivetGun = matchReceiptLineToCatalog('RIVET GUN');
    expect(rivetGun, isNotNull);
    expect(rivetGun!.item.trade, 'Tools and Safety');
    expect(rivetGun.item.name, contains('Rivet Gun'));

    final powderTool = matchReceiptLineToCatalog('POWDER ACTUATED TOOL');
    expect(powderTool, isNotNull);
    expect(powderTool!.item.trade, 'Tools and Safety');
    expect(powderTool.item.name, contains('Powder Actuated Tool'));
  });

  test('tools parser understands expanded jobsite detail stock', () {
    final gloves = matchReceiptLineToCatalog('XL CUT RESISTANT GLOVE PAIR');
    expect(gloves, isNotNull);
    expect(gloves!.item.trade, 'Tools and Safety');
    expect(gloves.item.name, contains('XL Cut Resistant Glove Pair'));

    final sdsBits = matchReceiptLineToCatalog('SDS PLUS MASONRY BIT SET');
    expect(sdsBits, isNotNull);
    expect(sdsBits!.item.trade, 'Tools and Safety');
    expect(sdsBits.item.name, contains('SDS Plus Masonry Bit Set'));

    final pexTool = matchReceiptLineToCatalog('3/4 IN PEX EXPANSION TOOL HEAD');
    expect(pexTool, isNotNull);
    expect(pexTool!.item.trade, 'Tools and Safety');
    expect(pexTool.item.name, contains('3/4 in PEX Expansion Tool Head'));

    final chalk = matchReceiptLineToCatalog('BLUE CHALK REFILL');
    expect(chalk, isNotNull);
    expect(chalk!.item.trade, 'Tools and Safety');
    expect(chalk.item.name, contains('Blue Chalk Refill'));

    final protection = matchReceiptLineToCatalog('RAM BOARD FLOOR PROTECTION');
    expect(protection, isNotNull);
    expect(protection!.item.trade, 'Tools and Safety');
    expect(protection.item.name, contains('Ram Board Floor Protection'));

    final headlamp = matchReceiptLineToCatalog('RECHARGEABLE HEADLAMP');
    expect(headlamp, isNotNull);
    expect(headlamp!.item.trade, 'Tools and Safety');
    expect(headlamp.item.name, contains('Rechargeable Headlamp'));
  });
}
