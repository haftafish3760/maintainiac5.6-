import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';

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
    expect(
      store.activeSession?.events.single.type,
      ActiveWorkdayEventType.started,
    );

    final restored = await ActiveWorkdayController.create();
    expect(restored.activeSession?.vehicleLabel, 'Work Truck 1');
    expect(restored.activeSession?.startedAt, startedAt);
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
}
