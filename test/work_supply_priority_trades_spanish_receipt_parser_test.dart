import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test(
    'electrical es-US parser handles common residential receipt wording',
    () {
      final gfci = matchReceiptLineToCatalog(
        'HD 20A TOMACORRIENTE GFCI BLANCO',
        localePackId: 'es-US',
        tradeScope: 'Electrical',
        maxCandidates: 320,
      );
      expect(gfci, isNotNull);
      expect(gfci!.item.trade, 'Electrical');
      expect(gfci.item.name.toLowerCase(), contains('gfci'));
      expect(gfci.confidenceLevel, ReceiptConfidenceLevel.good);

      final breaker = matchReceiptLineToCatalog(
        'LOWES 20A BREAKER UN POLO',
        localePackId: 'es-US',
        tradeScope: 'Electrical',
        maxCandidates: 320,
      );
      expect(breaker, isNotNull);
      expect(breaker!.item.trade, 'Electrical');
      expect(breaker.item.name.toLowerCase(), contains('breaker'));
      expect(breaker.confidenceLevel, ReceiptConfidenceLevel.good);

      final emtConnector = matchReceiptLineToCatalog(
        'ACE 1/2 CONECTOR EMT SET SCREW',
        localePackId: 'es-US',
        tradeScope: 'Electrical',
        maxCandidates: 320,
      );
      expect(emtConnector, isNotNull);
      expect(emtConnector!.item.trade, 'Electrical');
      expect(emtConnector.item.name.toLowerCase(), contains('emt'));
      expect(emtConnector.item.name.toLowerCase(), contains('connector'));
      expect(emtConnector.confidenceLevel, ReceiptConfidenceLevel.good);

      final surge = matchReceiptLineToCatalog(
        'LOWES PROTECTOR SOBRETENSION WHOLE HOME',
        localePackId: 'es-US',
        tradeScope: 'Electrical',
        maxCandidates: 320,
      );
      expect(surge, isNotNull);
      expect(surge!.item.trade, 'Electrical');
      expect(surge.item.name.toLowerCase(), contains('surge'));
      expect(surge.confidenceLevel, ReceiptConfidenceLevel.good);

      final doorbell = matchReceiptLineToCatalog(
        'ACE TRANSFORMADOR TIMBRE 16V',
        localePackId: 'es-US',
        tradeScope: 'Electrical',
        maxCandidates: 320,
      );
      expect(doorbell, isNotNull);
      expect(doorbell!.item.trade, 'Electrical');
      expect(doorbell.item.name.toLowerCase(), contains('doorbell'));
      expect(doorbell.confidenceLevel, ReceiptConfidenceLevel.good);

      final bubbleCover = matchReceiptLineToCatalog(
        'HD 1 GANG CUBIERTA INTEMPERIE',
        localePackId: 'es-US',
        tradeScope: 'Electrical',
        maxCandidates: 320,
      );
      expect(bubbleCover, isNotNull);
      expect(bubbleCover!.item.trade, 'Electrical');
      expect(bubbleCover.item.name.toLowerCase(), contains('weatherproof'));
      expect(bubbleCover.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test('electrical es-US parser handles service connector stock', () {
    final leverConnector = matchReceiptLineToCatalog(
      'HD CONECTOR PALANCA 3 PUERTOS 25PK',
      localePackId: 'es-US',
      tradeScope: 'Electrical',
      maxCandidates: 320,
    );
    expect(leverConnector, isNotNull);
    expect(leverConnector!.item.trade, 'Electrical');
    expect(leverConnector.item.name.toLowerCase(), contains('lever'));

    final antiShort = matchReceiptLineToCatalog(
      'SUPPLY BUSHING ANTI CORTO MC 100PK',
      localePackId: 'es-US',
      tradeScope: 'Electrical',
      maxCandidates: 320,
    );
    expect(antiShort, isNotNull);
    expect(antiShort!.item.trade, 'Electrical');
    expect(antiShort.item.name.toLowerCase(), contains('anti short'));

    final buttSplice = matchReceiptLineToCatalog(
      'ACE CONECTOR EMPALME TOPE 25PK',
      localePackId: 'es-US',
      tradeScope: 'Electrical',
      maxCandidates: 320,
    );
    expect(buttSplice, isNotNull);
    expect(buttSplice!.item.trade, 'Electrical');
    expect(buttSplice.item.name.toLowerCase(), contains('butt splice'));
  });

  test('hvac es-US parser handles common service-truck receipt wording', () {
    final capacitor = matchReceiptLineToCatalog(
      'FERG 35/5 MFD CAPACITOR MARCHA',
      localePackId: 'es-US',
      tradeScope: 'HVAC',
      maxCandidates: 320,
    );
    expect(capacitor, isNotNull);
    expect(capacitor!.item.trade, 'HVAC');
    expect(capacitor.item.name.toLowerCase(), contains('capacitor'));
    expect(capacitor.confidenceLevel, ReceiptConfidenceLevel.good);

    final filter = matchReceiptLineToCatalog(
      'HD 16X25X1 FILTRO PLISADO',
      localePackId: 'es-US',
      tradeScope: 'HVAC',
      maxCandidates: 320,
    );
    expect(filter, isNotNull);
    expect(filter!.item.trade, 'HVAC');
    expect(filter.item.name.toLowerCase(), contains('filter'));
    expect(filter.confidenceLevel, ReceiptConfidenceLevel.good);

    final foilTape = matchReceiptLineToCatalog(
      'LOWES CINTA ALUMINIO HVAC',
      localePackId: 'es-US',
      tradeScope: 'HVAC',
      maxCandidates: 320,
    );
    expect(foilTape, isNotNull);
    expect(foilTape!.item.trade, 'HVAC');
    expect(foilTape.item.name.toLowerCase(), contains('tape'));
    expect(foilTape.confidenceLevel, ReceiptConfidenceLevel.good);

    final zonePanel = matchReceiptLineToCatalog(
      'SUPPLY PANEL CONTROL ZONAS 3 ZONE',
      localePackId: 'es-US',
      tradeScope: 'HVAC',
      maxCandidates: 320,
    );
    expect(zonePanel, isNotNull);
    expect(zonePanel!.item.trade, 'HVAC');
    expect(zonePanel.item.name.toLowerCase(), contains('zone control'));
    expect(zonePanel.confidenceLevel, ReceiptConfidenceLevel.good);

    final miniSplitBib = matchReceiptLineToCatalog(
      'LOWES BOLSA LIMPIEZA MINI SPLIT',
      localePackId: 'es-US',
      tradeScope: 'HVAC',
      maxCandidates: 320,
    );
    expect(miniSplitBib, isNotNull);
    expect(miniSplitBib!.item.trade, 'HVAC');
    expect(miniSplitBib.item.name.toLowerCase(), contains('cleaning bib'));
    expect(miniSplitBib.confidenceLevel, ReceiptConfidenceLevel.good);

    final mervFilter = matchReceiptLineToCatalog(
      'HD 16X25X1 MERV 11 FILTRO PLISADO 12PK',
      localePackId: 'es-US',
      tradeScope: 'HVAC',
      maxCandidates: 320,
    );
    expect(mervFilter, isNotNull);
    expect(mervFilter!.item.trade, 'HVAC');
    expect(mervFilter.item.name, contains('MERV 11'));
    expect(mervFilter.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('hvac es-US parser handles IAQ and condensate service stock', () {
    final humidifierPad = matchReceiptLineToCatalog(
      'SUPPLY PANEL HUMIDIFICADOR MODELO 10',
      localePackId: 'es-US',
      tradeScope: 'HVAC',
      maxCandidates: 320,
    );
    expect(humidifierPad, isNotNull);
    expect(humidifierPad!.item.trade, 'HVAC');
    expect(humidifierPad.item.name.toLowerCase(), contains('humidifier'));

    final drainGun = matchReceiptLineToCatalog(
      'FERG PISTOLA DRENAJE CONDENSADO',
      localePackId: 'es-US',
      tradeScope: 'HVAC',
      maxCandidates: 320,
    );
    expect(drainGun, isNotNull);
    expect(drainGun!.item.trade, 'HVAC');
    expect(drainGun.item.name.toLowerCase(), contains('drain gun'));

    final ionizingWire = matchReceiptLineToCatalog(
      'SUPPLY ALAMBRE IONIZADOR AIR CLEANER',
      localePackId: 'es-US',
      tradeScope: 'HVAC',
      maxCandidates: 320,
    );
    expect(ionizingWire, isNotNull);
    expect(ionizingWire!.item.trade, 'HVAC');
    expect(ionizingWire.item.name.toLowerCase(), contains('ionizing wire'));
  });

  test('garage es-US parser handles common door and opener wording', () {
    final spring = matchReceiptLineToCatalog(
      'SUPPLY RESORTE PUERTA GARAJE TORSION',
      localePackId: 'es-US',
      tradeScope: 'Garage Doors and Openers',
      maxCandidates: 320,
    );
    expect(spring, isNotNull);
    expect(spring!.item.trade, 'Garage Doors and Openers');
    expect(spring.item.name.toLowerCase(), contains('spring'));
    expect(spring.confidenceLevel, ReceiptConfidenceLevel.good);

    final sensor = matchReceiptLineToCatalog(
      'HD SENSOR SEGURIDAD GARAJE',
      localePackId: 'es-US',
      tradeScope: 'Garage Doors and Openers',
      maxCandidates: 320,
    );
    expect(sensor, isNotNull);
    expect(sensor!.item.trade, 'Garage Doors and Openers');
    expect(sensor.item.name.toLowerCase(), contains('sensor'));
    expect(sensor.confidenceLevel, ReceiptConfidenceLevel.good);

    final torsionSpring = matchReceiptLineToCatalog(
      '0.243 X 32IN RESORTE TORSION LEFT WIND',
      localePackId: 'es-US',
      tradeScope: 'Garage Doors and Openers',
      maxCandidates: 320,
    );
    expect(torsionSpring, isNotNull);
    expect(torsionSpring!.item.trade, 'Garage Doors and Openers');
    expect(torsionSpring.item.name.toLowerCase(), contains('spring'));
    expect(torsionSpring.confidenceLevel, ReceiptConfidenceLevel.good);

    final liftCable = matchReceiptLineToCatalog(
      '7FT CABLE ELEVACION PUERTA GARAJE PAIR',
      localePackId: 'es-US',
      tradeScope: 'Garage Doors and Openers',
      maxCandidates: 320,
    );
    expect(liftCable, isNotNull);
    expect(liftCable!.item.trade, 'Garage Doors and Openers');
    expect(liftCable.item.name.toLowerCase(), contains('cable'));
    expect(liftCable.confidenceLevel, ReceiptConfidenceLevel.good);

    final bottomSeal = matchReceiptLineToCatalog(
      '16FT SELLO INFERIOR PUERTA GARAJE T STYLE',
      localePackId: 'es-US',
      tradeScope: 'Garage Doors and Openers',
      maxCandidates: 320,
    );
    expect(bottomSeal, isNotNull);
    expect(bottomSeal!.item.trade, 'Garage Doors and Openers');
    expect(bottomSeal.item.name.toLowerCase(), contains('seal'));
    expect(bottomSeal.confidenceLevel, ReceiptConfidenceLevel.good);
  });
}
