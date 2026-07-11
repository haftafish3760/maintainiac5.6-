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
  });
}
