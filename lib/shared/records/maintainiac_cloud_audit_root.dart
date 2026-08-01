import 'maintainiac_audit_chain.dart';

/// Bounded audit state stored on a cloud record root.
///
/// The complete readable audit history remains local and is protected in the
/// immutable cloud archive. This projection prevents root documents from
/// growing with every edit while retaining enough evidence to detect an
/// incomplete archive before a record is treated as recoverable.
class MaintainiacCloudAuditRoot {
  factory MaintainiacCloudAuditRoot.fromEvents(
    Iterable<String> events, {
    int maximumRecentEvents = defaultMaximumRecentEvents,
  }) {
    if (maximumRecentEvents < 0 ||
        maximumRecentEvents > defaultMaximumRecentEvents) {
      throw ArgumentError.value(maximumRecentEvents, 'maximumRecentEvents');
    }
    final values = List<String>.unmodifiable(events);
    final state = MaintainiacAuditChain.fromEvents(values);
    final start = (values.length - maximumRecentEvents).clamp(0, values.length);
    return MaintainiacCloudAuditRoot(
      eventCount: state.eventCount,
      chainSha256: state.chainSha256,
      recentEvents: List.unmodifiable(values.sublist(start)),
    );
  }

  factory MaintainiacCloudAuditRoot.fromMap(Map<dynamic, dynamic> map) {
    final eventCount = map['auditEventCount'];
    final chainSha256 = map['auditChainSha256'];
    final recentEvents = map['auditRecentEvents'];
    if (eventCount is! int ||
        eventCount < 0 ||
        chainSha256 is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(chainSha256) ||
        recentEvents is! List ||
        recentEvents.length > defaultMaximumRecentEvents ||
        recentEvents.any((event) => event is! String)) {
      throw const FormatException('Cloud audit root is invalid.');
    }
    return MaintainiacCloudAuditRoot(
      eventCount: eventCount,
      chainSha256: chainSha256,
      recentEvents: List.unmodifiable(recentEvents.cast<String>()),
    );
  }

  const MaintainiacCloudAuditRoot({
    required this.eventCount,
    required this.chainSha256,
    required this.recentEvents,
  }) : assert(eventCount >= 0),
       assert(recentEvents.length <= defaultMaximumRecentEvents);

  static const defaultMaximumRecentEvents = 24;

  final int eventCount;
  final String chainSha256;
  final List<String> recentEvents;

  Map<String, Object> toMap() => {
    'auditEventCount': eventCount,
    'auditChainSha256': chainSha256,
    'auditRecentEvents': recentEvents,
  };

  /// Validates archive evidence before reconstructing it during restore.
  bool verifies(Iterable<String> completeEvents) {
    final events = List<String>.of(completeEvents);
    if (!MaintainiacAuditChain.verifies(
      events: events,
      expectedCount: eventCount,
      expectedSha256: chainSha256,
    )) {
      return false;
    }
    final start = (events.length - recentEvents.length).clamp(0, events.length);
    return _equal(events.sublist(start), recentEvents);
  }

  static bool _equal(List<String> left, List<String> right) =>
      left.length == right.length &&
      left.indexed.every((entry) => entry.$2 == right[entry.$1]);
}
