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
  });
}
