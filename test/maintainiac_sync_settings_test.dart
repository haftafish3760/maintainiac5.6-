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
      final store = await MaintainiacSyncSettingsStore.create('sync_settings');
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
      final reopened = await MaintainiacSyncSettingsStore.create(
        'sync_settings',
      );
      expect(reopened.settingsFor('expenses').toMap(), settings.toMap());
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
