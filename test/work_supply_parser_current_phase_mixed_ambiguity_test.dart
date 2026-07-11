import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  group('inventory parser current-phase mixed ambiguity safety', () {
    test(
      'local mixed receipt does not auto-confirm generic motor shorthand',
      () {
        final motorItem = matchReceiptLineToCatalog(
          'LOCAL MOTOR 14.98',
          maxCandidates: 80,
        );
        expect(
          motorItem == null || motorItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare MOTOR '
              'line without line-level evidence such as blower, fan, '
              'pump, or other explicit motor clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic ceiling shorthand',
      () {
        final ceilingItem = matchReceiptLineToCatalog(
          'LOCAL CEILING 14.98',
          maxCandidates: 80,
        );
        expect(
          ceilingItem == null || ceilingItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CEILING '
              'line without line-level evidence such as fan, box, '
              'register, or other explicit ceiling clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic sensor shorthand',
      () {
        final sensorItem = matchReceiptLineToCatalog(
          'LOCAL SENSOR 14.98',
          maxCandidates: 80,
        );
        expect(
          sensorItem == null || sensorItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SENSOR '
              'line without line-level evidence such as flame, outdoor, '
              'defrost, or other explicit sensor clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic control shorthand',
      () {
        final controlItem = matchReceiptLineToCatalog(
          'LOCAL CONTROL 14.98',
          maxCandidates: 80,
        );
        expect(
          controlItem == null || controlItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CONTROL '
              'line without line-level evidence such as zone, valve, '
              'panel, or other explicit control clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic relay shorthand',
      () {
        final relayItem = matchReceiptLineToCatalog(
          'LOCAL RELAY 14.98',
          maxCandidates: 80,
        );
        expect(
          relayItem == null || relayItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare RELAY '
              'line without line-level evidence such as time delay, fan, '
              'potential, or other explicit relay clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic heater shorthand',
      () {
        final heaterItem = matchReceiptLineToCatalog(
          'LOCAL HEATER 14.98',
          maxCandidates: 80,
        );
        expect(
          heaterItem == null || heaterItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare HEATER '
              'line without line-level evidence such as water, crankcase, '
              'baseboard, or other explicit heater clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic capacitor shorthand',
      () {
        final capacitorItem = matchReceiptLineToCatalog(
          'LOCAL CAPACITOR 14.98',
          maxCandidates: 80,
        );
        expect(
          capacitorItem == null || capacitorItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CAPACITOR '
              'line without line-level evidence such as run, dual, start, '
              'MFD, or other explicit capacitor clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic contactor shorthand',
      () {
        final contactorItem = matchReceiptLineToCatalog(
          'LOCAL CONTACTOR 14.98',
          maxCandidates: 80,
        );
        expect(
          contactorItem == null || contactorItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CONTACTOR '
              'line without line-level evidence such as compressor, pole, '
              'coil, or other explicit contactor clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic board shorthand',
      () {
        final boardItem = matchReceiptLineToCatalog(
          'LOCAL BOARD 14.98',
          maxCandidates: 80,
        );
        expect(
          boardItem == null || boardItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare BOARD '
              'line without line-level evidence such as control, furnace, '
              'foam, backer, or other explicit board clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic terminal shorthand',
      () {
        final terminalItem = matchReceiptLineToCatalog(
          'LOCAL TERMINAL 14.98',
          maxCandidates: 80,
        );
        expect(
          terminalItem == null || terminalItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare TERMINAL '
              'line without line-level evidence such as spade, fork, strip, '
              'adapter, or other explicit terminal clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic transformer shorthand',
      () {
        final transformerItem = matchReceiptLineToCatalog(
          'LOCAL TRANSFORMER 14.98',
          maxCandidates: 80,
        );
        expect(
          transformerItem == null || transformerItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare '
              'TRANSFORMER line without line-level evidence such as 24V, '
              'doorbell, lighting, or other explicit transformer clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic fuse shorthand',
      () {
        final fuseItem = matchReceiptLineToCatalog(
          'LOCAL FUSE 14.98',
          maxCandidates: 80,
        );
        expect(
          fuseItem == null || fuseItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare FUSE '
              'line without line-level evidence such as blade, cartridge, '
              'plug, amp, or other explicit fuse clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic disconnect shorthand',
      () {
        final disconnectItem = matchReceiptLineToCatalog(
          'LOCAL DISCONNECT 14.98',
          maxCandidates: 80,
        );
        expect(
          disconnectItem == null || disconnectItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare '
              'DISCONNECT line without line-level evidence such as AC, '
              'pullout, fusible, or other explicit disconnect clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic whip shorthand',
      () {
        final whipItem = matchReceiptLineToCatalog(
          'LOCAL WHIP 14.98',
          maxCandidates: 80,
        );
        expect(
          whipItem == null || whipItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare WHIP '
              'line without line-level evidence such as AC, equipment, '
              'liquidtight, or other explicit whip clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic thermostat shorthand',
      () {
        final thermostatItem = matchReceiptLineToCatalog(
          'LOCAL THERMOSTAT 14.98',
          maxCandidates: 80,
        );
        expect(
          thermostatItem == null || thermostatItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare '
              'THERMOSTAT line without line-level evidence such as heat '
              'pump, programmable, smart, or other explicit thermostat clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic float shorthand',
      () {
        final floatItem = matchReceiptLineToCatalog(
          'LOCAL FLOAT 14.98',
          maxCandidates: 80,
        );
        expect(
          floatItem == null || floatItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare FLOAT '
              'line without line-level evidence such as switch, pan, pump, '
              'or other explicit float clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic breaker shorthand',
      () {
        final breakerItem = matchReceiptLineToCatalog(
          'LOCAL BREAKER 14.98',
          maxCandidates: 80,
        );
        expect(
          breakerItem == null || breakerItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare BREAKER '
              'line without line-level evidence such as 1P, 2P, GFCI, AFCI, '
              'amp, or other explicit breaker clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic receptacle shorthand',
      () {
        final receptacleItem = matchReceiptLineToCatalog(
          'LOCAL RECEPTACLE 14.98',
          maxCandidates: 80,
        );
        expect(
          receptacleItem == null || receptacleItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare RECEPTACLE '
              'line without line-level evidence such as duplex, GFCI, WR, '
              'outlet, or other explicit receptacle clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic outlet shorthand',
      () {
        final outletItem = matchReceiptLineToCatalog(
          'LOCAL OUTLET 14.98',
          maxCandidates: 80,
        );
        expect(
          outletItem == null || outletItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare OUTLET '
              'line without line-level evidence such as duplex, GFCI, wall, '
              'receptacle, or other explicit outlet clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic junction shorthand',
      () {
        final junctionItem = matchReceiptLineToCatalog(
          'LOCAL JUNCTION 14.98',
          maxCandidates: 80,
        );
        expect(
          junctionItem == null || junctionItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare JUNCTION '
              'line without line-level evidence such as box, splice, pull, '
              'or other explicit junction clues.',
        );
      },
    );

    test('local mixed receipt does not auto-confirm generic nut shorthand', () {
      final nutItem = matchReceiptLineToCatalog(
        'LOCAL NUT 14.98',
        maxCandidates: 80,
      );
      expect(
        nutItem == null || nutItem.confidence <= .81,
        isTrue,
        reason:
            'Local merchant flavor must not auto-confirm a bare NUT '
            'line without line-level evidence such as lock, wire, '
            'compression, or other explicit nut clues.',
      );
    });

    test('local mixed receipt does not auto-confirm generic kit shorthand', () {
      final kitItem = matchReceiptLineToCatalog(
        'LOCAL KIT 14.98',
        maxCandidates: 80,
      );
      expect(
        kitItem == null || kitItem.confidence <= .81,
        isTrue,
        reason:
            'Local merchant flavor must not auto-confirm a bare KIT '
            'line without line-level evidence such as repair, toilet, '
            'faucet, or other explicit kit clues.',
      );
    });

    test(
      'local mixed receipt does not auto-confirm generic guard shorthand',
      () {
        final guardItem = matchReceiptLineToCatalog(
          'LOCAL GUARD 14.98',
          maxCandidates: 80,
        );
        expect(
          guardItem == null || guardItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare GUARD '
              'line without line-level evidence such as fan, blade, '
              'wire, or other explicit guard clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic case shorthand',
      () {
        final caseItem = matchReceiptLineToCatalog(
          'LOCAL CASE 14.98',
          maxCandidates: 80,
        );
        expect(
          caseItem == null || caseItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CASE '
              'line without line-level evidence such as breaker, motor, '
              'housing, or other explicit case clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic cage shorthand',
      () {
        final cageItem = matchReceiptLineToCatalog(
          'LOCAL CAGE 14.98',
          maxCandidates: 80,
        );
        expect(
          cageItem == null || cageItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CAGE '
              'line without line-level evidence such as fan, guard, '
              'lamp, or other explicit cage clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic housing shorthand',
      () {
        final housingItem = matchReceiptLineToCatalog(
          'LOCAL HOUSING 14.98',
          maxCandidates: 80,
        );
        expect(
          housingItem == null || housingItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare HOUSING '
              'line without line-level evidence such as motor, fan, '
              'trim, or other explicit housing clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic bolt shorthand',
      () {
        final boltItem = matchReceiptLineToCatalog(
          'LOCAL BOLT 14.98',
          maxCandidates: 80,
        );
        expect(
          boltItem == null || boltItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare BOLT '
              'line without line-level evidence such as anchor, carriage, '
              'lag, or other explicit bolt clues.',
        );
      },
    );

    test('local mixed receipt does not auto-confirm generic rod shorthand', () {
      final rodItem = matchReceiptLineToCatalog(
        'LOCAL ROD 14.98',
        maxCandidates: 80,
      );
      expect(
        rodItem == null || rodItem.confidence <= .81,
        isTrue,
        reason:
            'Local merchant flavor must not auto-confirm a bare ROD '
            'line without line-level evidence such as threaded, hanger, '
            'anode, or other explicit rod clues.',
      );
    });

    test(
      'local mixed receipt does not auto-confirm generic branch shorthand',
      () {
        final branchItem = matchReceiptLineToCatalog(
          'LOCAL BRANCH 14.98',
          maxCandidates: 80,
        );
        expect(
          branchItem == null || branchItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare BRANCH '
              'line without line-level evidence such as circuit, wye, '
              'drain, or other explicit branch clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic splice shorthand',
      () {
        final spliceItem = matchReceiptLineToCatalog(
          'LOCAL SPLICE 14.98',
          maxCandidates: 80,
        );
        expect(
          spliceItem == null || spliceItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SPLICE '
              'line without line-level evidence such as wire, kit, '
              'repair, or other explicit splice clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic joint shorthand',
      () {
        final jointItem = matchReceiptLineToCatalog(
          'LOCAL JOINT 14.98',
          maxCandidates: 80,
        );
        expect(
          jointItem == null || jointItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare JOINT '
              'line without line-level evidence such as expansion, slip, '
              'repair, or other explicit joint clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic stub shorthand',
      () {
        final stubItem = matchReceiptLineToCatalog(
          'LOCAL STUB 14.98',
          maxCandidates: 80,
        );
        expect(
          stubItem == null || stubItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare STUB '
              'line without line-level evidence such as out, nipple, '
              'pipe, or other explicit stub clues.',
        );
      },
    );

    test('local mixed receipt does not auto-confirm generic pan shorthand', () {
      final panItem = matchReceiptLineToCatalog(
        'LOCAL PAN 14.98',
        maxCandidates: 80,
      );
      expect(
        panItem == null || panItem.confidence <= .81,
        isTrue,
        reason:
            'Local merchant flavor must not auto-confirm a bare PAN '
            'line without line-level evidence such as drain, shower, '
            'heater, or other explicit pan clues.',
      );
    });

    test(
      'local mixed receipt does not auto-confirm generic shell shorthand',
      () {
        final shellItem = matchReceiptLineToCatalog(
          'LOCAL SHELL 14.98',
          maxCandidates: 80,
        );
        expect(
          shellItem == null || shellItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SHELL '
              'line without line-level evidence such as housing, cover, '
              'case, or other explicit shell clues.',
        );
      },
    );

    test('local mixed receipt does not auto-confirm generic bar shorthand', () {
      final barItem = matchReceiptLineToCatalog(
        'LOCAL BAR 14.98',
        maxCandidates: 80,
      );
      expect(
        barItem == null || barItem.confidence <= .81,
        isTrue,
        reason:
            'Local merchant flavor must not auto-confirm a bare BAR '
            'line without line-level evidence such as support, grab, '
            'hanger, or other explicit bar clues.',
      );
    });

    test(
      'local mixed receipt does not auto-confirm generic tray shorthand',
      () {
        final trayItem = matchReceiptLineToCatalog(
          'LOCAL TRAY 14.98',
          maxCandidates: 80,
        );
        expect(
          trayItem == null || trayItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare TRAY '
              'line without line-level evidence such as drain, shower, '
              'pan, or other explicit tray clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic channel shorthand',
      () {
        final channelItem = matchReceiptLineToCatalog(
          'LOCAL CHANNEL 14.98',
          maxCandidates: 80,
        );
        expect(
          channelItem == null || channelItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CHANNEL '
              'line without line-level evidence such as strut, rail, '
              'track, or other explicit channel clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic rail shorthand',
      () {
        final railItem = matchReceiptLineToCatalog(
          'LOCAL RAIL 14.98',
          maxCandidates: 80,
        );
        expect(
          railItem == null || railItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare RAIL '
              'line without line-level evidence such as support, track, '
              'channel, or other explicit rail clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic anchor shorthand',
      () {
        final anchorItem = matchReceiptLineToCatalog(
          'LOCAL ANCHOR 14.98',
          maxCandidates: 80,
        );
        expect(
          anchorItem == null || anchorItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare ANCHOR '
              'line without line-level evidence such as wall, sleeve, '
              'bolt, or other explicit anchor clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic post shorthand',
      () {
        final postItem = matchReceiptLineToCatalog(
          'LOCAL POST 14.98',
          maxCandidates: 80,
        );
        expect(
          postItem == null || postItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare POST '
              'line without line-level evidence such as fence, support, '
              'base, or other explicit post clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic collar shorthand',
      () {
        final collarItem = matchReceiptLineToCatalog(
          'LOCAL COLLAR 14.98',
          maxCandidates: 80,
        );
        expect(
          collarItem == null || collarItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare COLLAR '
              'line without line-level evidence such as pipe, escutcheon, '
              'duct, or other explicit collar clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic hook shorthand',
      () {
        final hookItem = matchReceiptLineToCatalog(
          'LOCAL HOOK 14.98',
          maxCandidates: 80,
        );
        expect(
          hookItem == null || hookItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare HOOK '
              'line without line-level evidence such as hanger, wall, '
              'tool, or other explicit hook clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic clip shorthand',
      () {
        final clipItem = matchReceiptLineToCatalog(
          'LOCAL CLIP 14.98',
          maxCandidates: 80,
        );
        expect(
          clipItem == null || clipItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CLIP '
              'line without line-level evidence such as conduit, pipe, '
              'spring, or other explicit clip clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic sleeve shorthand',
      () {
        final sleeveItem = matchReceiptLineToCatalog(
          'LOCAL SLEEVE 14.98',
          maxCandidates: 80,
        );
        expect(
          sleeveItem == null || sleeveItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SLEEVE '
              'line without line-level evidence such as repair, anchor, '
              'pipe, or other explicit sleeve clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic body shorthand',
      () {
        final bodyItem = matchReceiptLineToCatalog(
          'LOCAL BODY 14.98',
          maxCandidates: 80,
        );
        expect(
          bodyItem == null || bodyItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare BODY '
              'line without line-level evidence such as valve, faucet, '
              'sprayer, or other explicit body clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic ring shorthand',
      () {
        final ringItem = matchReceiptLineToCatalog(
          'LOCAL RING 14.98',
          maxCandidates: 80,
        );
        expect(
          ringItem == null || ringItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare RING '
              'line without line-level evidence such as wax, closet, '
              'trim, or other explicit ring clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic hinge shorthand',
      () {
        final hingeItem = matchReceiptLineToCatalog(
          'LOCAL HINGE 14.98',
          maxCandidates: 80,
        );
        expect(
          hingeItem == null || hingeItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare HINGE '
              'line without line-level evidence such as toilet, door, '
              'seat, or other explicit hinge clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic spring shorthand',
      () {
        final springItem = matchReceiptLineToCatalog(
          'LOCAL SPRING 14.98',
          maxCandidates: 80,
        );
        expect(
          springItem == null || springItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SPRING '
              'line without line-level evidence such as faucet, door, '
              'trap, or other explicit spring clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic handle shorthand',
      () {
        final handleItem = matchReceiptLineToCatalog(
          'LOCAL HANDLE 14.98',
          maxCandidates: 80,
        );
        expect(
          handleItem == null || handleItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare HANDLE '
              'line without line-level evidence such as faucet, door, '
              'toilet, or other explicit handle clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic lever shorthand',
      () {
        final leverItem = matchReceiptLineToCatalog(
          'LOCAL LEVER 14.98',
          maxCandidates: 80,
        );
        expect(
          leverItem == null || leverItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare LEVER '
              'line without line-level evidence such as flush, valve, '
              'door, or other explicit lever clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic seat shorthand',
      () {
        final seatItem = matchReceiptLineToCatalog(
          'LOCAL SEAT 14.98',
          maxCandidates: 80,
        );
        expect(
          seatItem == null || seatItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SEAT '
              'line without line-level evidence such as toilet, faucet, '
              'valve, or other explicit seat clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic stop shorthand',
      () {
        final stopItem = matchReceiptLineToCatalog(
          'LOCAL STOP 14.98',
          maxCandidates: 80,
        );
        expect(
          stopItem == null || stopItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare STOP '
              'line without line-level evidence such as angle, door, '
              'compression, or other explicit stop clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic gasket shorthand',
      () {
        final gasketItem = matchReceiptLineToCatalog(
          'LOCAL GASKET 14.98',
          maxCandidates: 80,
        );
        expect(
          gasketItem == null || gasketItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare GASKET '
              'line without line-level evidence such as toilet, flange, '
              'burner, or other explicit gasket clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic hanger shorthand',
      () {
        final hangerItem = matchReceiptLineToCatalog(
          'LOCAL HANGER 14.98',
          maxCandidates: 80,
        );
        expect(
          hangerItem == null || hangerItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare HANGER '
              'line without line-level evidence such as pipe, strap, '
              'beam, or other explicit hanger clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic bracket shorthand',
      () {
        final bracketItem = matchReceiptLineToCatalog(
          'LOCAL BRACKET 14.98',
          maxCandidates: 80,
        );
        expect(
          bracketItem == null || bracketItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare BRACKET '
              'line without line-level evidence such as support, shelf, '
              'fan, or other explicit bracket clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic flange shorthand',
      () {
        final flangeItem = matchReceiptLineToCatalog(
          'LOCAL FLANGE 14.98',
          maxCandidates: 80,
        );
        expect(
          flangeItem == null || flangeItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare FLANGE '
              'line without line-level evidence such as closet, toilet, '
              'hub, or other explicit flange clues.',
        );
      },
    );

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
      'local mixed receipt does not auto-confirm sized union without trade context',
      () {
        final sizedUnionLine = matchReceiptLineToCatalog(
          'LOCAL UNION 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedUnionLine == null || sizedUnionLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized UNION '
              'line when the receipt still lacks dielectric, brass, '
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
      'local mixed receipt does not auto-confirm sized bushing without trade context',
      () {
        final sizedBushingLine = matchReceiptLineToCatalog(
          'LOCAL BUSHING 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedBushingLine == null || sizedBushingLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized BUSHING '
              'line when the receipt still lacks conduit, reducing, PVC, '
              'brass, or other explicit system-level bushing clues.',
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
      'local mixed receipt does not auto-confirm sized pipe without trade context',
      () {
        final sizedPipeLine = matchReceiptLineToCatalog(
          'LOCAL PIPE 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedPipeLine == null || sizedPipeLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized PIPE '
              'line when the receipt still lacks PVC, copper, EMT, drain, '
              'gas, vent, or other system-level pipe clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm bare copper without trade context',
      () {
        final copperLine = matchReceiptLineToCatalog(
          'LOCAL COPPER 14.98',
          maxCandidates: 80,
        );
        expect(
          copperLine == null || copperLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare COPPER '
              'line without tubing, fitting, coil, pipe, or other trade '
              'context on the receipt line itself.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm small pvc pipe without system context',
      () {
        final pvcPipeLine = matchReceiptLineToCatalog(
          'LOCAL PVC 3/4 PIPE 14.98',
          maxCandidates: 80,
        );
        expect(
          pvcPipeLine == null || pvcPipeLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a small PVC pipe '
              'line when no plumbing, electrical, or HVAC system context is '
              'present on the receipt line itself.',
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
      'local mixed receipt does not auto-confirm sized tube without trade context',
      () {
        final sizedTubeLine = matchReceiptLineToCatalog(
          'LOCAL TUBE 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedTubeLine == null || sizedTubeLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized TUBE '
              'line when the receipt still lacks copper, condensate, '
              'refrigerant, softener, drain, or other explicit tube clues.',
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
      'local mixed receipt does not auto-confirm sized cable without trade context',
      () {
        final sizedCableLine = matchReceiptLineToCatalog(
          'LOCAL CABLE 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedCableLine == null || sizedCableLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized CABLE '
              'line when the receipt still lacks romex, nm, mc, low voltage, '
              'thermostat, mini split, or other explicit cable clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm bare wire without electrical context',
      () {
        final wireLine = matchReceiptLineToCatalog(
          'LOCAL WIRE 14.98',
          maxCandidates: 80,
        );
        expect(
          wireLine == null || wireLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare WIRE '
              'line without gauge, type, spool, grounding, or other '
              'electrical context on the receipt line itself.',
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
      'local mixed receipt does not auto-confirm sized hose without trade context',
      () {
        final sizedHoseLine = matchReceiptLineToCatalog(
          'LOCAL HOSE 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedHoseLine == null || sizedHoseLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized HOSE '
              'line when the receipt still lacks washer, drain, garden, '
              'condensate, supply, or other explicit hose clues.',
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
      'local mixed receipt does not auto-confirm sized strap without trade context',
      () {
        final sizedStrapLine = matchReceiptLineToCatalog(
          'LOCAL STRAP 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedStrapLine == null || sizedStrapLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized STRAP '
              'line when the receipt still lacks conduit, hanger, water '
              'heater, pipe, vent, or other explicit strap clues.',
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
      'local mixed receipt does not auto-confirm sized clamp without trade context',
      () {
        final sizedClampLine = matchReceiptLineToCatalog(
          'LOCAL CLAMP 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedClampLine == null || sizedClampLine.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized CLAMP '
              'line when the receipt still lacks riser, beam, vent, pipe, '
              'grounding, ring, or other explicit clamp clues.',
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
      'local mixed receipt does not auto-confirm sized line without trade context',
      () {
        final sizedLineItem = matchReceiptLineToCatalog(
          'LOCAL LINE 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedLineItem == null || sizedLineItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized LINE '
              'line when the receipt still lacks supply, line set, '
              'refrigerant, copper, condensate, gas, or other explicit line clues.',
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
      'local mixed receipt does not auto-confirm sized switch without trade context',
      () {
        final sizedSwitchItem = matchReceiptLineToCatalog(
          'LOCAL SWITCH 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedSwitchItem == null || sizedSwitchItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized SWITCH '
              'line when the receipt still lacks float, pressure, wall, '
              'toggle, timer, safety, or other explicit switch clues.',
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
      'local mixed receipt does not auto-confirm sized cover without trade context',
      () {
        final sizedCoverItem = matchReceiptLineToCatalog(
          'LOCAL COVER 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedCoverItem == null || sizedCoverItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized COVER '
              'line when the receipt still lacks cleanout, access, weatherproof, '
              'plate, device, vent, or other explicit cover clues.',
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
      'local mixed receipt does not auto-confirm sized panel without trade context',
      () {
        final sizedPanelItem = matchReceiptLineToCatalog(
          'LOCAL PANEL 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedPanelItem == null || sizedPanelItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized PANEL '
              'line when the receipt still lacks breaker, load center, service, '
              'zone, humidifier, cabinet, or other explicit panel clues.',
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
      'local mixed receipt does not auto-confirm sized trap without trade context',
      () {
        final sizedTrapItem = matchReceiptLineToCatalog(
          'LOCAL TRAP 1-1/2 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedTrapItem == null || sizedTrapItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized TRAP '
              'line when the receipt still lacks p-trap, tubular, lav, '
              'sink, condensate, or other system-level trap clues.',
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
      'local mixed receipt does not auto-confirm sized cleanout without trade context',
      () {
        final sizedCleanoutItem = matchReceiptLineToCatalog(
          'LOCAL CLEANOUT 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedCleanoutItem == null || sizedCleanoutItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized CLEANOUT '
              'line when the receipt still lacks plug, cover, tee, pvc, abs, '
              'dwv, brass, or other explicit cleanout clues.',
        );
      },
    );

    test('local mixed receipt does not auto-confirm generic cap shorthand', () {
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
    });

    test(
      'local mixed receipt does not auto-confirm sized cap without trade context',
      () {
        final sizedCapItem = matchReceiptLineToCatalog(
          'LOCAL CAP 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedCapItem == null || sizedCapItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized CAP '
              'line when the receipt still lacks copper, end cap, service, '
              'valve, capacitor, or other system-level cap clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm bare condensate without hvac context',
      () {
        final condensateItem = matchReceiptLineToCatalog(
          'LOCAL CONDENSATE 14.98',
          maxCandidates: 80,
        );
        expect(
          condensateItem == null || condensateItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CONDENSATE '
              'line without drain, pump, tubing, trap, or other HVAC '
              'context on the receipt line itself.',
        );
      },
    );

    test('local mixed receipt does not auto-confirm generic tee shorthand', () {
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
    });

    test(
      'local mixed receipt does not auto-confirm sized tee without trade context',
      () {
        final sizedTeeItem = matchReceiptLineToCatalog(
          'LOCAL TEE 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedTeeItem == null || sizedTeeItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized TEE '
              'line when the receipt still lacks material or system clues '
              'such as PVC, copper, PEX, conduit, or condensate context.',
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
      'local mixed receipt does not auto-confirm sized valve without trade context',
      () {
        final sizedValveItem = matchReceiptLineToCatalog(
          'LOCAL VALVE 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedValveItem == null || sizedValveItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized VALVE '
              'line when the receipt still lacks ball, gate, relief, '
              'stop, service, gas, or other system-level valve context.',
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
      'local mixed receipt does not auto-confirm sized adapter without trade context',
      () {
        final sizedAdapterItem = matchReceiptLineToCatalog(
          'LOCAL ADAPTER 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedAdapterItem == null || sizedAdapterItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized ADAPTER '
              'line when the receipt still lacks male, female, trap, '
              'conduit, PVC, copper, or other system-level adapter clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm threaded adapter shorthand without trade context',
      () {
        final threadedAdapterItem = matchReceiptLineToCatalog(
          'LOCAL 1/2 MIP X FIP 14.98',
          maxCandidates: 80,
        );
        expect(
          threadedAdapterItem == null || threadedAdapterItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare threaded '
              'MIP X FIP shorthand line when the receipt still lacks '
              'material, valve, supply, connector, or other system-level '
              'adapter evidence.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm bare black without trade context',
      () {
        final blackItem = matchReceiptLineToCatalog(
          'LOCAL BLACK 14.98',
          maxCandidates: 80,
        );
        expect(
          blackItem == null || blackItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare BLACK '
              'line without pipe, iron, fitting, paint, or other trade '
              'context on the receipt line itself.',
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
      'local mixed receipt does not auto-confirm pvc elbow without trade context',
      () {
        final pvcElbowItem = matchReceiptLineToCatalog(
          'LOCAL PVC 3/4 ELBOW 14.98',
          maxCandidates: 80,
        );
        expect(
          pvcElbowItem == null || pvcElbowItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a PVC elbow line '
              'when the line still lacks plumbing, electrical, or HVAC '
              'system-level context.',
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
      'local mixed receipt does not auto-confirm sized coupling without trade context',
      () {
        final sizedCouplingItem = matchReceiptLineToCatalog(
          'LOCAL COUPLING 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedCouplingItem == null || sizedCouplingItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized COUPLING '
              'line when the receipt still lacks material or trade clues '
              'such as PVC, copper, conduit, or DWV context.',
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
      'local mixed receipt does not auto-confirm sized connector without trade context',
      () {
        final sizedConnectorItem = matchReceiptLineToCatalog(
          'LOCAL CONNECTOR 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedConnectorItem == null || sizedConnectorItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized CONNECTOR '
              'line when the receipt still lacks conduit, wire, toilet, '
              'faucet, gas, whip, or other system-level connector clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm connector kit without system context',
      () {
        final connectorKitItem = matchReceiptLineToCatalog(
          'LOCAL CONNECTOR KIT 14.98',
          maxCandidates: 80,
        );
        expect(
          connectorKitItem == null || connectorKitItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a connector kit '
              'line without dishwasher, toilet, faucet, gas, dryer, '
              'appliance, or electrical context.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm wire connector without electrical clues',
      () {
        final wireConnectorItem = matchReceiptLineToCatalog(
          'LOCAL WIRE CONNECTOR 14.98',
          maxCandidates: 80,
        );
        expect(
          wireConnectorItem == null || wireConnectorItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a wire connector '
              'line when the line still lacks splice, grounding, twister, '
              'electrical, or other line-level electrical clues.',
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
      'local mixed receipt does not auto-confirm sized conduit without trade context',
      () {
        final sizedConduitItem = matchReceiptLineToCatalog(
          'LOCAL CONDUIT 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedConduitItem == null || sizedConduitItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized CONDUIT '
              'line when the receipt still lacks EMT, electrical, rigid, '
              'PVC, or other system-level conduit clues.',
        );
      },
    );

    test('local mixed receipt does not auto-confirm generic box shorthand', () {
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
    });

    test(
      'local mixed receipt does not auto-confirm sized box without trade context',
      () {
        final sizedBoxItem = matchReceiptLineToCatalog(
          'LOCAL BOX 4X4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedBoxItem == null || sizedBoxItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized BOX '
              'line when the receipt still lacks junction, device, outlet, '
              'gang, square, or other system-level box clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm j box without electrical context',
      () {
        final jBoxItem = matchReceiptLineToCatalog(
          'LOCAL J BOX 14.98',
          maxCandidates: 80,
        );
        expect(
          jBoxItem == null || jBoxItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a J BOX line '
              'without device, junction, outlet, splice, or other explicit '
              'electrical box clues.',
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
      'local mixed receipt does not auto-confirm sized filter without hvac or water context',
      () {
        final sizedFilterItem = matchReceiptLineToCatalog(
          'LOCAL FILTER 16 x 20 x 1 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedFilterItem == null || sizedFilterItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized FILTER '
              'line when the receipt still lacks furnace, return, MERV, '
              'water, or other system-level filter context.',
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
      'local mixed receipt does not auto-confirm salt pellets without softener context',
      () {
        final saltPelletsItem = matchReceiptLineToCatalog(
          'LOCAL SALT PELLETS 14.98',
          maxCandidates: 80,
        );
        expect(
          saltPelletsItem == null || saltPelletsItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a salt pellets '
              'line without softener, brine, or other water treatment '
              'context on the receipt line itself.',
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

    test(
      'local mixed receipt does not auto-confirm foil tape without hvac context',
      () {
        final foilTapeItem = matchReceiptLineToCatalog(
          'LOCAL FOIL TAPE 14.98',
          maxCandidates: 80,
        );
        expect(
          foilTapeItem == null || foilTapeItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a foil tape line '
              'without HVAC, duct, mastic, UL181, or other line-level duct '
              'system clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic vent shorthand',
      () {
        final ventItem = matchReceiptLineToCatalog(
          'LOCAL VENT 14.98',
          maxCandidates: 80,
        );
        expect(
          ventItem == null || ventItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare VENT '
              'line without line-level evidence such as roof, bath, dryer, '
              'flue, register, or other explicit vent clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic drain shorthand',
      () {
        final drainItem = matchReceiptLineToCatalog(
          'LOCAL DRAIN 14.98',
          maxCandidates: 80,
        );
        expect(
          drainItem == null || drainItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare DRAIN '
              'line without line-level evidence such as floor, tub, shower, '
              'condensate, or other explicit drain clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm bare fitting without trade context',
      () {
        final fittingItem = matchReceiptLineToCatalog(
          'LOCAL FITTING 14.98',
          maxCandidates: 80,
        );
        expect(
          fittingItem == null || fittingItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare FITTING '
              'line without material, fitting family, or other trade '
              'context on the receipt line itself.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm condensate drain without hvac context',
      () {
        final condensateDrainItem = matchReceiptLineToCatalog(
          'LOCAL CONDENSATE DRAIN 14.98',
          maxCandidates: 80,
        );
        expect(
          condensateDrainItem == null || condensateDrainItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a condensate drain '
              'line when the line still lacks trap, pan, pump, tubing, AC, '
              'or other HVAC system context.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic plug shorthand',
      () {
        final plugItem = matchReceiptLineToCatalog(
          'LOCAL PLUG 14.98',
          maxCandidates: 80,
        );
        expect(
          plugItem == null || plugItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare PLUG '
              'line without line-level evidence such as cleanout, test, '
              'cord, drain, or other explicit plug clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm sized plug without trade context',
      () {
        final sizedPlugItem = matchReceiptLineToCatalog(
          'LOCAL PLUG 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedPlugItem == null || sizedPlugItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized PLUG '
              'line when the receipt still lacks cleanout, test, drain, '
              'cord, brass, PVC, or other system-level plug clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic access shorthand',
      () {
        final accessItem = matchReceiptLineToCatalog(
          'LOCAL ACCESS 14.98',
          maxCandidates: 80,
        );
        expect(
          accessItem == null || accessItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare ACCESS '
              'line without line-level evidence such as panel, door, '
              'cleanout, or other explicit access clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic plate shorthand',
      () {
        final plateItem = matchReceiptLineToCatalog(
          'LOCAL PLATE 14.98',
          maxCandidates: 80,
        );
        expect(
          plateItem == null || plateItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare PLATE '
              'line without line-level evidence such as cover, nail, wall, '
              'stud, or other explicit plate clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic washer shorthand',
      () {
        final washerItem = matchReceiptLineToCatalog(
          'LOCAL WASHER 14.98',
          maxCandidates: 80,
        );
        expect(
          washerItem == null || washerItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare WASHER '
              'line without line-level evidence such as hose, trap, seat, '
              'fender, or other explicit washer clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm sized washer without trade context',
      () {
        final sizedWasherItem = matchReceiptLineToCatalog(
          'LOCAL WASHER 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedWasherItem == null || sizedWasherItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized WASHER '
              'line when the receipt still lacks beveled, slip joint, hose, '
              'faucet, bonding, or other explicit washer clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm bare white without trade context',
      () {
        final whiteItem = matchReceiptLineToCatalog(
          'LOCAL WHITE 14.98',
          maxCandidates: 80,
        );
        expect(
          whiteItem == null || whiteItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare WHITE '
              'line without PVC, wire, cover, caulk, paint, or other trade '
              'context on the receipt line itself.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic cleaner shorthand',
      () {
        final cleanerItem = matchReceiptLineToCatalog(
          'LOCAL CLEANER 14.98',
          maxCandidates: 80,
        );
        expect(
          cleanerItem == null || cleanerItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CLEANER '
              'line without line-level evidence such as coil, PVC, solvent, '
              'or other explicit cleaner clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic cement shorthand',
      () {
        final cementItem = matchReceiptLineToCatalog(
          'LOCAL CEMENT 14.98',
          maxCandidates: 80,
        );
        expect(
          cementItem == null || cementItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare CEMENT '
              'line without line-level evidence such as PVC, CPVC, solvent, '
              'or other explicit cement clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm pvc cement without trade context',
      () {
        final pvcCementItem = matchReceiptLineToCatalog(
          'LOCAL PVC CEMENT 14.98',
          maxCandidates: 80,
        );
        expect(
          pvcCementItem == null || pvcCementItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a PVC CEMENT '
              'line when the receipt still lacks plumbing, electrical, or '
              'HVAC system context for that adhesive.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic device shorthand',
      () {
        final deviceItem = matchReceiptLineToCatalog(
          'LOCAL DEVICE 14.98',
          maxCandidates: 80,
        );
        expect(
          deviceItem == null || deviceItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare DEVICE '
              'line without line-level evidence such as switch, outlet, '
              'cover, or other explicit device clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic register shorthand',
      () {
        final registerItem = matchReceiptLineToCatalog(
          'LOCAL REGISTER 14.98',
          maxCandidates: 80,
        );
        expect(
          registerItem == null || registerItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare REGISTER '
              'line without line-level evidence such as vent, grille, boot, '
              'or other explicit register clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic fixture shorthand',
      () {
        final fixtureItem = matchReceiptLineToCatalog(
          'LOCAL FIXTURE 14.98',
          maxCandidates: 80,
        );
        expect(
          fixtureItem == null || fixtureItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare FIXTURE '
              'line without line-level evidence such as faucet, light, '
              'heater, or other explicit fixture clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic meter shorthand',
      () {
        final meterItem = matchReceiptLineToCatalog(
          'LOCAL METER 14.98',
          maxCandidates: 80,
        );
        expect(
          meterItem == null || meterItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare METER '
              'line without line-level evidence such as clamp, gas, water, '
              'or other explicit meter clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm bare pvc without trade context',
      () {
        final pvcItem = matchReceiptLineToCatalog(
          'LOCAL PVC 14.98',
          maxCandidates: 80,
        );
        expect(
          pvcItem == null || pvcItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare PVC line '
              'without pipe, conduit, fitting, cement, drain, or other '
              'trade context on the receipt line itself.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm sized pvc without system context',
      () {
        final sizedPvcItem = matchReceiptLineToCatalog(
          'LOCAL PVC 3/4 14.98',
          maxCandidates: 80,
        );
        expect(
          sizedPvcItem == null || sizedPvcItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a sized PVC '
              'line when the receipt still lacks plumbing, electrical, or '
              'HVAC system-level context.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic hood shorthand',
      () {
        final hoodItem = matchReceiptLineToCatalog(
          'LOCAL HOOD 14.98',
          maxCandidates: 80,
        );
        expect(
          hoodItem == null || hoodItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare HOOD '
              'line without line-level evidence such as vent, range, bath, '
              'or other explicit hood clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic grille shorthand',
      () {
        final grilleItem = matchReceiptLineToCatalog(
          'LOCAL GRILLE 14.98',
          maxCandidates: 80,
        );
        expect(
          grilleItem == null || grilleItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare GRILLE '
              'line without line-level evidence such as return, supply, '
              'filter, or other explicit grille clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic boot shorthand',
      () {
        final bootItem = matchReceiptLineToCatalog(
          'LOCAL BOOT 14.98',
          maxCandidates: 80,
        );
        expect(
          bootItem == null || bootItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare BOOT '
              'line without line-level evidence such as register, vent, '
              'roof, or other explicit boot clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic damper shorthand',
      () {
        final damperItem = matchReceiptLineToCatalog(
          'LOCAL DAMPER 14.98',
          maxCandidates: 80,
        );
        expect(
          damperItem == null || damperItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare DAMPER '
              'line without line-level evidence such as vent, furnace, '
              'return, or other explicit damper clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic door shorthand',
      () {
        final doorItem = matchReceiptLineToCatalog(
          'LOCAL DOOR 14.98',
          maxCandidates: 80,
        );
        expect(
          doorItem == null || doorItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare DOOR '
              'line without line-level evidence such as access, attic, '
              'panel, or other explicit door clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic wall shorthand',
      () {
        final wallItem = matchReceiptLineToCatalog(
          'LOCAL WALL 14.98',
          maxCandidates: 80,
        );
        expect(
          wallItem == null || wallItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare WALL '
              'line without line-level evidence such as plate, switch, '
              'boot, or other explicit wall clues.',
        );
      },
    );

    test('local mixed receipt does not auto-confirm generic fan shorthand', () {
      final fanItem = matchReceiptLineToCatalog(
        'LOCAL FAN 14.98',
        maxCandidates: 80,
      );
      expect(
        fanItem == null || fanItem.confidence <= .81,
        isTrue,
        reason:
            'Local merchant flavor must not auto-confirm a bare FAN '
            'line without line-level evidence such as ceiling, bath, '
            'exhaust, or other explicit fan clues.',
      );
    });

    test(
      'local mixed receipt does not auto-confirm generic light shorthand',
      () {
        final lightItem = matchReceiptLineToCatalog(
          'LOCAL LIGHT 14.98',
          maxCandidates: 80,
        );
        expect(
          lightItem == null || lightItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare LIGHT '
              'line without line-level evidence such as fixture, LED, wall, '
              'or other explicit light clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic attic shorthand',
      () {
        final atticItem = matchReceiptLineToCatalog(
          'LOCAL ATTIC 14.98',
          maxCandidates: 80,
        );
        expect(
          atticItem == null || atticItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare ATTIC '
              'line without line-level evidence such as access, fan, '
              'ladder, or other explicit attic clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic floor shorthand',
      () {
        final floorItem = matchReceiptLineToCatalog(
          'LOCAL FLOOR 14.98',
          maxCandidates: 80,
        );
        expect(
          floorItem == null || floorItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare FLOOR '
              'line without line-level evidence such as drain, register, '
              'flange, or other explicit floor clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic roof shorthand',
      () {
        final roofItem = matchReceiptLineToCatalog(
          'LOCAL ROOF 14.98',
          maxCandidates: 80,
        );
        expect(
          roofItem == null || roofItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare ROOF '
              'line without line-level evidence such as vent, drain, boot, '
              'or other explicit roof clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic window shorthand',
      () {
        final windowItem = matchReceiptLineToCatalog(
          'LOCAL WINDOW 14.98',
          maxCandidates: 80,
        );
        expect(
          windowItem == null || windowItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare WINDOW '
              'line without line-level evidence such as seal, sash, '
              'screen, or other explicit window clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic stack shorthand',
      () {
        final stackItem = matchReceiptLineToCatalog(
          'LOCAL STACK 14.98',
          maxCandidates: 80,
        );
        expect(
          stackItem == null || stackItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare STACK '
              'line without line-level evidence such as roof, vent, soil, '
              'or other explicit stack clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic bath shorthand',
      () {
        final bathItem = matchReceiptLineToCatalog(
          'LOCAL BATH 14.98',
          maxCandidates: 80,
        );
        expect(
          bathItem == null || bathItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare BATH '
              'line without line-level evidence such as fan, drain, vent, '
              'or other explicit bath clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic kitchen shorthand',
      () {
        final kitchenItem = matchReceiptLineToCatalog(
          'LOCAL KITCHEN 14.98',
          maxCandidates: 80,
        );
        expect(
          kitchenItem == null || kitchenItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare KITCHEN '
              'line without line-level evidence such as faucet, sink, vent, '
              'or other explicit kitchen clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic sink shorthand',
      () {
        final sinkItem = matchReceiptLineToCatalog(
          'LOCAL SINK 14.98',
          maxCandidates: 80,
        );
        expect(
          sinkItem == null || sinkItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SINK '
              'line without line-level evidence such as drain, lav, tub, '
              'or other explicit sink clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic shower shorthand',
      () {
        final showerItem = matchReceiptLineToCatalog(
          'LOCAL SHOWER 14.98',
          maxCandidates: 80,
        );
        expect(
          showerItem == null || showerItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SHOWER '
              'line without line-level evidence such as drain, pan, valve, '
              'or other explicit shower clues.',
        );
      },
    );

    test('local mixed receipt does not auto-confirm generic tub shorthand', () {
      final tubItem = matchReceiptLineToCatalog(
        'LOCAL TUB 14.98',
        maxCandidates: 80,
      );
      expect(
        tubItem == null || tubItem.confidence <= .81,
        isTrue,
        reason:
            'Local merchant flavor must not auto-confirm a bare TUB '
            'line without line-level evidence such as drain, shower, bath, '
            'or other explicit tub clues.',
      );
    });

    test('local mixed receipt does not auto-confirm generic lav shorthand', () {
      final lavItem = matchReceiptLineToCatalog(
        'LOCAL LAV 14.98',
        maxCandidates: 80,
      );
      expect(
        lavItem == null || lavItem.confidence <= .81,
        isTrue,
        reason:
            'Local merchant flavor must not auto-confirm a bare LAV '
            'line without line-level evidence such as sink, faucet, drain, '
            'or other explicit lav clues.',
      );
    });

    test(
      'local mixed receipt does not auto-confirm generic frame shorthand',
      () {
        final frameItem = matchReceiptLineToCatalog(
          'LOCAL FRAME 14.98',
          maxCandidates: 80,
        );
        expect(
          frameItem == null || frameItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare FRAME '
              'line without line-level evidence such as window, screen, '
              'glass, or other explicit frame clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic screen shorthand',
      () {
        final screenItem = matchReceiptLineToCatalog(
          'LOCAL SCREEN 14.98',
          maxCandidates: 80,
        );
        expect(
          screenItem == null || screenItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SCREEN '
              'line without line-level evidence such as window, frame, '
              'mesh, or other explicit screen clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic head shorthand',
      () {
        final headItem = matchReceiptLineToCatalog(
          'LOCAL HEAD 14.98',
          maxCandidates: 80,
        );
        expect(
          headItem == null || headItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare HEAD '
              'line without line-level evidence such as shower, sprinkler, '
              'weatherhead, or other explicit head clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic base shorthand',
      () {
        final baseItem = matchReceiptLineToCatalog(
          'LOCAL BASE 14.98',
          maxCandidates: 80,
        );
        expect(
          baseItem == null || baseItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare BASE '
              'line without line-level evidence such as shower, fixture, '
              'mount, or other explicit base clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic glass shorthand',
      () {
        final glassItem = matchReceiptLineToCatalog(
          'LOCAL GLASS 14.98',
          maxCandidates: 80,
        );
        expect(
          glassItem == null || glassItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare GLASS '
              'line without line-level evidence such as pane, window, '
              'screen, or other explicit glass clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic pane shorthand',
      () {
        final paneItem = matchReceiptLineToCatalog(
          'LOCAL PANE 14.98',
          maxCandidates: 80,
        );
        expect(
          paneItem == null || paneItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare PANE '
              'line without line-level evidence such as glass, window, '
              'frame, or other explicit pane clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic sash shorthand',
      () {
        final sashItem = matchReceiptLineToCatalog(
          'LOCAL SASH 14.98',
          maxCandidates: 80,
        );
        expect(
          sashItem == null || sashItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SASH '
              'line without line-level evidence such as window, pane, '
              'screen, or other explicit sash clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic trim shorthand',
      () {
        final trimItem = matchReceiptLineToCatalog(
          'LOCAL TRIM 14.98',
          maxCandidates: 80,
        );
        expect(
          trimItem == null || trimItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare TRIM '
              'line without line-level evidence such as shower, faucet, '
              'window, or other explicit trim clues.',
        );
      },
    );

    test('local mixed receipt does not auto-confirm generic arm shorthand', () {
      final armItem = matchReceiptLineToCatalog(
        'LOCAL ARM 14.98',
        maxCandidates: 80,
      );
      expect(
        armItem == null || armItem.confidence <= .81,
        isTrue,
        reason:
            'Local merchant flavor must not auto-confirm a bare ARM '
            'line without line-level evidence such as shower, support, '
            'mount, or other explicit arm clues.',
      );
    });

    test(
      'local mixed receipt does not auto-confirm generic mount shorthand',
      () {
        final mountItem = matchReceiptLineToCatalog(
          'LOCAL MOUNT 14.98',
          maxCandidates: 80,
        );
        expect(
          mountItem == null || mountItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare MOUNT '
              'line without line-level evidence such as fixture, fan, '
              'bracket, or other explicit mount clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic mirror shorthand',
      () {
        final mirrorItem = matchReceiptLineToCatalog(
          'LOCAL MIRROR 14.98',
          maxCandidates: 80,
        );
        expect(
          mirrorItem == null || mirrorItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare MIRROR '
              'line without line-level evidence such as glass, frame, '
              'cabinet, or other explicit mirror clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic lens shorthand',
      () {
        final lensItem = matchReceiptLineToCatalog(
          'LOCAL LENS 14.98',
          maxCandidates: 80,
        );
        expect(
          lensItem == null || lensItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare LENS '
              'line without line-level evidence such as light, cover, '
              'fixture, or other explicit lens clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic shade shorthand',
      () {
        final shadeItem = matchReceiptLineToCatalog(
          'LOCAL SHADE 14.98',
          maxCandidates: 80,
        );
        expect(
          shadeItem == null || shadeItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SHADE '
              'line without line-level evidence such as lens, lamp, '
              'window, or other explicit shade clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm bare supply without system context',
      () {
        final supplyItem = matchReceiptLineToCatalog(
          'LOCAL SUPPLY 14.98',
          maxCandidates: 80,
        );
        expect(
          supplyItem == null || supplyItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SUPPLY '
              'line without line, hose, vent, register, toilet, faucet, '
              'or other system context on the receipt line itself.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic support shorthand',
      () {
        final supportItem = matchReceiptLineToCatalog(
          'LOCAL SUPPORT 14.98',
          maxCandidates: 80,
        );
        expect(
          supportItem == null || supportItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SUPPORT '
              'line without line-level evidence such as bracket, mount, '
              'fan, or other explicit support clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic primer shorthand',
      () {
        final primerItem = matchReceiptLineToCatalog(
          'LOCAL PRIMER 14.98',
          maxCandidates: 80,
        );
        expect(
          primerItem == null || primerItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare PRIMER '
              'line without line-level evidence such as PVC, CPVC, trap, '
              'purple, or other explicit primer clues.',
        );
      },
    );

    test(
      'local mixed receipt does not auto-confirm generic seal shorthand',
      () {
        final sealItem = matchReceiptLineToCatalog(
          'LOCAL SEAL 14.98',
          maxCandidates: 80,
        );
        expect(
          sealItem == null || sealItem.confidence <= .81,
          isTrue,
          reason:
              'Local merchant flavor must not auto-confirm a bare SEAL '
              'line without line-level evidence such as toilet, wax, tank, '
              'gasket, or other explicit seal clues.',
        );
      },
    );
  });
}
