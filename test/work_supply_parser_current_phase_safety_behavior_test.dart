import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_store.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  group('inventory parser current-phase safety behavior', () {
    test('receipt noise never becomes an inventory material match', () {
      const noiseLines = [
        'SUBTOTAL 123.45',
        'SALES TAX 8.64',
        'TOTAL 132.09',
        'CREDIT CARD APPROVED',
        'CHANGE DUE 0.00',
      ];

      for (final line in noiseLines) {
        expect(
          matchReceiptLineToCatalog(line, maxCandidates: 300),
          isNull,
          reason: 'Receipt noise must not create inventory candidates: $line',
        );
      }
    });

    test('dangerous generic words stay unknown or low-confidence alone', () {
      const dangerousWords = [
        'PVC',
        'tape',
        'filter',
        'box',
        'adapter',
        'coupling',
        'elbow',
        'pipe',
        'wire',
        'valve',
      ];

      for (final word in dangerousWords) {
        final match = matchReceiptLineToCatalog(word, maxCandidates: 300);
        expect(
          match == null || match.confidence < .82,
          isTrue,
          reason: 'Generic word must not force a confident match: $word',
        );
      }
    });

    test('trade context separates plumbing PVC from electrical conduit', () {
      final plumbing = matchReceiptLineToCatalog(
        '3/4 PVC COUPLING SCH40',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      final electrical = matchReceiptLineToCatalog(
        '3/4 PVC COND COUPLING',
        tradeScope: 'Electrical',
        maxCandidates: 320,
      );

      expect(plumbing, isNotNull);
      expect(plumbing!.item.trade, 'Plumbing');
      expect(plumbing.item.name.toLowerCase(), contains('pvc'));
      expect(plumbing.confidenceLevel, ReceiptConfidenceLevel.good);
      expect(electrical, isNotNull);
      expect(electrical!.item.trade, 'Electrical');
      expect(electrical.item.name.toLowerCase(), contains('conduit'));
      expect(electrical.confidenceLevel, ReceiptConfidenceLevel.good);
    });

    test(
      'mixed-trade PVC shorthand stays review-level without enough evidence',
      () {
        const lines = [
          'PVC EL 3/4',
          'PVC 90 1/2',
          'CODO PVC 3/4',
          '3/4 PVC COUPLING',
        ];

        for (final line in lines) {
          final match = matchReceiptLineToCatalog(line, maxCandidates: 400);

          expect(
            match == null || match.confidence <= .81,
            isTrue,
            reason:
                'Cross-trade PVC shorthand must not become a false-confident '
                'single answer without trade/job/merchant evidence: $line '
                '=> ${match?.item.path} confidence=${match?.confidence}',
          );
        }
      },
    );

    test(
      'mixed receipt sibling lines do not auto-confirm ambiguous materials',
      () {
        const receiptLines = [
          'HD SUPPLY PVC EL 3/4 2.18',
          '12/2 NM-B WIRE 25FT 24.98',
          'MERV 8 AIR FILTER 20X25X1 11.97',
          '1/2 PEX CRIMP RING 10PK 4.28',
          'BLACK ELEC TAPE 3.97',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final pvc = parsed['HD SUPPLY PVC EL 3/4 2.18'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(2),
          reason:
              'The regression must include enough sibling evidence to tempt '
              'trade inference without letting it auto-confirm ambiguity.',
        );
        expect(
          pvc == null || pvc.confidence <= .81,
          isTrue,
          reason:
              'A mixed receipt can contain electrical, HVAC, and plumbing '
              'lines together; sibling purchases must not convert PVC EL into '
              'a final confident trade answer without explicit line evidence.',
        );
      },
    );

    test(
      'mixed receipt sibling lines do not auto-confirm ambiguous copper tubing',
      () {
        const receiptLines = [
          'SUPPLY 3/4 COPPER TUBING 18.22',
          '12/2 NM-B WIRE 25FT 24.98',
          'MERV 8 AIR FILTER 20X25X1 11.97',
          '3/4 PVC COND COUPLING 2.18',
          '1/2 PEX CRIMP RING 10PK 4.28',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final copper = parsed['SUPPLY 3/4 COPPER TUBING 18.22'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(3),
          reason:
              'The regression must include enough plumbing/electrical/HVAC '
              'siblings to tempt cross-trade inference without allowing a '
              'bare copper tubing line to jump to a final answer.',
        );
        expect(
          copper == null || copper.confidence <= .81,
          isTrue,
          reason:
              'A mixed receipt can contain plumbing, electrical, and HVAC '
              'neighbors together; sibling evidence must not convert bare '
              'copper tubing into a confident trade answer without explicit '
              'line-level clues.',
        );
      },
    );

    test(
      'mixed Spanish sibling lines do not auto-confirm ambiguous PVC shorthand',
      () {
        const receiptLines = [
          'FERRETERIA CODO PVC 3/4 2.18',
          'CABLE 12/2 NM-B 25FT 24.98',
          'DRENAJE CONDENSADO PVC 3/4 5.28',
          'VALVULA BOLA 1/2 8.49',
          'FILTRO AIRE 20X25X1 MERV 8 11.97',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(
              line,
              localePackId: 'es-US',
              maxCandidates: 420,
            ),
        };
        final pvc = parsed['FERRETERIA CODO PVC 3/4 2.18'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(3),
          reason:
              'The regression must include enough Spanish-language plumbing, '
              'electrical, and HVAC siblings to tempt trade inference without '
              'allowing a bare PVC shorthand line to become a final answer.',
        );
        expect(
          pvc == null || pvc.confidence <= .81,
          isTrue,
          reason:
              'A mixed Spanish receipt can contain plumbing, electrical, and '
              'HVAC lines together; sibling and locale evidence must not '
              'convert CODO PVC into a confident single-trade answer without '
              'explicit line-level trade evidence.',
        );
      },
    );

    test('filter dimensions require HVAC air-filter evidence', () {
      final generic = matchReceiptLineToCatalog(
        'FILTER 20X25X1',
        maxCandidates: 400,
      );
      final hvac = matchReceiptLineToCatalog(
        'MERV 8 AIR FILTER 20X25X1',
        tradeScope: 'HVAC',
        maxCandidates: 400,
      );

      expect(
        generic == null || generic.confidence <= .81,
        isTrue,
        reason:
            'A bare filter size can mean water, oil, HVAC, or other filters '
            'and must stay review-level without air/MERV/furnace evidence.',
      );
      expect(hvac, isNotNull);
      expect(hvac!.item.trade, 'HVAC');
      expect(hvac.item.name.toLowerCase(), contains('filter'));
      expect(hvac.confidenceLevel, ReceiptConfidenceLevel.good);
    });

    test(
      'new Core service-stock generic families require specific evidence',
      () {
        const genericLines = [
          'BUSHING',
          'WIRE CONNECTOR',
          'CONDENSATE DRAIN',
          'SALT PELLETS',
          'CONNECTOR KIT',
        ];

        for (final line in genericLines) {
          final match = matchReceiptLineToCatalog(line, maxCandidates: 420);

          expect(
            match == null || match.confidence <= .81,
            isTrue,
            reason:
                'Generic service-stock wording must not become a confident '
                'single answer without stronger item/trade evidence: $line '
                '=> ${match?.item.path} confidence=${match?.confidence}',
          );
        }

        final antiShort = matchReceiptLineToCatalog(
          'MC ANTI SHORT BUSHING 100PK',
          tradeScope: 'Electrical',
          maxCandidates: 420,
        );
        expect(antiShort, isNotNull);
        expect(antiShort!.item.trade, 'Electrical');
        expect(antiShort.item.name, contains('Anti Short Bushing'));
        expect(antiShort.confidenceLevel, ReceiptConfidenceLevel.good);

        final drainGun = matchReceiptLineToCatalog(
          'CONDENSATE DRAIN GUN',
          tradeScope: 'HVAC',
          maxCandidates: 420,
        );
        expect(drainGun, isNotNull);
        expect(drainGun!.item.trade, 'HVAC');
        expect(drainGun.item.name, contains('Condensate Drain Gun'));
        expect(drainGun.confidenceLevel, ReceiptConfidenceLevel.good);

        final softenerSalt = matchReceiptLineToCatalog(
          '40LB WATER SOFTENER SALT PELLETS',
          tradeScope: 'Plumbing',
          maxCandidates: 420,
        );
        expect(softenerSalt, isNotNull);
        expect(softenerSalt!.item.trade, 'Plumbing');
        expect(
          softenerSalt.item.name.toLowerCase(),
          contains('water softener salt'),
        );
        expect(softenerSalt.confidenceLevel, ReceiptConfidenceLevel.good);
      },
    );

    test(
      'bare PVC COND shorthand stays review-level even in electrical scope',
      () {
        for (final line in const [
          'GRAINGER PVC COND 3/4 5.28',
          'GRAINGER PVC COND 3/4 45.08',
        ]) {
          final match = matchReceiptLineToCatalog(
            line,
            tradeScope: 'Electrical',
            maxCandidates: 320,
          );

          expect(match, isNotNull, reason: line);
          expect(match!.item.trade, 'Electrical', reason: line);
          expect(
            match.item.name.toLowerCase(),
            contains('conduit'),
            reason: line,
          );
          expect(
            match.confidence,
            lessThanOrEqualTo(.81),
            reason:
                'Bare PVC COND can mean conduit/condensate shorthand and must '
                'remain review-level without stronger product evidence: $line',
          );
        }
      },
    );

    test(
      'local supply-house mixed receipt does not auto-confirm PVC COND shorthand',
      () {
        const receiptLines = [
          'COUNTER SALE PVC COND 3/4 5.28',
          '12/2 NM-B WIRE 25FT 24.98',
          '3/4X3/8 LINE SET 50FT 89.00',
          '1/2 PEX TEE 2.49',
          'ELEC TAPE BLK 3.97',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final pvcCond = parsed['COUNTER SALE PVC COND 3/4 5.28'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(3),
          reason:
              'The regression must include enough local/supply-house sibling '
              'evidence to tempt PEH routing without letting merchant flavor '
              'or neighboring lines convert PVC COND into a final answer.',
        );
        expect(pvcCond, isNotNull);
        expect(
          pvcCond!.confidence,
          lessThanOrEqualTo(.81),
          reason:
              'Local or counter-sale merchant wording plus mixed PEH siblings '
              'must not auto-confirm PVC COND 3/4 without explicit line-level '
              'conduit or condensate evidence.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic switch shorthand',
      () {
        const receiptLines = [
          'LOCAL SWITCH 14.98',
          '45/5 MFD DUAL RUN CAP 18.49',
          '20A WR GFCI RECPT WHITE 22.97',
          '1/2 PEX TEE 2.49',
          'MERV 8 AIR FILTER 20X25X1 11.97',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final switchLine = parsed['LOCAL SWITCH 14.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(3),
          reason:
              'The regression must include enough mixed PEH sibling evidence '
              'to tempt switch routing without letting a generic switch line '
              'collapse into a final answer.',
        );
        expect(
          switchLine == null || switchLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby HVAC/electrical/plumbing '
              'lines must not auto-confirm a bare SWITCH line without '
              'line-level evidence such as condensate, float, 3-way, dimmer, '
              'or other explicit switch-family clues.',
        );
      },
    );

    test('local mixed receipt does not auto-confirm generic tape shorthand', () {
      const receiptLines = [
        'LOCAL TAPE 6.98',
        'UL181 FOIL HVAC TAPE 12.49',
        'ELEC TAPE BLK 3PK 3.97',
        'WHITE PTFE THREAD TAPE 1.29',
        '1/2 PEX TEE 2.49',
      ];

      final parsed = {
        for (final line in receiptLines)
          line: matchReceiptLineToCatalog(line, maxCandidates: 420),
      };
      final tapeLine = parsed['LOCAL TAPE 6.98'];

      expect(
        parsed.values.whereType<ReceiptLineMatch>().length,
        greaterThanOrEqualTo(4),
        reason:
            'The regression must include enough mixed PEH tape-family '
            'siblings to tempt routing without letting a generic tape line '
            'collapse into a final answer.',
      );
      expect(
        tapeLine == null || tapeLine.confidence <= .81,
        isTrue,
        reason:
            'Local merchant flavor plus nearby HVAC/electrical/plumbing tape '
            'families must not auto-confirm a bare TAPE line without '
            'line-level evidence such as UL181, electrical, PTFE, gas, or '
            'other explicit tape-family clues.',
      );
    });

    test('local mixed receipt does not auto-confirm generic valve shorthand', () {
      const receiptLines = [
        'LOCAL VALVE 18.98',
        '3/4 BALL VALVE FIP 14.29',
        'R410A SERV VALVE CAP 6.49',
        '20A WR GFCI RECPT WHITE 22.97',
        '1/2 PEX TEE 2.49',
      ];

      final parsed = {
        for (final line in receiptLines)
          line: matchReceiptLineToCatalog(line, maxCandidates: 420),
      };
      final valveLine = parsed['LOCAL VALVE 18.98'];

      expect(
        parsed.values.whereType<ReceiptLineMatch>().length,
        greaterThanOrEqualTo(4),
        reason:
            'The regression must include enough mixed PEH valve-family '
            'siblings to tempt routing without letting a generic valve line '
            'collapse into a final answer.',
      );
      expect(
        valveLine == null || valveLine.confidence <= .81,
        isTrue,
        reason:
            'Local merchant flavor plus nearby plumbing/HVAC/electrical '
            'neighbors must not auto-confirm a bare VALVE line without '
            'line-level evidence such as ball, gate, check, PRV, fill, or '
            'service-valve clues.',
      );
    });

    test(
      'local mixed receipt does not auto-confirm generic connector shorthand',
      () {
        const receiptLines = [
          'LOCAL CONNECTOR 9.98',
          '1/2 EMT SET SCREW CONN 1.49',
          '1/2 IN X 6FT EQUIP WHIP 18.99',
          '3/8X12 TOILET CONN 6.49',
          '1/2 PEX TEE 2.49',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final connectorLine = parsed['LOCAL CONNECTOR 9.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(4),
          reason:
              'The regression must include enough mixed PEH connector-family '
              'siblings to tempt routing without letting a generic connector '
              'line collapse into a final answer.',
        );
        expect(
          connectorLine == null || connectorLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby plumbing/HVAC/electrical '
              'connector families must not auto-confirm a bare CONNECTOR line '
              'without line-level evidence such as EMT, whip, toilet, '
              'compression, liquidtight, or other explicit connector clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic coupling shorthand',
      () {
        const receiptLines = [
          'LOCAL COUPLING 4.98',
          '3/4 EMT CPLG 1.19',
          '3/4 PVC COUPLING SCH40 0.89',
          '3/4 COND PVC CPLG 2.49',
          '1/2 PEX TEE 2.49',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final couplingLine = parsed['LOCAL COUPLING 4.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(4),
          reason:
              'The regression must include enough mixed PEH coupling-family '
              'siblings to tempt routing without letting a generic coupling '
              'line collapse into a final answer.',
        );
        expect(
          couplingLine == null || couplingLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby plumbing/HVAC/electrical '
              'coupling families must not auto-confirm a bare COUPLING line '
              'without line-level evidence such as EMT, schedule 40, '
              'condensate, reducing, or other explicit coupling clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic adapter shorthand',
      () {
        const receiptLines = [
          'LOCAL ADAPTER 5.98',
          '3/4 PVC SCHEDULE 40 MALE ADAPTER 1.29',
          '3/4 PVC SCHEDULE 40 FEMALE ADAPTER 1.49',
          '3/4 PVC CONDUIT TERMINAL ADAPTER 2.19',
          'THERMOSTAT WIRE ADAPTER 19.99',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final adapterLine = parsed['LOCAL ADAPTER 5.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(4),
          reason:
              'The regression must include enough mixed PEH adapter-family '
              'siblings to tempt routing without letting a generic adapter '
              'line collapse into a final answer.',
        );
        expect(
          adapterLine == null || adapterLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby plumbing/HVAC/electrical '
              'adapter families must not auto-confirm a bare ADAPTER line '
              'without line-level evidence such as male, female, terminal, '
              'thermostat, or other explicit adapter clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic bushing shorthand',
      () {
        const receiptLines = [
          'LOCAL BUSHING 3.98',
          'MC ANTI SHORT BUSHING 100PK 6.49',
          'RED HEAD BUSHING 50PK 4.99',
          '3/4 INSULATED BUSHING 2.19',
          '3/4 PVC SPIGOT BUSHING 1.19',
          '3/4 CPVC REDUCER BUSHING 1.29',
          '3/4 BLACK IRON REDUCING BUSHING 2.49',
          '1/2 BRASS BUSHING 1.39',
          '45/5 MFD DUAL RUN CAP 18.49',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final bushingLine = parsed['LOCAL BUSHING 3.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(3),
          reason:
              'The regression must include enough mixed PEH sibling evidence '
              'to tempt bushing routing without letting a generic bushing '
              'line collapse into a final answer.',
        );
        expect(
          bushingLine == null || bushingLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby plumbing/electrical bushing '
              'families must not auto-confirm a bare BUSHING line without '
              'line-level evidence such as anti-short, reducing, PVC, CPVC, '
              'or other explicit bushing clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic cap shorthand',
      () {
        const receiptLines = [
          'LOCAL CAP 4.98',
          '1/2 COPPER CAP 1.19',
          '45/5 MFD DUAL RUN CAP 18.49',
          'R410A SERV VALVE CAP 6.49',
          '20A WR GFCI RECPT WHITE 22.97',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final capLine = parsed['LOCAL CAP 4.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(4),
          reason:
              'The regression must include enough mixed PEH cap-family '
              'siblings to tempt routing without letting a generic cap line '
              'collapse into a final answer.',
        );
        expect(
          capLine == null || capLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby plumbing/HVAC cap families '
              'must not auto-confirm a bare CAP line without line-level '
              'evidence such as copper, service valve, capacitor, or other '
              'explicit cap-family clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic pipe shorthand',
      () {
        const receiptLines = [
          'LOCAL PIPE 12.98',
          '1/2 COPPER PIPE 10FT 24.99',
          '3/4 PVC CONDUIT 10FT 8.49',
          '3/8 X 3/4 LINE SET 25FT 89.99',
          '1/2 CPVC PIPE 10FT 5.49',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final pipeLine = parsed['LOCAL PIPE 12.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(4),
          reason:
              'The regression must include enough mixed PEH pipe-family '
              'siblings to tempt routing without letting a generic pipe line '
              'collapse into a final answer.',
        );
        expect(
          pipeLine == null || pipeLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby plumbing/HVAC/electrical '
              'pipe families must not auto-confirm a bare PIPE line without '
              'line-level evidence such as copper, conduit, line set, CPVC, '
              'or other explicit pipe-family clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic tube shorthand',
      () {
        const receiptLines = [
          'LOCAL TUBE 14.98',
          '1/2 COPPER TUBE TYPE L 10FT 31.99',
          '3/8 X 3/4 LINE SET 25FT 89.99',
          '1/2 EMT CONDUIT 10FT 7.49',
          '1/2 CPVC PIPE 10FT 5.49',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final tubeLine = parsed['LOCAL TUBE 14.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(4),
          reason:
              'The regression must include enough mixed PEH tube-family '
              'siblings to tempt routing without letting a generic tube line '
              'collapse into a final answer.',
        );
        expect(
          tubeLine == null || tubeLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby plumbing/HVAC/electrical '
              'tube families must not auto-confirm a bare TUBE line without '
              'line-level evidence such as copper, line set, conduit, CPVC, '
              'or other explicit tube-family clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic elbow shorthand',
      () {
        const receiptLines = [
          'LOCAL ELBOW 6.98',
          '1/2 COPPER 90 ELBOW 1.19',
          '3/4 EMT 90 ELBOW 8.49',
          '3/4 CPVC 90 ELBOW 1.39',
          '3/4 PVC VENT ELBOW 6.89',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final elbowLine = parsed['LOCAL ELBOW 6.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(3),
          reason:
              'The regression must include enough mixed PEH elbow-family '
              'siblings to tempt routing without letting a generic elbow line '
              'collapse into a final answer.',
        );
        expect(
          elbowLine == null || elbowLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby plumbing/HVAC/electrical '
              'elbow families must not auto-confirm a bare ELBOW line '
              'without line-level evidence such as copper, conduit, CPVC, '
              'or other explicit elbow-family clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic tee shorthand',
      () {
        const receiptLines = [
          'LOCAL TEE 5.98',
          '1/2 COPPER TEE 2.19',
          '3/4 CPVC TEE 1.59',
          '3/4 PVC TEE SCH40 1.29',
          '1/2 PEX TEE 2.49',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final teeLine = parsed['LOCAL TEE 5.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(4),
          reason:
              'The regression must include enough mixed PEH tee-family '
              'siblings to tempt routing without letting a generic tee line '
              'collapse into a final answer.',
        );
        expect(
          teeLine == null || teeLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby plumbing/HVAC/electrical '
              'tee families must not auto-confirm a bare TEE line without '
              'line-level evidence such as copper, CPVC, PVC, PEX, or other '
              'explicit tee-family clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic fitting shorthand',
      () {
        const receiptLines = [
          'LOCAL FITTING 7.98',
          '1/2 COPPER TEE 2.19',
          '3/4 EMT 90 ELBOW 8.49',
          '3/4 CPVC TEE 1.59',
          '3/8 X 3/4 LINE SET 25FT 89.99',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final fittingLine = parsed['LOCAL FITTING 7.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(4),
          reason:
              'The regression must include enough mixed PEH fitting-family '
              'siblings to tempt routing without letting a generic fitting '
              'line collapse into a final answer.',
        );
        expect(
          fittingLine == null || fittingLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby plumbing/HVAC/electrical '
              'fitting families must not auto-confirm a bare FITTING line '
              'without line-level evidence such as copper, EMT, CPVC, line '
              'set, or other explicit fitting-family clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic plug shorthand',
      () {
        const receiptLines = [
          'LOCAL PLUG 6.98',
          '1/2 BRASS PLUG 2.19',
          '4 IN CLEANOUT PLUG 8.49',
          '20A PLUG FUSE 5.49',
          'DUPLEX PLUG WHITE 2.99',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final plugLine = parsed['LOCAL PLUG 6.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(3),
          reason:
              'The regression must include enough mixed PEH plug-family '
              'siblings to tempt routing without letting a generic plug line '
              'collapse into a final answer.',
        );
        expect(
          plugLine == null || plugLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby plumbing/electrical plug '
              'families must not auto-confirm a bare PLUG line without '
              'line-level evidence such as brass, cleanout, fuse, duplex, '
              'or other explicit plug-family clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic drain shorthand',
      () {
        const receiptLines = [
          'LOCAL DRAIN 8.98',
          '3/4 CONDENSATE DRAIN TEE 2.19',
          'LAVATORY DRAIN 24.99',
          'WTR HTR DRAIN PAN 16.49',
          'DW DRAIN HOSE 11.99',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final drainLine = parsed['LOCAL DRAIN 8.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(3),
          reason:
              'The regression must include enough mixed plumbing/HVAC drain '
              'siblings to tempt routing without letting a generic drain line '
              'collapse into a final answer.',
        );
        expect(
          drainLine == null || drainLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby plumbing/HVAC drain families '
              'must not auto-confirm a bare DRAIN line without line-level '
              'evidence such as condensate, lavatory, pan, hose, or other '
              'explicit drain-family clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic supply shorthand',
      () {
        const receiptLines = [
          'LOCAL SUPPLY 9.98',
          'TOILET SUPPLY LINE 8.49',
          'FAUCET SUPPLY LINE 9.49',
          'APPLIANCE SUPPLY LINE 12.99',
          'SUPPLY STOP REPAIR PART 3.19',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final supplyLine = parsed['LOCAL SUPPLY 9.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(3),
          reason:
              'The regression must include enough mixed supply-family '
              'siblings to tempt routing without letting a generic supply '
              'line collapse into a final answer.',
        );
        expect(
          supplyLine == null || supplyLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby supply-line families must '
              'not auto-confirm a bare SUPPLY line without line-level '
              'evidence such as toilet, faucet, appliance, stop, or other '
              'explicit supply-family clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic box shorthand',
      () {
        const receiptLines = [
          'LOCAL BOX 12.98',
          'OLD WORK BOX 3.49',
          'JUNCTION BOX 5.99',
          'DISCONNECT BOX 18.99',
          'RETURN BOX 24.99',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final boxLine = parsed['LOCAL BOX 12.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(3),
          reason:
              'The regression must include enough mixed electrical/HVAC box '
              'siblings to tempt routing without letting a generic box line '
              'collapse into a final answer.',
        );
        expect(
          boxLine == null || boxLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby electrical/HVAC box families '
              'must not auto-confirm a bare BOX line without line-level '
              'evidence such as old work, junction, disconnect, return, or '
              'other explicit box-family clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic wire shorthand',
      () {
        const receiptLines = [
          'LOCAL WIRE 14.98',
          'ROMEX HOUSE WIRE 25FT 34.99',
          'THERMOSTAT WIRE 50FT 29.99',
          'WIRE CONNECTOR 100PK 8.49',
          'WIRE MARKER BOOK 4.99',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final wireLine = parsed['LOCAL WIRE 14.98'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(3),
          reason:
              'The regression must include enough mixed electrical/HVAC wire '
              'siblings to tempt routing without letting a generic wire line '
              'collapse into a final answer.',
        );
        expect(
          wireLine == null || wireLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor plus nearby electrical/HVAC wire '
              'families must not auto-confirm a bare WIRE line without '
              'line-level evidence such as romex, thermostat, connector, '
              'marker, or other explicit wire-family clues.',
        );
      },
    );

    test('tape context separates HVAC foil tape from electrical tape', () {
      final hvac = matchReceiptLineToCatalog(
        'UL181 FOIL TAPE',
        tradeScope: 'HVAC',
        maxCandidates: 320,
      );
      final electrical = matchReceiptLineToCatalog(
        'BLACK ELEC TAPE',
        tradeScope: 'Electrical',
        maxCandidates: 320,
      );

      expect(hvac, isNotNull);
      expect(hvac!.item.trade, 'HVAC');
      expect(hvac.item.name.toLowerCase(), contains('tape'));
      expect(electrical, isNotNull);
      expect(electrical!.item.trade, 'Electrical');
      expect(electrical.item.name.toLowerCase(), contains('tape'));
      expect(electrical.item.id, isNot(hvac.item.id));
    });

    test('search index returns empty for impossible mixed-token query', () {
      final results = searchWorkSupplies(
        'banana submarine copper pex thermostat',
      );

      expect(results, isEmpty);
    });

    test(
      'Hive inventory store remains local authority for stock state',
      () async {
        final hiveDirectory = await Directory.systemTemp.createTemp(
          'work_supply_current_phase_authority_',
        );
        Hive.init(hiveDirectory.path);
        try {
          final store = await WorkSupplyInventoryStore.create();
          final item = _catalogItem(
            'Plumbing',
            'Copper 90 Elbow',
            variant: '1/2',
          );

          final first = await store.addStock(
            _record(
              item,
              onHand: 5,
              storageArea: 'Truck 1',
              storageDetail: 'Drawer A',
              sourceReceiptLineId: 'RCP-HIVE-L1',
            ),
          );
          await store.addStock(
            _record(
              item,
              onHand: 3,
              storageArea: 'Truck 1',
              storageDetail: 'Drawer A',
              sourceReceiptLineId: 'RCP-HIVE-L2',
            ),
          );
          await store.markOutOfStock(first);

          final inventory = store.loadInventory();
          final events = store.loadEvents();
          final transactions = store.loadTransactions();

          expect(inventory, hasLength(1));
          expect(inventory.single.id, first.id);
          expect(inventory.single.onHand, 0);
          expect(events.first.type, WorkSupplyStockEventType.countAdjusted);
          expect(
            transactions.first.type,
            WorkSupplyStockEventType.countAdjusted,
          );
          expect(
            transactions.where(
              (transaction) =>
                  transaction.type == WorkSupplyStockEventType.stockAdded,
            ),
            hasLength(2),
          );
        } finally {
          await Hive.close();
          if (hiveDirectory.existsSync()) {
            await hiveDirectory.delete(recursive: true);
          }
        }
      },
    );
  });
}

WorkSupplyItem _catalogItem(
  String trade,
  String namePart, {
  String variant = '',
}) {
  return workSupplyCatalogItems.firstWhere(
    (item) =>
        item.trade == trade &&
        item.name.toLowerCase().contains(namePart.toLowerCase()) &&
        (variant.isEmpty || item.variant.contains(variant)),
  );
}

WorkSupplyInventoryRecord _record(
  WorkSupplyItem item, {
  required double onHand,
  required String storageArea,
  required String storageDetail,
  required String sourceReceiptLineId,
}) {
  return WorkSupplyInventoryRecord(
    item: item,
    onHand: onHand,
    threshold: 1,
    lastUnitCost: 2.5,
    storageArea: storageArea,
    storageDetail: storageDetail,
    receiptLinked: true,
    sourceReceiptId: 'RCP-HIVE',
    sourceReceiptLineId: sourceReceiptLineId,
  );
}
