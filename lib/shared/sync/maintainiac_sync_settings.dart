enum MaintainiacSyncMode {
  disabled,
  manualOnly,
  scheduled,
  automaticProtection,
}

enum MaintainiacSyncTransport { wifiOnly, wifiAndCellular }

enum MaintainiacSyncNetwork { unavailable, wifi, cellular, unknown }

enum MaintainiacSyncTrigger { manual, scheduled, importantEvent, background }

enum MaintainiacSyncDecision {
  allowed,
  disabled,
  manualOnly,
  waitingForSchedule,
  waitingForNetwork,
  roamingBlocked,
  batterySaverPaused,
  planDisallowsImmediate,
}

class MaintainiacSyncSettings {
  MaintainiacSyncSettings({
    required this.mode,
    required this.transport,
    required Iterable<int> localTimesMinutesAfterMidnight,
    required this.allowRoaming,
    required this.pauseOnBatterySaver,
  }) : localTimesMinutesAfterMidnight = List.unmodifiable(
         _normalizeTimes(localTimesMinutesAfterMidnight),
       );

  factory MaintainiacSyncSettings.fromMap(Map<dynamic, dynamic> map) {
    final mode = MaintainiacSyncMode.values.where(
      (value) => value.name == map['mode'],
    );
    final transport = MaintainiacSyncTransport.values.where(
      (value) => value.name == map['transport'],
    );
    final times = map['localTimesMinutesAfterMidnight'];
    final allowRoaming = map['allowRoaming'];
    final pauseOnBatterySaver = map['pauseOnBatterySaver'];
    if (mode.length != 1 ||
        transport.length != 1 ||
        times is! List ||
        !times.every((value) => value is int) ||
        allowRoaming is! bool ||
        pauseOnBatterySaver is! bool) {
      throw const FormatException('Sync settings are corrupt.');
    }
    final settings = MaintainiacSyncSettings(
      mode: mode.single,
      transport: transport.single,
      localTimesMinutesAfterMidnight: times.cast<int>(),
      allowRoaming: allowRoaming,
      pauseOnBatterySaver: pauseOnBatterySaver,
    );
    if (settings.localTimesMinutesAfterMidnight.length != times.length) {
      throw const FormatException('Sync schedule contains invalid times.');
    }
    return settings;
  }

  factory MaintainiacSyncSettings.disabled() => MaintainiacSyncSettings(
    mode: MaintainiacSyncMode.disabled,
    transport: MaintainiacSyncTransport.wifiOnly,
    localTimesMinutesAfterMidnight: const [],
    allowRoaming: false,
    pauseOnBatterySaver: true,
  );

  final MaintainiacSyncMode mode;
  final MaintainiacSyncTransport transport;
  final List<int> localTimesMinutesAfterMidnight;
  final bool allowRoaming;
  final bool pauseOnBatterySaver;

  bool get hasSchedule => localTimesMinutesAfterMidnight.isNotEmpty;

  DateTime? nextScheduledAtOrAfter(DateTime localNow) {
    if (!hasSchedule) return null;
    for (final minutes in localTimesMinutesAfterMidnight) {
      final candidate = DateTime(
        localNow.year,
        localNow.month,
        localNow.day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (!candidate.isBefore(localNow)) return candidate;
    }
    final first = localTimesMinutesAfterMidnight.first;
    return DateTime(
      localNow.year,
      localNow.month,
      localNow.day + 1,
      first ~/ 60,
      first % 60,
    );
  }

  bool isScheduledDue({
    required DateTime localNow,
    required DateTime referenceLocal,
  }) {
    if (!hasSchedule) return false;
    final next = _nextScheduledAfter(referenceLocal);
    return next != null && !next.isAfter(localNow);
  }

  MaintainiacSyncDecision decide({
    required MaintainiacSyncTrigger trigger,
    required MaintainiacSyncNetwork network,
    required bool isRoaming,
    required bool batterySaverEnabled,
    required bool immediateSyncAllowed,
    required DateTime localNow,
    DateTime? lastAttemptLocal,
    DateTime? authorizationBeganLocal,
  }) {
    if (mode == MaintainiacSyncMode.disabled) {
      return MaintainiacSyncDecision.disabled;
    }
    if (mode == MaintainiacSyncMode.manualOnly &&
        trigger != MaintainiacSyncTrigger.manual) {
      return MaintainiacSyncDecision.manualOnly;
    }
    if (trigger == MaintainiacSyncTrigger.scheduled) {
      final reference = lastAttemptLocal ?? authorizationBeganLocal;
      if (mode == MaintainiacSyncMode.manualOnly ||
          reference == null ||
          !isScheduledDue(localNow: localNow, referenceLocal: reference)) {
        return MaintainiacSyncDecision.waitingForSchedule;
      }
    }
    if ((trigger == MaintainiacSyncTrigger.importantEvent ||
            trigger == MaintainiacSyncTrigger.background) &&
        (mode != MaintainiacSyncMode.automaticProtection ||
            !immediateSyncAllowed)) {
      return MaintainiacSyncDecision.planDisallowsImmediate;
    }
    if (isRoaming && !allowRoaming) {
      return MaintainiacSyncDecision.roamingBlocked;
    }
    if (batterySaverEnabled &&
        pauseOnBatterySaver &&
        trigger != MaintainiacSyncTrigger.manual) {
      return MaintainiacSyncDecision.batterySaverPaused;
    }
    final networkAllowed = switch (network) {
      MaintainiacSyncNetwork.wifi => true,
      MaintainiacSyncNetwork.cellular =>
        transport == MaintainiacSyncTransport.wifiAndCellular,
      MaintainiacSyncNetwork.unavailable ||
      MaintainiacSyncNetwork.unknown => false,
    };
    return networkAllowed
        ? MaintainiacSyncDecision.allowed
        : MaintainiacSyncDecision.waitingForNetwork;
  }

  Map<String, Object?> toMap() => {
    'mode': mode.name,
    'transport': transport.name,
    'localTimesMinutesAfterMidnight': localTimesMinutesAfterMidnight,
    'allowRoaming': allowRoaming,
    'pauseOnBatterySaver': pauseOnBatterySaver,
  };

  DateTime? _nextScheduledAfter(DateTime reference) {
    for (final minutes in localTimesMinutesAfterMidnight) {
      final candidate = DateTime(
        reference.year,
        reference.month,
        reference.day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (candidate.isAfter(reference)) return candidate;
    }
    if (!hasSchedule) return null;
    final first = localTimesMinutesAfterMidnight.first;
    return DateTime(
      reference.year,
      reference.month,
      reference.day + 1,
      first ~/ 60,
      first % 60,
    );
  }
}

List<int> _normalizeTimes(Iterable<int> values) {
  final times = values.where((value) => value >= 0 && value < 24 * 60).toSet();
  if (times.length > 24) {
    throw const FormatException(
      'A sync schedule may contain at most 24 times.',
    );
  }
  return times.toList()..sort();
}
