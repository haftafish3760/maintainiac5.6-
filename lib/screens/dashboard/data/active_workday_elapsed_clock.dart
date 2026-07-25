import 'active_workday_store.dart';

/// Keeps the visible workday duration monotonic while this process is alive.
///
/// Wall time is used only to establish a baseline for a newly observed durable
/// workday. Later ticks use elapsed monotonic time, so a device-clock rollback,
/// time-zone change, or daylight-saving transition cannot make the dashboard
/// timer move backward or add artificial work time.
class ActiveWorkdayElapsedClock {
  ActiveWorkdayElapsedClock({required Duration Function() monotonicNow})
    : _monotonicNow = monotonicNow;

  factory ActiveWorkdayElapsedClock.runtime() {
    final stopwatch = Stopwatch()..start();
    return ActiveWorkdayElapsedClock(monotonicNow: () => stopwatch.elapsed);
  }

  final Duration Function() _monotonicNow;

  String? _sessionId;
  String? _sessionFingerprint;
  Duration _baseline = Duration.zero;
  Duration _anchor = Duration.zero;
  bool _running = true;
  bool _initialized = false;

  Duration elapsedFor(
    ActiveWorkdaySessionRecord? session, {
    required DateTime wallNow,
  }) {
    final monotonic = _safeMonotonic(_monotonicNow());
    final sessionId = session?.id;
    final fingerprint = _fingerprint(session);

    if (!_initialized || sessionId != _sessionId) {
      _initialized = true;
      _sessionId = sessionId;
      _sessionFingerprint = fingerprint;
      _baseline = session?.elapsedWorkTimeAt(wallNow) ?? Duration.zero;
      _anchor = monotonic;
      _running = session == null || _shouldRun(session);
      return _baseline;
    }

    if (fingerprint != _sessionFingerprint) {
      _baseline = _current(monotonic);
      _anchor = monotonic;
      _sessionFingerprint = fingerprint;
      _running = session == null || _shouldRun(session);
    }

    return _current(monotonic);
  }

  Duration _current(Duration monotonic) {
    if (!_running) return _baseline;
    final delta = monotonic - _anchor;
    if (delta.isNegative) return _baseline;
    final elapsed = _baseline + delta;
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  bool _shouldRun(ActiveWorkdaySessionRecord session) =>
      session.isActive && !session.isPaused;

  String _fingerprint(ActiveWorkdaySessionRecord? session) {
    if (session == null) return 'no-session';
    final lastEvent = session.events.isEmpty ? null : session.events.last;
    return [
      session.id,
      session.status.name,
      session.events.length,
      lastEvent?.id ?? '',
      lastEvent?.type.name ?? '',
      session.endedAt?.toUtc().toIso8601String() ?? '',
    ].join('|');
  }
}

Duration _safeMonotonic(Duration value) {
  if (value.isNegative) return Duration.zero;
  return value;
}
