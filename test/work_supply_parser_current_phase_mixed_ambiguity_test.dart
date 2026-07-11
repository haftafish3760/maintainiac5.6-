import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  group('inventory parser current-phase mixed ambiguity safety', () {
    test(
      'local mixed receipt does not auto-confirm generic repair shorthand',
      () {
        final repairLine = matchReceiptLineToCatalog(
          'LOCAL REPAIR 14.98',
          maxCandidates: 80,
        );
        expect(
          repairLine == null || repairLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare REPAIR '
              'line without line-level evidence such as drain, faucet, '
              'heater, service, or other explicit repair-family clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic reparacion shorthand',
      () {
        final repairLine = matchReceiptLineToCatalog(
          'LOCAL REPARACION 14.98',
          maxCandidates: 80,
        );
        expect(
          repairLine == null || repairLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare '
              'REPARACION line without line-level evidence such as drenaje, '
              'grifo, calentador, servicio, or other explicit repair clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic service shorthand',
      () {
        final serviceLine = matchReceiptLineToCatalog(
          'LOCAL SERVICE 14.98',
          maxCandidates: 80,
        );
        expect(
          serviceLine == null || serviceLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SERVICE '
              'line without line-level evidence such as valve, head, '
              'filter, fitting, or other explicit service-family clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic servicio shorthand',
      () {
        final serviceLine = matchReceiptLineToCatalog(
          'LOCAL SERVICIO 14.98',
          maxCandidates: 80,
        );
        expect(
          serviceLine == null || serviceLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SERVICIO '
              'line without line-level evidence such as valvula, cabeza, '
              'filtro, conexion, or other explicit service clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic valvula shorthand',
      () {
        final valveLine = matchReceiptLineToCatalog(
          'LOCAL VALVULA 14.98',
          maxCandidates: 80,
        );
        expect(
          valveLine == null || valveLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare VALVULA '
              'line without line-level evidence such as alivio, llenado, '
              'angulo, servicio, or other explicit valve clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic interruptor shorthand',
      () {
        final switchLine = matchReceiptLineToCatalog(
          'LOCAL INTERRUPTOR 14.98',
          maxCandidates: 80,
        );
        expect(
          switchLine == null || switchLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare '
              'INTERRUPTOR line without line-level evidence such as 3-way, '
              'limite, presion, pared, or other explicit switch clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic caja shorthand',
      () {
        final boxLine = matchReceiptLineToCatalog(
          'LOCAL CAJA 14.98',
          maxCandidates: 80,
        );
        expect(
          boxLine == null || boxLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CAJA '
              'line without line-level evidence such as electrica, '
              'remodelacion, panel, cubierta, or other explicit box clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic filtro shorthand',
      () {
        final filterLine = matchReceiptLineToCatalog(
          'LOCAL FILTRO 14.98',
          maxCandidates: 80,
        );
        expect(
          filterLine == null || filterLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare FILTRO '
              'line without line-level evidence such as aire, secador, '
              'agua, horno, or other explicit filter clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic bomba shorthand',
      () {
        final pumpLine = matchReceiptLineToCatalog(
          'LOCAL BOMBA 14.98',
          maxCandidates: 80,
        );
        expect(
          pumpLine == null || pumpLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare BOMBA '
              'line without line-level evidence such as condensado, pozo, '
              'sumidero, agua, or other explicit pump clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic llave shorthand',
      () {
        final valveLine = matchReceiptLineToCatalog(
          'LOCAL LLAVE 14.98',
          maxCandidates: 80,
        );
        expect(
          valveLine == null || valveLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare LLAVE '
              'line without line-level evidence such as lavabo, escuadra, '
              'paso, grifo, or other explicit valve or faucet clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic conector shorthand',
      () {
        final connectorLine = matchReceiptLineToCatalog(
          'LOCAL CONECTOR 14.98',
          maxCandidates: 80,
        );
        expect(
          connectorLine == null || connectorLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CONECTOR '
              'line without line-level evidence such as romex, liquido, '
              'grifo, supply, or other explicit connector clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic codo shorthand',
      () {
        final elbowLine = matchReceiptLineToCatalog(
          'LOCAL CODO 14.98',
          maxCandidates: 80,
        );
        expect(
          elbowLine == null || elbowLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CODO '
              'line without line-level evidence such as pvc, cobre, 90, '
              'conduit, or other explicit elbow-family clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic cinta shorthand',
      () {
        final tapeLine = matchReceiptLineToCatalog(
          'LOCAL CINTA 14.98',
          maxCandidates: 80,
        );
        expect(
          tapeLine == null || tapeLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CINTA '
              'line without line-level evidence such as aluminio, electrica, '
              'teflon, ducto, or other explicit tape clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic conducto shorthand',
      () {
        final conduitLine = matchReceiptLineToCatalog(
          'LOCAL CONDUCTO 14.98',
          maxCandidates: 80,
        );
        expect(
          conduitLine == null || conduitLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CONDUCTO '
              'line without line-level evidence such as pvc, electrico, emt, '
              'sweep, or other explicit conduit clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic adaptador shorthand',
      () {
        final adapterLine = matchReceiptLineToCatalog(
          'LOCAL ADAPTADOR 14.98',
          maxCandidates: 80,
        );
        expect(
          adapterLine == null || adapterLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare ADAPTADOR '
              'line without line-level evidence such as pvc, pex, macho, '
              'hembra, or other explicit adapter clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic acople shorthand',
      () {
        final couplingLine = matchReceiptLineToCatalog(
          'LOCAL ACOPLE 14.98',
          maxCandidates: 80,
        );
        expect(
          couplingLine == null || couplingLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare ACOPLE '
              'line without line-level evidence such as pvc, cobre, union, '
              'conducto, or other explicit coupling clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic union shorthand',
      () {
        final unionLine = matchReceiptLineToCatalog(
          'LOCAL UNION 14.98',
          maxCandidates: 80,
        );
        expect(
          unionLine == null || unionLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare UNION '
              'line without line-level evidence such as dielectric, brass, '
              'compression, condensate, or other explicit union clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic bushing shorthand',
      () {
        final bushingLine = matchReceiptLineToCatalog(
          'LOCAL BUSHING 14.98',
          maxCandidates: 80,
        );
        expect(
          bushingLine == null || bushingLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare BUSHING '
              'line without line-level evidence such as reducing, insulated, '
              'PVC, brass, or other explicit bushing clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic pipe shorthand',
      () {
        final pipeLine = matchReceiptLineToCatalog(
          'LOCAL PIPE 14.98',
          maxCandidates: 80,
        );
        expect(
          pipeLine == null || pipeLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare PIPE '
              'line without line-level evidence such as pvc, copper, flue, '
              'drain, conduit, or other explicit pipe clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic tube shorthand',
      () {
        final tubeLine = matchReceiptLineToCatalog(
          'LOCAL TUBE 14.98',
          maxCandidates: 80,
        );
        expect(
          tubeLine == null || tubeLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare TUBE '
              'line without line-level evidence such as copper, condensate, '
              'extension, humidifier, or other explicit tube clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic cable shorthand',
      () {
        final cableLine = matchReceiptLineToCatalog(
          'LOCAL CABLE 14.98',
          maxCandidates: 80,
        );
        expect(
          cableLine == null || cableLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CABLE '
              'line without line-level evidence such as NM-B, UF, SER, '
              'communication, or other explicit cable clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic hose shorthand',
      () {
        final hoseLine = matchReceiptLineToCatalog(
          'LOCAL HOSE 14.98',
          maxCandidates: 80,
        );
        expect(
          hoseLine == null || hoseLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare HOSE '
              'line without line-level evidence such as washer, drain, '
              'bibb, condensate, or other explicit hose clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic strap shorthand',
      () {
        final strapLine = matchReceiptLineToCatalog(
          'LOCAL STRAP 14.98',
          maxCandidates: 80,
        );
        expect(
          strapLine == null || strapLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare STRAP '
              'line without line-level evidence such as conduit, duct, '
              'heater, fixture, or other explicit strap clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic clamp shorthand',
      () {
        final clampLine = matchReceiptLineToCatalog(
          'LOCAL CLAMP 14.98',
          maxCandidates: 80,
        );
        expect(
          clampLine == null || clampLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CLAMP '
              'line without line-level evidence such as riser, vent, '
              'ground, mast, or other explicit clamp clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic line shorthand',
      () {
        final lineItem = matchReceiptLineToCatalog(
          'LOCAL LINE 14.98',
          maxCandidates: 80,
        );
        expect(
          lineItem == null || lineItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare LINE '
              'line without line-level evidence such as supply, line set, '
              'water heater, refrigerant, or other explicit line clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic switch shorthand',
      () {
        final switchItem = matchReceiptLineToCatalog(
          'LOCAL SWITCH 14.98',
          maxCandidates: 80,
        );
        expect(
          switchItem == null || switchItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SWITCH '
              'line without line-level evidence such as float, limit, '
              'pressure, wall, or other explicit switch clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic cover shorthand',
      () {
        final coverItem = matchReceiptLineToCatalog(
          'LOCAL COVER 14.98',
          maxCandidates: 80,
        );
        expect(
          coverItem == null || coverItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare COVER '
              'line without line-level evidence such as cleanout, weatherproof, '
              'vent, access, or other explicit cover clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic panel shorthand',
      () {
        final panelItem = matchReceiptLineToCatalog(
          'LOCAL PANEL 14.98',
          maxCandidates: 80,
        );
        expect(
          panelItem == null || panelItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare PANEL '
              'line without line-level evidence such as breaker, load center, '
              'zone, water, or other explicit panel clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic trap shorthand',
      () {
        final trapItem = matchReceiptLineToCatalog(
          'LOCAL TRAP 14.98',
          maxCandidates: 80,
        );
        expect(
          trapItem == null || trapItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare TRAP '
              'line without line-level evidence such as condensate, p-trap, '
              'tubular, sediment, or other explicit trap clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic cleanout shorthand',
      () {
        final cleanoutItem = matchReceiptLineToCatalog(
          'LOCAL CLEANOUT 14.98',
          maxCandidates: 80,
        );
        expect(
          cleanoutItem == null || cleanoutItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CLEANOUT '
              'line without line-level evidence such as plug, cover, PVC, '
              'ABS, or other explicit cleanout clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic cap shorthand',
      () {
        final capItem = matchReceiptLineToCatalog(
          'LOCAL CAP 14.98',
          maxCandidates: 80,
        );
        expect(
          capItem == null || capItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CAP '
              'line without line-level evidence such as end cap, service '
              'valve, vent, roof, or other explicit cap clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic tee shorthand',
      () {
        final teeItem = matchReceiptLineToCatalog(
          'LOCAL TEE 14.98',
          maxCandidates: 80,
        );
        expect(
          teeItem == null || teeItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare TEE '
              'line without line-level evidence such as sanitary, reducing, '
              'PVC, copper, or other explicit tee clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic valve shorthand',
      () {
        final valveItem = matchReceiptLineToCatalog(
          'LOCAL VALVE 14.98',
          maxCandidates: 80,
        );
        expect(
          valveItem == null || valveItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare VALVE '
              'line without line-level evidence such as ball, check, gate, '
              'gas, stop, or other explicit valve clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic adapter shorthand',
      () {
        final adapterItem = matchReceiptLineToCatalog(
          'LOCAL ADAPTER 14.98',
          maxCandidates: 80,
        );
        expect(
          adapterItem == null || adapterItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare ADAPTER '
              'line without line-level evidence such as male, female, trap, '
              'conduit, PVC, or other explicit adapter clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic elbow shorthand',
      () {
        final elbowItem = matchReceiptLineToCatalog(
          'LOCAL ELBOW 14.98',
          maxCandidates: 80,
        );
        expect(
          elbowItem == null || elbowItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare ELBOW '
              'line without line-level evidence such as 90, 45, conduit, '
              'PVC, copper, or other explicit elbow clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic coupling shorthand',
      () {
        final couplingItem = matchReceiptLineToCatalog(
          'LOCAL COUPLING 14.98',
          maxCandidates: 80,
        );
        expect(
          couplingItem == null || couplingItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare COUPLING '
              'line without line-level evidence such as repair, conduit, '
              'PVC, copper, or other explicit coupling clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic connector shorthand',
      () {
        final connectorItem = matchReceiptLineToCatalog(
          'LOCAL CONNECTOR 14.98',
          maxCandidates: 80,
        );
        expect(
          connectorItem == null || connectorItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CONNECTOR '
              'line without line-level evidence such as conduit, cable, '
              'flex, PVC, or other explicit connector clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic conduit shorthand',
      () {
        final conduitItem = matchReceiptLineToCatalog(
          'LOCAL CONDUIT 14.98',
          maxCandidates: 80,
        );
        expect(
          conduitItem == null || conduitItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CONDUIT '
              'line without line-level evidence such as EMT, PVC, sweep, '
              'electrical, or other explicit conduit clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic box shorthand',
      () {
        final boxItem = matchReceiptLineToCatalog(
          'LOCAL BOX 14.98',
          maxCandidates: 80,
        );
        expect(
          boxItem == null || boxItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare BOX '
              'line without line-level evidence such as junction, device, '
              'outlet, repair, or other explicit box clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic filter shorthand',
      () {
        final filterItem = matchReceiptLineToCatalog(
          'LOCAL FILTER 14.98',
          maxCandidates: 80,
        );
        expect(
          filterItem == null || filterItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare FILTER '
              'line without line-level evidence such as air, water, whole '
              'house, return, or other explicit filter clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic pump shorthand',
      () {
        final pumpItem = matchReceiptLineToCatalog(
          'LOCAL PUMP 14.98',
          maxCandidates: 80,
        );
        expect(
          pumpItem == null || pumpItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare PUMP '
              'line without line-level evidence such as condensate, well, '
              'sump, circulation, or other explicit pump clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic tape shorthand',
      () {
        final tapeItem = matchReceiptLineToCatalog(
          'LOCAL TAPE 14.98',
          maxCandidates: 80,
        );
        expect(
          tapeItem == null || tapeItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare TAPE '
              'line without line-level evidence such as electrical, teflon, '
              'foil, duct, or other explicit tape clues.',
        );
      },
    );
  });
}
