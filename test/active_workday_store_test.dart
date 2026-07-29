import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'active_workday_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('starts and restores the active workday session from Hive', () async {
    final store = await ActiveWorkdayController.create();
    final startedAt = DateTime(2026, 6, 12, 8, 30);

    await store.startDay(
      vehicleId: 'truck-1',
      vehicleLabel: 'Work Truck 1',
      workProfileId: 'Business',
      startOdometer: 125000,
      startedAt: startedAt,
    );

    expect(store.activeSession?.vehicleId, 'truck-1');
    expect(store.activeSession?.startOdometer, 125000);
    expect(store.activeSession?.resolvedContextSegments, hasLength(1));
    expect(
      store.activeSession?.resolvedContextSegments.single.vehicleId,
      'truck-1',
    );
    expect(
      store.activeSession?.events.single.type,
      ActiveWorkdayEventType.started,
    );

    final restored = await ActiveWorkdayController.create();
    expect(restored.activeSession?.vehicleLabel, 'Work Truck 1');
    expect(restored.activeSession?.startedAt, startedAt);
    expect(
      restored.activeSession?.resolvedContextSegments.single.workProfileId,
      'Business',
    );
  });

  test('starting an active workday twice keeps the original session', () async {
    final store = ActiveWorkdayController.memory();
    final first = await store.startDay(
      vehicleId: 'truck-1',
      vehicleLabel: 'Work Truck 1',
      workProfileId: 'Business',
      startOdometer: 125000,
      startedAt: DateTime(2026, 6, 12, 8, 30),
    );
    final second = await store.startDay(
      vehicleId: 'truck-2',
      vehicleLabel: 'Work Truck 2',
      workProfileId: 'Side Work',
      startOdometer: 500,
      startedAt: DateTime(2026, 6, 12, 9),
    );

    expect(second.id, first.id);
    expect(store.sessions, hasLength(1));
    expect(store.activeSession?.vehicleId, 'truck-1');
  });

  test('does not claim a workday started when storage is full', () async {
    final store = ActiveWorkdayController.memory(
      storageCheck: () async => const AppStorageCheck(
        availableBytes: 0,
        operationBytes: AppStorageGuard.smallRecordWriteBytes,
        requiredBytes: AppStorageGuard.smallRecordWriteBytes,
        purpose: AppStoragePurpose.smallRecordWrite,
      ),
    );

    await expectLater(
      store.startDay(
        vehicleId: 'truck-1',
        vehicleLabel: 'Work Truck 1',
        workProfileId: 'Business',
        startOdometer: 125000,
      ),
      throwsStateError,
    );
    expect(store.activeSession, isNull);
  });

  test('starting a workday rejects negative odometers before persistence', () {
    final store = ActiveWorkdayController.memory();

    expect(
      () => store.startDay(
        vehicleId: 'truck-1',
        vehicleLabel: 'Work Truck 1',
        workProfileId: 'Business',
        startOdometer: -1,
      ),
      throwsArgumentError,
    );

    expect(store.activeSession, isNull);
  });

  test('starting a workday rejects future start timestamps', () async {
    final store = ActiveWorkdayController.memory();

    await expectLater(
      store.startDay(
        vehicleId: 'truck-1',
        vehicleLabel: 'Work Truck 1',
        workProfileId: 'Business',
        startOdometer: 1000,
        startedAt: DateTime.now().add(const Duration(days: 1)),
      ),
      throwsArgumentError,
    );

    expect(store.activeSession, isNull);
  });

  test('unsafe active workday ids are not used as durable lookup keys', () {
    final store = ActiveWorkdayController.memory();

    expect(store.sessionById(' workday_bad '), isNull);
    expect(store.sessionById('workday_\nbad'), isNull);
    expect(store.sessionById('workday_${'x' * 200}'), isNull);
  });

  test('unsafe persisted active workday identities are not restored', () async {
    final box = await Hive.openBox<dynamic>(ActiveWorkdayController.boxName);
    await box.put(ActiveWorkdayController.activeSessionKey, 'workday_bad');
    await box.put('workday_bad', {
      'id': 'workday_bad',
      'vehicleId': 'truck_\n1',
      'vehicleLabel': 'Work Truck 1',
      'workProfileId': 'Business',
      'startedAt': DateTime(2026, 6, 12, 8).toIso8601String(),
      'startOdometer': 125000,
      'status': 'active',
      'events': [
        {
          'id': 'event_1',
          'type': 'started',
          'occurredAt': DateTime(2026, 6, 12, 8).toIso8601String(),
          'odometerReading': 125000,
          'label': 'Workday started',
        },
      ],
    });
    await box.put('workday_bad_event', {
      'id': 'workday_bad_event',
      'vehicleId': 'truck-1',
      'vehicleLabel': 'Work Truck 1',
      'workProfileId': 'Business',
      'startedAt': DateTime(2026, 6, 12, 9).toIso8601String(),
      'startOdometer': 125010,
      'status': 'active',
      'events': [
        {
          'id': 'event_\nbad',
          'type': 'started',
          'occurredAt': DateTime(2026, 6, 12, 9).toIso8601String(),
          'odometerReading': 125010,
          'label': 'Workday started',
        },
      ],
    });

    final store = await ActiveWorkdayController.create();

    expect(store.activeSession, isNull);
    expect(store.sessionById('workday_bad'), isNull);
    expect(store.sessionById('workday_bad_event'), isNull);
    expect(store.sessions, isEmpty);
  });

  test('malformed active workday pointer is ignored', () async {
    final box = await Hive.openBox<dynamic>(ActiveWorkdayController.boxName);
    await box.put(ActiveWorkdayController.activeSessionKey, {'bad': 'shape'});

    final store = await ActiveWorkdayController.create();

    expect(store.activeSession, isNull);
  });

  test(
    'records pause, stop, fuel, and end events with odometer readings',
    () async {
      final store = ActiveWorkdayController.memory();

      await store.startDay(
        vehicleId: 'truck-1',
        vehicleLabel: 'Work Truck 1',
        workProfileId: 'Business',
        startOdometer: 1000,
        startedAt: DateTime(2026, 6, 12, 7),
      );
      await store.addEvent(
        type: ActiveWorkdayEventType.paused,
        odometerReading: 1015,
        occurredAt: DateTime(2026, 6, 12, 10),
      );
      await store.addEvent(
        type: ActiveWorkdayEventType.stop,
        odometerReading: 1020,
        note: 'Customer stop',
        occurredAt: DateTime(2026, 6, 12, 11),
      );
      await store.addEvent(
        type: ActiveWorkdayEventType.fuel,
        odometerReading: 1028,
        occurredAt: DateTime(2026, 6, 12, 12),
      );
      final ended = await store.addEvent(
        type: ActiveWorkdayEventType.ended,
        odometerReading: 1042,
        occurredAt: DateTime(2026, 6, 12, 16),
      );

      expect(ended?.status, ActiveWorkdayStatus.ended);
      expect(ended?.endOdometer, 1042);
      expect(ended?.milesSoFar(1042), 42);
      expect(ended?.events.map((event) => event.type), [
        ActiveWorkdayEventType.started,
        ActiveWorkdayEventType.paused,
        ActiveWorkdayEventType.stop,
        ActiveWorkdayEventType.fuel,
        ActiveWorkdayEventType.ended,
      ]);
      expect(store.activeSession, isNull);
    },
  );

  test(
    'active workday writes require safe vehicle and work profile ids',
    () async {
      final store = ActiveWorkdayController.memory();

      await expectLater(
        store.startDay(
          vehicleId: 'vehicle\nunsafe',
          vehicleLabel: 'Work Truck',
          workProfileId: 'business',
          startOdometer: 1000,
        ),
        throwsArgumentError,
      );
      await expectLater(
        store.startDay(
          vehicleId: 'vehicle_1',
          vehicleLabel: 'Work Truck',
          workProfileId: ' business ',
          startOdometer: 1000,
        ),
        throwsArgumentError,
      );

      expect(store.activeSession, isNull);
    },
  );

  test(
    'ending an active workday cannot persist a decreasing odometer',
    () async {
      final decreasingStore = ActiveWorkdayController.memory();
      await decreasingStore.startDay(
        vehicleId: 'vehicle_1',
        vehicleLabel: 'Work Truck',
        workProfileId: 'business',
        startOdometer: 1000,
      );

      await expectLater(
        decreasingStore.addEvent(
          type: ActiveWorkdayEventType.ended,
          odometerReading: 999,
        ),
        throwsArgumentError,
      );

      expect(decreasingStore.activeSession?.status, ActiveWorkdayStatus.active);
      expect(decreasingStore.activeSession?.endOdometer, isNull);
      expect(decreasingStore.activeSession?.events.map((event) => event.type), [
        ActiveWorkdayEventType.started,
      ]);
    },
  );

  test(
    'active workday events cannot persist below the starting odometer',
    () async {
      final store = ActiveWorkdayController.memory();
      await store.startDay(
        vehicleId: 'vehicle_1',
        vehicleLabel: 'Work Truck',
        workProfileId: 'business',
        startOdometer: 1000,
      );

      await expectLater(
        store.addEvent(type: ActiveWorkdayEventType.stop, odometerReading: 999),
        throwsArgumentError,
      );

      expect(store.activeSession?.status, ActiveWorkdayStatus.active);
      expect(store.activeSession?.events.map((event) => event.type), [
        ActiveWorkdayEventType.started,
      ]);
    },
  );

  test('active workday events cannot move the odometer backward', () async {
    final store = ActiveWorkdayController.memory();
    await store.startDay(
      vehicleId: 'vehicle_1',
      vehicleLabel: 'Work Truck',
      workProfileId: 'business',
      startOdometer: 1000,
    );
    await store.addEvent(
      type: ActiveWorkdayEventType.stop,
      odometerReading: 1050,
    );

    await expectLater(
      store.addEvent(
        type: ActiveWorkdayEventType.dropOff,
        odometerReading: 1049,
      ),
      throwsArgumentError,
    );

    expect(store.activeSession?.events.map((event) => event.type), [
      ActiveWorkdayEventType.started,
      ActiveWorkdayEventType.stop,
    ]);
  });

  test('active workday import references must be safe tokens', () async {
    final store = ActiveWorkdayController.memory();
    await store.startDay(
      vehicleId: 'vehicle_1',
      vehicleLabel: 'Work Truck',
      workProfileId: 'business',
      startOdometer: 1000,
    );

    await expectLater(
      store.addEvent(
        type: ActiveWorkdayEventType.expense,
        odometerReading: 1001,
        sourceType: 'expense\nentry',
        sourceId: 'expense_1',
      ),
      throwsArgumentError,
    );
    await expectLater(
      store.addEvent(
        type: ActiveWorkdayEventType.expense,
        odometerReading: 1001,
        sourceType: 'expense',
        sourceId: ' receipt/path ',
      ),
      throwsArgumentError,
    );

    expect(store.activeSession?.events.map((event) => event.type), [
      ActiveWorkdayEventType.started,
    ]);
  });

  test(
    'active workday events cannot persist before the day start time',
    () async {
      final store = ActiveWorkdayController.memory();
      final startedAt = DateTime(2026, 6, 12, 8);
      await store.startDay(
        vehicleId: 'vehicle_1',
        vehicleLabel: 'Work Truck',
        workProfileId: 'business',
        startOdometer: 1000,
        startedAt: startedAt,
      );

      await expectLater(
        store.addEvent(
          type: ActiveWorkdayEventType.stop,
          odometerReading: 1001,
          occurredAt: startedAt.subtract(const Duration(minutes: 1)),
        ),
        throwsArgumentError,
      );

      expect(store.activeSession?.status, ActiveWorkdayStatus.active);
      expect(store.activeSession?.events.map((event) => event.type), [
        ActiveWorkdayEventType.started,
      ]);
    },
  );

  test('active workday events cannot persist future timestamps', () async {
    final store = ActiveWorkdayController.memory();
    await store.startDay(
      vehicleId: 'vehicle_1',
      vehicleLabel: 'Work Truck',
      workProfileId: 'business',
      startOdometer: 1000,
    );

    await expectLater(
      store.addEvent(
        type: ActiveWorkdayEventType.stop,
        odometerReading: 1001,
        occurredAt: DateTime.now().add(const Duration(days: 1)),
      ),
      throwsArgumentError,
    );

    expect(store.activeSession?.events.map((event) => event.type), [
      ActiveWorkdayEventType.started,
    ]);
  });

  test(
    'resuming a paused day restores the active local session state',
    () async {
      final store = ActiveWorkdayController.memory();
      final startedAt = DateTime(2026, 6, 12, 7);

      await store.startDay(
        vehicleId: 'truck-1',
        vehicleLabel: 'Work Truck 1',
        workProfileId: 'Business',
        startOdometer: 1000,
        startedAt: startedAt,
      );
      await store.addEvent(
        type: ActiveWorkdayEventType.paused,
        odometerReading: 1015,
        occurredAt: DateTime(2026, 6, 12, 10),
      );
      final resumed = await store.addEvent(
        type: ActiveWorkdayEventType.resumed,
        odometerReading: 1015,
        occurredAt: DateTime(2026, 6, 12, 11),
      );

      expect(resumed?.status, ActiveWorkdayStatus.active);
      expect(store.activeSession?.status, ActiveWorkdayStatus.active);
      expect(store.activeSession?.isPaused, isFalse);
      expect(
        store.activeSession?.elapsedWorkTimeAt(DateTime(2026, 6, 12, 12)),
        const Duration(hours: 4),
      );
      expect(store.activeSession?.events.map((event) => event.type), [
        ActiveWorkdayEventType.started,
        ActiveWorkdayEventType.paused,
        ActiveWorkdayEventType.resumed,
      ]);
    },
  );

  test(
    'a currently paused workday does not advance its elapsed work timer',
    () {
      final record = ActiveWorkdaySessionRecord(
        id: 'workday-paused',
        vehicleId: 'truck-1',
        vehicleLabel: 'Work Truck 1',
        workProfileId: 'Business',
        startedAt: DateTime(2026, 6, 12, 7),
        startOdometer: 1000,
        status: ActiveWorkdayStatus.paused,
        events: [
          ActiveWorkdayEvent(
            id: 'paused',
            type: ActiveWorkdayEventType.paused,
            occurredAt: DateTime(2026, 6, 12, 10),
            odometerReading: 1015,
            label: 'Day paused',
          ),
        ],
      );

      expect(
        record.elapsedWorkTimeAt(DateTime(2026, 6, 12, 12)),
        const Duration(hours: 3),
      );
      expect(record.isPaused, isTrue);
    },
  );

  test(
    'serializes and reloads a session record without losing event details',
    () {
      final record = ActiveWorkdaySessionRecord(
        id: 'workday-1',
        vehicleId: 'truck-1',
        vehicleLabel: 'Work Truck 1',
        workProfileId: 'Business',
        startedAt: DateTime(2026, 6, 12, 8),
        startOdometer: 2000,
        status: ActiveWorkdayStatus.active,
        events: [
          ActiveWorkdayEvent(
            id: 'event-1',
            type: ActiveWorkdayEventType.stop,
            occurredAt: DateTime(2026, 6, 12, 9, 15),
            odometerReading: 2012,
            label: 'Stop logged',
            note: 'Warehouse',
          ),
        ],
      );

      final restored = ActiveWorkdaySessionRecord.fromMap(record.toMap());

      expect(restored.vehicleId, record.vehicleId);
      expect(restored.events.single.type, ActiveWorkdayEventType.stop);
      expect(restored.events.single.note, 'Warehouse');
      expect(restored.events.single.timeLabel, '9:15 AM');
    },
  );

  test('malformed active workday odometers recover safely', () {
    final restored = ActiveWorkdaySessionRecord.fromMap({
      'id': 'malformed-workday-odometer',
      'vehicleId': 'truck-1',
      'vehicleLabel': 'Work Truck 1',
      'workProfileId': 'Business',
      'startedAt': DateTime(2026, 6, 12, 8).toIso8601String(),
      'startOdometer': double.nan,
      'status': 'ended',
      'endOdometer': double.negativeInfinity,
      'events': [
        {
          'id': 'bad-odometer-event',
          'type': 'stop',
          'occurredAt': DateTime(2026, 6, 12, 9).toIso8601String(),
          'odometerReading': -10,
          'label': 'Stop logged',
        },
      ],
    });

    expect(restored.startOdometer, 0);
    expect(restored.status, ActiveWorkdayStatus.active);
    expect(restored.endOdometer, isNull);
    expect(restored.events.single.odometerReading, 0);
    expect(restored.milesSoFar(12), 12);
  });

  test('ended active workdays require coherent persisted end state', () {
    final startedAt = DateTime(2026, 6, 12, 8);
    final restored = ActiveWorkdaySessionRecord.fromMap({
      'id': 'incomplete-ended-workday',
      'vehicleId': 'truck-1',
      'vehicleLabel': 'Work Truck 1',
      'workProfileId': 'Business',
      'startedAt': startedAt.toIso8601String(),
      'startOdometer': 1000,
      'status': 'ended',
      'endOdometer': 1040,
      'events': [
        {
          'id': 'started-event',
          'type': 'started',
          'occurredAt': startedAt.toIso8601String(),
          'odometerReading': 1000,
          'label': 'Day started',
        },
      ],
    });

    expect(restored.status, ActiveWorkdayStatus.active);
    expect(restored.endedAt, isNull);
    expect(restored.endOdometer, isNull);
  });

  test('ended active workdays reject events after end state', () {
    final startedAt = DateTime(2026, 6, 12, 8);
    final endedAt = DateTime(2026, 6, 12, 17);
    for (final poisonedEvent in [
      {
        'id': 'after-ended-time',
        'type': 'note',
        'occurredAt': endedAt.add(const Duration(minutes: 1)).toIso8601String(),
        'odometerReading': 1040,
        'label': 'Late note',
      },
      {
        'id': 'after-ended-odometer',
        'type': 'note',
        'occurredAt': endedAt.toIso8601String(),
        'odometerReading': 1041,
        'label': 'Late odometer',
      },
    ]) {
      final restored = ActiveWorkdaySessionRecord.fromMap({
        'id': 'poisoned-ended-workday',
        'vehicleId': 'truck-1',
        'vehicleLabel': 'Work Truck 1',
        'workProfileId': 'Business',
        'startedAt': startedAt.toIso8601String(),
        'startOdometer': 1000,
        'status': 'ended',
        'endedAt': endedAt.toIso8601String(),
        'endOdometer': 1040,
        'events': [
          {
            'id': 'ended-event',
            'type': 'ended',
            'occurredAt': endedAt.toIso8601String(),
            'odometerReading': 1040,
            'label': 'Day ended',
          },
          poisonedEvent,
        ],
      });

      expect(restored.status, ActiveWorkdayStatus.active);
      expect(restored.endedAt, isNull);
      expect(restored.endOdometer, isNull);
    }
  });

  test('malformed active workday timestamps do not become current time', () {
    final restored = ActiveWorkdaySessionRecord.fromMap({
      'id': 'malformed-workday-time',
      'vehicleId': 'truck-1',
      'vehicleLabel': 'Work Truck 1',
      'workProfileId': 'Business',
      'startedAt': 'not-a-date',
      'startOdometer': 1200,
      'status': 'active',
      'events': [
        {
          'id': 'bad-time-event',
          'type': 'stop',
          'occurredAt': 'also-bad',
          'odometerReading': 1201,
          'label': 'Stop logged',
        },
      ],
    });

    final fallback = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    expect(restored.startedAt, fallback);
    expect(restored.events.single.occurredAt, fallback);
  });

  test('restored active workday events cannot predate start or odometer', () {
    final startedAt = DateTime(2026, 6, 12, 8);
    final restored = ActiveWorkdaySessionRecord.fromMap({
      'id': 'filtered-workday-events',
      'vehicleId': 'truck-1',
      'vehicleLabel': 'Work Truck 1',
      'workProfileId': 'Business',
      'startedAt': startedAt.toIso8601String(),
      'startOdometer': 1200,
      'status': 'active',
      'events': [
        {
          'id': 'pre-start-event',
          'type': 'stop',
          'occurredAt': startedAt
              .subtract(const Duration(minutes: 1))
              .toIso8601String(),
          'odometerReading': 1200,
          'label': 'Stop logged',
        },
        {
          'id': 'below-start-odometer',
          'type': 'stop',
          'occurredAt': startedAt
              .add(const Duration(minutes: 1))
              .toIso8601String(),
          'odometerReading': 1199,
          'label': 'Stop logged',
        },
        {
          'id': 'valid-event',
          'type': 'stop',
          'occurredAt': startedAt
              .add(const Duration(minutes: 2))
              .toIso8601String(),
          'odometerReading': 1201,
          'label': 'Stop logged',
        },
        {
          'id': 'decreasing-event',
          'type': 'dropOff',
          'occurredAt': startedAt
              .add(const Duration(minutes: 3))
              .toIso8601String(),
          'odometerReading': 1200,
          'label': 'Drop-off logged',
        },
      ],
    });

    expect(restored.events, hasLength(1));
    expect(restored.events.single.id, 'valid-event');
  });

  test('restored active workday events are sorted before odometer checks', () {
    final startedAt = DateTime(2026, 6, 12, 8);
    final restored = ActiveWorkdaySessionRecord.fromMap({
      'id': 'out-of-order-workday-events',
      'vehicleId': 'truck-1',
      'vehicleLabel': 'Work Truck 1',
      'workProfileId': 'Business',
      'startedAt': startedAt.toIso8601String(),
      'startOdometer': 1200,
      'status': 'active',
      'events': [
        {
          'id': 'later-event',
          'type': 'dropOff',
          'occurredAt': startedAt
              .add(const Duration(minutes: 10))
              .toIso8601String(),
          'odometerReading': 1205,
          'label': 'Drop-off logged',
        },
        {
          'id': 'earlier-event',
          'type': 'pickup',
          'occurredAt': startedAt
              .add(const Duration(minutes: 5))
              .toIso8601String(),
          'odometerReading': 1202,
          'label': 'Pickup logged',
        },
      ],
    });

    expect(restored.events.map((event) => event.id), [
      'earlier-event',
      'later-event',
    ]);
  });

  test('non-string active workday restore fields fail closed', () {
    final restored = ActiveWorkdaySessionRecord.fromMap({
      'id': 'malformed-workday-shape',
      'vehicleId': 'truck-1',
      'vehicleLabel': 'Work Truck 1',
      'workProfileId': 'Business',
      'startedAt': 12345,
      'startOdometer': 1200,
      'status': {'bad': 'shape'},
      'endedAt': 67890,
      'events': [
        {
          'id': 'bad-shape-event',
          'type': 42,
          'occurredAt': ['not', 'a', 'date'],
          'odometerReading': 1201,
          'label': 'Stop logged',
        },
      ],
    });

    final fallback = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    expect(restored.startedAt, fallback);
    expect(restored.status, ActiveWorkdayStatus.active);
    expect(restored.endedAt, isNull);
    expect(restored.hasValidIdentity, isFalse);
    expect(restored.events.single.type, ActiveWorkdayEventType.note);
    expect(restored.events.single.hasValidIdentity, isFalse);
    expect(restored.events.single.occurredAt, fallback);
  });

  test('unknown active workday enum values fail closed on restore', () {
    final restored = ActiveWorkdaySessionRecord.fromMap({
      'id': 'unknown-enum-workday',
      'vehicleId': 'truck-1',
      'vehicleLabel': 'Work Truck 1',
      'workProfileId': 'Business',
      'startedAt': DateTime(2026, 6, 12, 8).toIso8601String(),
      'startOdometer': 1200,
      'status': 'ghostMode',
      'events': [
        {
          'id': 'unknown-enum-event',
          'type': 'teleport',
          'occurredAt': DateTime(2026, 6, 12, 9).toIso8601String(),
          'odometerReading': 1201,
          'label': 'Unknown event',
        },
      ],
    });

    expect(restored.status, ActiveWorkdayStatus.active);
    expect(restored.hasValidIdentity, isFalse);
    expect(restored.events.single.type, ActiveWorkdayEventType.note);
    expect(restored.events.single.hasValidIdentity, isFalse);
  });

  test('restored active workday events require explicit safe event ids', () {
    final restored = ActiveWorkdaySessionRecord.fromMap({
      'id': 'missing-event-id-workday',
      'vehicleId': 'truck-1',
      'vehicleLabel': 'Work Truck 1',
      'workProfileId': 'Business',
      'startedAt': DateTime(2026, 6, 12, 8).toIso8601String(),
      'startOdometer': 1200,
      'status': 'active',
      'events': [
        {
          'type': 'stop',
          'occurredAt': DateTime(2026, 6, 12, 9).toIso8601String(),
          'odometerReading': 1201,
          'label': 'Stop logged',
        },
      ],
    });

    expect(restored.hasValidIdentity, isFalse);
    expect(restored.events.single.hasValidIdentity, isFalse);
  });

  test('restored active workday import references must be safe tokens', () {
    for (final event in [
      {
        'id': 'unsafe-source-type',
        'type': 'expense',
        'occurredAt': DateTime(2026, 6, 12, 9).toIso8601String(),
        'odometerReading': 1201,
        'label': 'Expense opened',
        'sourceType': 'expense\nentry',
        'sourceId': 'expense_1',
      },
      {
        'id': 'unsafe-source-id',
        'type': 'expense',
        'occurredAt': DateTime(2026, 6, 12, 9).toIso8601String(),
        'odometerReading': 1201,
        'label': 'Expense opened',
        'sourceType': 'expense',
        'sourceId': 'expense/../other',
      },
    ]) {
      final restored = ActiveWorkdaySessionRecord.fromMap({
        'id': 'unsafe-import-reference-workday',
        'vehicleId': 'truck-1',
        'vehicleLabel': 'Work Truck 1',
        'workProfileId': 'Business',
        'startedAt': DateTime(2026, 6, 12, 8).toIso8601String(),
        'startOdometer': 1200,
        'status': 'active',
        'events': [event],
      });

      expect(restored.hasValidIdentity, isFalse);
      expect(restored.events.single.hasValidIdentity, isFalse);
    }
  });

  test('active workday serialization never writes negative odometers', () {
    final record = ActiveWorkdaySessionRecord(
      id: 'negative-workday-odometer',
      vehicleId: 'truck-1',
      vehicleLabel: 'Work Truck 1',
      workProfileId: 'Business',
      startedAt: DateTime(2026, 6, 12, 8),
      startOdometer: -120,
      status: ActiveWorkdayStatus.ended,
      events: [
        ActiveWorkdayEvent(
          id: 'negative-event-odometer',
          type: ActiveWorkdayEventType.stop,
          occurredAt: DateTime(2026, 6, 12, 9),
          odometerReading: -3,
          label: 'Stop logged',
        ),
      ],
      endOdometer: -10,
    );

    final map = record.toMap();
    final events = map['events'] as List<Object?>;
    final event = events.single as Map<String, Object?>;

    expect(map['startOdometer'], 0);
    expect(map['endOdometer'], 0);
    expect(event['odometerReading'], 0);
  });

  test('active workday serialization bounds display text fields', () {
    final record = ActiveWorkdaySessionRecord(
      id: ' ${'w' * 240} ',
      vehicleId: ' ${'v' * 240} ',
      vehicleLabel: ' ${'Truck' * 40} ',
      workProfileId: ' ${'p' * 240} ',
      startedAt: DateTime(2026, 6, 12, 8),
      startOdometer: 1200,
      status: ActiveWorkdayStatus.active,
      events: [
        ActiveWorkdayEvent(
          id: 'event-text',
          type: ActiveWorkdayEventType.note,
          occurredAt: DateTime(2026, 6, 12, 9),
          odometerReading: 1201,
          label: ' ${'Label' * 40} ',
          note: 'first line\n${'n' * 300}',
          sourceType: ' ${'s' * 120} ',
          sourceId: ' ${'id' * 120} ',
        ),
      ],
    );

    final map = record.toMap();
    final event =
        (map['events'] as List<Object?>).single as Map<String, Object?>;

    expect((map['id'] as String), hasLength(160));
    expect((map['vehicleId'] as String), hasLength(160));
    expect((map['vehicleLabel'] as String), hasLength(120));
    expect((map['workProfileId'] as String), hasLength(160));
    expect((event['label'] as String), hasLength(80));
    expect((event['note'] as String), hasLength(240));
    expect(event['note'], isNot(contains('\n')));
    expect((event['sourceType'] as String), hasLength(80));
    expect((event['sourceId'] as String), hasLength(160));
  });
}
