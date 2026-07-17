class LiveOdometerDisplaySnapshot {
  const LiveOdometerDisplaySnapshot({
    required this.confirmedReading,
    required this.displayReading,
    required this.isLive,
    this.liveUpdatedAt,
  });

  final int confirmedReading;
  final int displayReading;
  final bool isLive;
  final DateTime? liveUpdatedAt;

  int get deltaMiles {
    final delta = displayReading - confirmedReading;
    return isLive && delta > 0 ? delta : 0;
  }

  String get label => isLive ? 'Live GPS odometer' : 'Odometer';

  String get displayValue =>
      _safeReading(displayReading).toString().padLeft(7, '0');

  String? get deltaLabel => isLive ? '+$deltaMiles mi live' : null;

  bool isStaleAt(
    DateTime now, {
    Duration staleAfter = const Duration(minutes: 5),
  }) {
    final updatedAt = liveUpdatedAt;
    if (!isLive || updatedAt == null) return false;
    if (staleAfter <= Duration.zero) return false;
    return now.toUtc().difference(updatedAt.toUtc()) > staleAfter;
  }

  String? statusLabelAt(DateTime now) {
    if (!isLive) return null;
    if (isStaleAt(now)) return 'Live GPS paused';
    return deltaLabel;
  }

  Map<String, Object?> toSafeDashboardMap(DateTime now) => {
    'label': label,
    'displayValue': displayValue,
    'isLive': isLive,
    'deltaMiles': deltaMiles,
    'statusLabel': statusLabelAt(now),
    'freshness': isStaleAt(now) ? 'stale' : 'fresh',
  };
}

int _safeReading(int value) => value < 0 ? 0 : value;
