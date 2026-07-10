class MaintainiacAuditEvent {
  const MaintainiacAuditEvent({
    required this.id,
    required this.actorId,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.timestamp,
    this.before = const {},
    this.after = const {},
    this.reason = '',
  });

  final String id;
  final String actorId;
  final String action;
  final String targetType;
  final String targetId;
  final DateTime timestamp;
  final Map<String, Object?> before;
  final Map<String, Object?> after;
  final String reason;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'actorId': actorId,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'timestamp': timestamp.toIso8601String(),
      if (before.isNotEmpty) 'before': before,
      if (after.isNotEmpty) 'after': after,
      if (reason.isNotEmpty) 'reason': reason,
    };
  }
}

class MaintainiacAuditTrailProbe {
  const MaintainiacAuditTrailProbe();

  List<String> validate(Iterable<MaintainiacAuditEvent> events) {
    final failures = <String>[];
    final ids = <String>{};
    DateTime? previous;
    for (final event in events) {
      if (!ids.add(event.id)) {
        failures.add('duplicate audit id ${event.id}');
      }
      if (event.actorId.trim().isEmpty) {
        failures.add('${event.id} missing actor');
      }
      if (event.action.trim().isEmpty) {
        failures.add('${event.id} missing action');
      }
      if (event.targetType.trim().isEmpty) {
        failures.add('${event.id} missing target type');
      }
      if (event.targetId.trim().isEmpty) {
        failures.add('${event.id} missing target id');
      }
      if (previous != null && event.timestamp.isBefore(previous)) {
        failures.add('${event.id} timestamp out of order');
      }
      previous = event.timestamp;
    }
    return failures;
  }

  MaintainiacAuditEvent userConfirmedSuggestion({
    required String id,
    required String actorId,
    required String targetType,
    required String targetId,
    required DateTime timestamp,
    required Map<String, Object?> suggestion,
    required Map<String, Object?> confirmed,
  }) {
    return MaintainiacAuditEvent(
      id: id,
      actorId: actorId,
      action: 'user_confirmed_suggestion',
      targetType: targetType,
      targetId: targetId,
      timestamp: timestamp,
      before: suggestion,
      after: confirmed,
      reason: 'User-confirmed data outranks parser automation.',
    );
  }

  bool provesUserConfirmation(MaintainiacAuditEvent event) {
    return event.action == 'user_confirmed_suggestion' &&
        event.before.isNotEmpty &&
        event.after.isNotEmpty &&
        event.reason.contains('outranks');
  }
}
