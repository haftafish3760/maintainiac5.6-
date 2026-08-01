import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Compact, append-only integrity state for audit evidence stored separately
/// from a durable record's cloud root document.
///
/// Local records keep their complete readable audit list. A cloud root can
/// instead carry this state while immutable event documents hold the evidence.
/// The chain makes a missing, reordered, or changed event detectable without
/// allowing an unbounded event list to consume the root document's size limit.
class MaintainiacAuditChain {
  const MaintainiacAuditChain._();

  static const schema = 'maintainiac_audit_chain_v1';

  static final emptySha256 = _hash({'schema': schema, 'kind': 'empty'});

  static MaintainiacAuditChainState fromEvents(Iterable<String> events) {
    var state = MaintainiacAuditChainState.empty();
    for (final event in events) {
      state = state.append(event);
    }
    return state;
  }

  static String eventSha256({
    required String previousSha256,
    required int ordinal,
    required String event,
  }) {
    if (!_sha256(previousSha256) || ordinal < 1 || !_event(event)) {
      throw ArgumentError('Audit event chain input is invalid.');
    }
    return _hash({
      'schema': schema,
      'previousSha256': previousSha256,
      'ordinal': ordinal,
      'event': event,
    });
  }

  static bool verifies({
    required Iterable<String> events,
    required int expectedCount,
    required String expectedSha256,
  }) {
    if (expectedCount < 0 || !_sha256(expectedSha256)) return false;
    try {
      final actual = fromEvents(events);
      return actual.eventCount == expectedCount &&
          actual.chainSha256 == expectedSha256;
    } on ArgumentError {
      return false;
    }
  }

  static String _hash(Map<String, Object> value) =>
      sha256.convert(utf8.encode(jsonEncode(_canonical(value)))).toString();

  static Object? _canonical(Object? value) {
    if (value is List) {
      return value.map(_canonical).toList(growable: false);
    }
    if (value is Map) {
      final keys = value.keys.toList();
      if (keys.any((key) => key is! String)) {
        throw const FormatException('Audit chain key is invalid.');
      }
      final sorted = keys.cast<String>()..sort();
      return {for (final key in sorted) key: _canonical(value[key])};
    }
    return value;
  }

  static bool _sha256(String value) =>
      RegExp(r'^[a-f0-9]{64}$').hasMatch(value);

  static bool _event(String value) =>
      value.trim().isNotEmpty && value.length <= 512;
}

/// The only cloud-root audit fields required to verify an immutable archive.
class MaintainiacAuditChainState {
  const MaintainiacAuditChainState({
    required this.eventCount,
    required this.chainSha256,
  }) : assert(eventCount >= 0);

  factory MaintainiacAuditChainState.empty() => MaintainiacAuditChainState(
    eventCount: 0,
    chainSha256: MaintainiacAuditChain.emptySha256,
  );

  final int eventCount;
  final String chainSha256;

  MaintainiacAuditChainState append(String event) => MaintainiacAuditChainState(
    eventCount: eventCount + 1,
    chainSha256: MaintainiacAuditChain.eventSha256(
      previousSha256: chainSha256,
      ordinal: eventCount + 1,
      event: event,
    ),
  );

  MaintainiacAuditChainState appendAll(Iterable<String> events) {
    var next = this;
    for (final event in events) {
      next = next.append(event);
    }
    return next;
  }
}
