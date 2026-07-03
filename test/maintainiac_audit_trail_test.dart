import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('audit trail probe validates ordered complete audit events', () {
    const probe = MaintainiacAuditTrailProbe();
    final events = [
      MaintainiacAuditEvent(
        id: 'audit_1',
        actorId: 'user_1',
        action: 'expense_created',
        targetType: 'expense',
        targetId: 'expense_1',
        timestamp: DateTime.utc(2026, 7, 3, 10),
      ),
      MaintainiacAuditEvent(
        id: 'audit_2',
        actorId: 'user_1',
        action: 'expense_synced',
        targetType: 'expense',
        targetId: 'expense_1',
        timestamp: DateTime.utc(2026, 7, 3, 10, 1),
      ),
    ];

    expect(probe.validate(events), isEmpty);
  });

  test('audit trail probe proves user confirmation outranks suggestions', () {
    const probe = MaintainiacAuditTrailProbe();
    final event = probe.userConfirmedSuggestion(
      id: 'audit_confirm_1',
      actorId: 'user_1',
      targetType: 'receipt_line',
      targetId: 'line_1',
      timestamp: DateTime.utc(2026, 7, 3, 10),
      suggestion: const {'category': 'materials', 'reviewStatus': 'suggested'},
      confirmed: const {'category': 'fuel', 'reviewStatus': 'confirmed'},
    );

    expect(probe.validate([event]), isEmpty);
    expect(probe.provesUserConfirmation(event), isTrue);
    expect(event.toJson().toString(), contains('user_confirmed_suggestion'));
  });

  test(
    'audit trail probe rejects duplicate incomplete or unordered events',
    () {
      const probe = MaintainiacAuditTrailProbe();
      final failures = probe.validate([
        MaintainiacAuditEvent(
          id: 'audit_1',
          actorId: '',
          action: '',
          targetType: 'expense',
          targetId: 'expense_1',
          timestamp: DateTime.utc(2026, 7, 3, 10),
        ),
        MaintainiacAuditEvent(
          id: 'audit_1',
          actorId: 'user_1',
          action: 'late_event',
          targetType: '',
          targetId: '',
          timestamp: DateTime.utc(2026, 7, 3, 9),
        ),
      ]);

      expect(failures, contains('duplicate audit id audit_1'));
      expect(failures, contains('audit_1 missing actor'));
      expect(failures, contains('audit_1 missing action'));
      expect(failures, contains('audit_1 missing target type'));
      expect(failures, contains('audit_1 missing target id'));
      expect(failures, contains('audit_1 timestamp out of order'));
    },
  );
}
