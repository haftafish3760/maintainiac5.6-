import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sync_settings_test_');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  test('backup defaults to disabled and cannot use any network implicitly', () {
    final settings = MaintainiacSyncSettings.disabled();
    for (final network in MaintainiacSyncNetwork.values) {
      expect(
        settings.decide(
          trigger: MaintainiacSyncTrigger.background,
          network: network,
          isRoaming: false,
          batterySaverEnabled: false,
          immediateSyncAllowed: true,
          localNow: DateTime(2026, 7, 22, 12),
        ),
        MaintainiacSyncDecision.disabled,
      );
    }
  });

  test('manual-only permits explicit sync and blocks background attempts', () {
    final settings = MaintainiacSyncSettings(
      mode: MaintainiacSyncMode.manualOnly,
      transport: MaintainiacSyncTransport.wifiAndCellular,
      localTimesMinutesAfterMidnight: const [],
      allowRoaming: false,
      pauseOnBatterySaver: true,
    );
    expect(
      _decide(
        settings,
        trigger: MaintainiacSyncTrigger.manual,
        network: MaintainiacSyncNetwork.cellular,
        batterySaverEnabled: true,
      ),
      MaintainiacSyncDecision.allowed,
    );
    expect(
      _decide(
        settings,
        trigger: MaintainiacSyncTrigger.background,
        network: MaintainiacSyncNetwork.cellular,
      ),
      MaintainiacSyncDecision.manualOnly,
    );
  });

  test(
    'selected local times normalize and become due without extra attempts',
    () {
      final settings = MaintainiacSyncSettings(
        mode: MaintainiacSyncMode.scheduled,
        transport: MaintainiacSyncTransport.wifiOnly,
        localTimesMinutesAfterMidnight: const [18 * 60, 8 * 60, 8 * 60],
        allowRoaming: false,
        pauseOnBatterySaver: true,
      );
      expect(settings.localTimesMinutesAfterMidnight, [480, 1080]);
      expect(
        settings.nextScheduledAtOrAfter(DateTime(2026, 7, 22, 9)),
        DateTime(2026, 7, 22, 18),
      );
      expect(
        settings.isScheduledDue(
          localNow: DateTime(2026, 7, 22, 18),
          referenceLocal: DateTime(2026, 7, 22, 8),
        ),
        isTrue,
      );
    },
  );

  test('invalid local sync times are rejected instead of dropped', () {
    expect(
      () => MaintainiacSyncSettings(
        mode: MaintainiacSyncMode.scheduled,
        transport: MaintainiacSyncTransport.wifiOnly,
        localTimesMinutesAfterMidnight: const [480, 24 * 60],
        allowRoaming: false,
        pauseOnBatterySaver: true,
      ),
      throwsFormatException,
    );
  });

  test('unknown network, roaming, and battery saver all fail closed', () {
    final settings = MaintainiacSyncSettings(
      mode: MaintainiacSyncMode.automaticProtection,
      transport: MaintainiacSyncTransport.wifiAndCellular,
      localTimesMinutesAfterMidnight: const [480],
      allowRoaming: false,
      pauseOnBatterySaver: true,
    );
    expect(
      _decide(settings, network: MaintainiacSyncNetwork.unknown),
      MaintainiacSyncDecision.waitingForNetwork,
    );
    expect(
      _decide(
        settings,
        network: MaintainiacSyncNetwork.cellular,
        isRoaming: true,
      ),
      MaintainiacSyncDecision.roamingBlocked,
    );
    expect(
      _decide(
        settings,
        network: MaintainiacSyncNetwork.wifi,
        batterySaverEnabled: true,
      ),
      MaintainiacSyncDecision.batterySaverPaused,
    );
    expect(
      _decide(
        settings,
        network: MaintainiacSyncNetwork.wifi,
        immediateSyncAllowed: false,
      ),
      MaintainiacSyncDecision.planDisallowsImmediate,
    );
  });

  test(
    'module-specific settings save immediately and survive Hive restart',
    () async {
      final store = await MaintainiacSyncSettingsStore.create();
      final settings = MaintainiacSyncSettings(
        mode: MaintainiacSyncMode.scheduled,
        transport: MaintainiacSyncTransport.wifiOnly,
        localTimesMinutesAfterMidnight: const [420, 720, 1020, 1320],
        allowRoaming: false,
        pauseOnBatterySaver: true,
      );
      await store.save('expenses', settings);
      expect(store.settingsFor('dashboard').mode, MaintainiacSyncMode.disabled);
      await Hive.close();
      Hive.init(directory.path);
      final reopened = await MaintainiacSyncSettingsStore.create();
      expect(reopened.settingsFor('expenses').toMap(), settings.toMap());
      expect(reopened.snapshotFor('expenses').revision, 1);
    },
  );

  test(
    'failed local settings write preserves the previously saved policy',
    () async {
      var allow = true;
      final store = MaintainiacSyncSettingsStore.memory(
        storageCheck: () async => AppStorageCheck(
          availableBytes: allow ? 100 : 0,
          operationBytes: 1,
          requiredBytes: 1,
          purpose: AppStoragePurpose.smallRecordWrite,
        ),
      );
      final original = MaintainiacSyncSettings.disabled();
      await store.save('expenses', original);
      allow = false;
      await expectLater(
        store.save(
          'expenses',
          MaintainiacSyncSettings(
            mode: MaintainiacSyncMode.automaticProtection,
            transport: MaintainiacSyncTransport.wifiAndCellular,
            localTimesMinutesAfterMidnight: const [60],
            allowRoaming: true,
            pauseOnBatterySaver: false,
          ),
        ),
        throwsStateError,
      );
      expect(store.settingsFor('expenses').mode, MaintainiacSyncMode.disabled);
    },
  );

  test('legacy sync settings remain readable and migrate on save', () async {
    final box = await Hive.openBox<dynamic>(
      MaintainiacSyncSettingsStore.boxName,
    );
    final legacy = MaintainiacSyncSettings(
      mode: MaintainiacSyncMode.manualOnly,
      transport: MaintainiacSyncTransport.wifiOnly,
      localTimesMinutesAfterMidnight: const [],
      allowRoaming: false,
      pauseOnBatterySaver: true,
    );
    await box.put('expenses', legacy.toMap());
    final store = await MaintainiacSyncSettingsStore.create();
    expect(store.settingsFor('expenses').toMap(), legacy.toMap());
    expect(store.snapshotFor('expenses').revision, 0);
    await store.save('expenses', legacy);
    expect(store.snapshotFor('expenses').revision, 1);
  });

  test('corrupt sync settings fail closed to disabled', () async {
    final box = await Hive.openBox<dynamic>(
      MaintainiacSyncSettingsStore.boxName,
    );
    await box.put('expenses', {'settings': 'invalid', 'revision': 9});
    final store = await MaintainiacSyncSettingsStore.create();
    expect(store.settingsFor('expenses').mode, MaintainiacSyncMode.disabled);
  });

  test('sync checkpoint survives restart and recovers interruption', () async {
    final store = await MaintainiacSyncCheckpointStore.create();
    final started = await store.begin(
      module: 'expenses',
      attemptId: 'attempt-1',
      trigger: MaintainiacSyncTrigger.scheduled,
      nowUtc: DateTime.utc(2026, 7, 22, 12),
    );
    expect(started.state, MaintainiacSyncAttemptState.running);
    await expectLater(
      store.begin(
        module: 'expenses',
        attemptId: 'attempt-2',
        trigger: MaintainiacSyncTrigger.scheduled,
      ),
      throwsStateError,
    );

    await Hive.close();
    Hive.init(directory.path);
    final reopened = await MaintainiacSyncCheckpointStore.create();
    expect(reopened.checkpointFor('expenses').activeAttemptId, 'attempt-1');
    final recovered = await reopened.recoverInterrupted(
      'expenses',
      nowUtc: DateTime.utc(2026, 7, 22, 12, 1),
    );
    expect(recovered.state, MaintainiacSyncAttemptState.failed);
    expect(recovered.lastError, contains('interrupted'));
    expect(recovered.revision, 2);
  });

  test('checkpoint keeps last success across a later failed attempt', () async {
    final store = MaintainiacSyncCheckpointStore.memory();
    await store.begin(
      module: 'expenses',
      attemptId: 'attempt-1',
      trigger: MaintainiacSyncTrigger.manual,
      nowUtc: DateTime.utc(2026, 7, 22, 12),
    );
    final success = await store.finish(
      module: 'expenses',
      attemptId: 'attempt-1',
      state: MaintainiacSyncAttemptState.succeeded,
      reservationId: 'reservation-1',
      nowUtc: DateTime.utc(2026, 7, 22, 12, 1),
    );
    await store.begin(
      module: 'expenses',
      attemptId: 'attempt-2',
      trigger: MaintainiacSyncTrigger.background,
      nowUtc: DateTime.utc(2026, 7, 22, 12, 2),
    );
    final failed = await store.finish(
      module: 'expenses',
      attemptId: 'attempt-2',
      state: MaintainiacSyncAttemptState.failed,
      error: 'Network unavailable.',
      nowUtc: DateTime.utc(2026, 7, 22, 12, 3),
    );
    expect(failed.lastSuccessfulAtUtc, success.lastSuccessfulAtUtc);
    expect(failed.lastError, 'Network unavailable.');
    expect(failed.reservationId, isNull);
  });

  test(
    'checkpoint repositories sharing a Hive box reject overlapping attempts',
    () async {
      final firstEntered = Completer<void>();
      final releaseFirst = Completer<void>();
      var secondEntered = false;
      final first = await MaintainiacSyncCheckpointStore.create(
        storageCheck: () async {
          firstEntered.complete();
          await releaseFirst.future;
          return _healthyStorage;
        },
      );
      final second = await MaintainiacSyncCheckpointStore.create(
        storageCheck: () async {
          secondEntered = true;
          return _healthyStorage;
        },
      );

      final firstBegin = first.begin(
        module: 'expenses',
        attemptId: 'attempt-a',
        trigger: MaintainiacSyncTrigger.manual,
      );
      await firstEntered.future;
      final secondBegin = second.begin(
        module: 'expenses',
        attemptId: 'attempt-b',
        trigger: MaintainiacSyncTrigger.manual,
      );
      await Future<void>.delayed(Duration.zero);

      expect(secondEntered, isFalse);
      releaseFirst.complete();
      expect((await firstBegin).activeAttemptId, 'attempt-a');
      await expectLater(secondBegin, throwsStateError);
      expect(second.checkpointFor('expenses').activeAttemptId, 'attempt-a');
    },
  );

  test(
    'corrupt checkpoint blocks sync instead of repeating an upload',
    () async {
      final box = await Hive.openBox<dynamic>(
        MaintainiacSyncCheckpointStore.boxName,
      );
      await box.put('expenses', {'state': 'running'});
      final store = await MaintainiacSyncCheckpointStore.create();
      expect(() => store.checkpointFor('expenses'), throwsStateError);
    },
  );
}

MaintainiacSyncDecision _decide(
  MaintainiacSyncSettings settings, {
  MaintainiacSyncTrigger trigger = MaintainiacSyncTrigger.background,
  MaintainiacSyncNetwork network = MaintainiacSyncNetwork.wifi,
  bool isRoaming = false,
  bool batterySaverEnabled = false,
  bool immediateSyncAllowed = true,
}) => settings.decide(
  trigger: trigger,
  network: network,
  isRoaming: isRoaming,
  batterySaverEnabled: batterySaverEnabled,
  immediateSyncAllowed: immediateSyncAllowed,
  localNow: DateTime(2026, 7, 22, 12),
);

const _healthyStorage = AppStorageCheck(
  availableBytes: 1024 * 1024 * 1024,
  operationBytes: 1,
  requiredBytes: 1,
  purpose: AppStoragePurpose.smallRecordWrite,
);
