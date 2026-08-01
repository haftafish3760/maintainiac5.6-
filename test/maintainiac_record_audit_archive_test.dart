import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/records/maintainiac_record_audit_archive.dart';

void main() {
  test('audit archive preserves ordered immutable evidence', () {
    final entries = MaintainiacRecordAuditArchive.entriesFor(
      recordModule: 'expenses',
      recordId: 'expense-1',
      auditEvents: const [
        '2026-08-01T00:00:00.000Z created record',
        '2026-08-01T00:01:00.000Z saved record',
      ],
    );

    expect(entries, hasLength(2));
    expect(entries.first.ordinal, 1);
    expect(entries.last.previousEntrySha256, entries.first.entrySha256);
    expect(MaintainiacRecordAuditArchive.hasValidChain(entries), isTrue);
  });

  test('audit archive detects duplicate or reordered ordinals', () {
    final entries = MaintainiacRecordAuditArchive.entriesFor(
      recordModule: 'expenses',
      recordId: 'expense-1',
      auditEvents: const ['one', 'two'],
    );
    final duplicateOrdinal = MaintainiacRecordAuditArchiveEntry(
      recordModule: 'expenses',
      recordId: 'expense-1',
      ordinal: 1,
      event: 'duplicate ordinal',
      previousEntrySha256: entries.first.entrySha256,
    );

    expect(
      MaintainiacRecordAuditArchive.hasValidChain([
        duplicateOrdinal,
        entries.first,
      ]),
      isFalse,
    );
  });
}
