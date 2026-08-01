import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Immutable, portable audit evidence for one durable record lifecycle event.
///
/// Archive entries are deliberately separate from a record snapshot: a record
/// can retain a compact recent-event summary while the complete audit trail is
/// persisted and transferred in bounded pages. The chain hash makes omission,
/// reordering, or replacement detectable without exposing business payloads.
class MaintainiacRecordAuditArchiveEntry {
  MaintainiacRecordAuditArchiveEntry({
    required this.recordModule,
    required this.recordId,
    required this.ordinal,
    required this.event,
    required this.previousEntrySha256,
  }) {
    _token(recordModule, 'recordModule', maximumLength: 80);
    _token(recordId, 'recordId', maximumLength: 160);
    if (ordinal < 1) throw ArgumentError.value(ordinal, 'ordinal');
    if (event.trim().isEmpty || event.length > 512) {
      throw ArgumentError.value(event, 'event');
    }
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(previousEntrySha256)) {
      throw ArgumentError.value(previousEntrySha256, 'previousEntrySha256');
    }
  }

  static const String genesisSha256 =
      '0000000000000000000000000000000000000000000000000000000000000000';

  final String recordModule;
  final String recordId;
  final int ordinal;
  final String event;
  final String previousEntrySha256;

  factory MaintainiacRecordAuditArchiveEntry.fromMap(
    Map<dynamic, dynamic> map,
  ) {
    if (map['schema'] != 'maintainiac_record_audit_archive_entry_v1' ||
        map['recordModule'] is! String ||
        map['recordId'] is! String ||
        map['ordinal'] is! int ||
        map['event'] is! String ||
        map['previousEntrySha256'] is! String) {
      throw const FormatException('Audit archive entry is corrupt.');
    }
    try {
      final entry = MaintainiacRecordAuditArchiveEntry(
        recordModule: map['recordModule'] as String,
        recordId: map['recordId'] as String,
        ordinal: map['ordinal'] as int,
        event: map['event'] as String,
        previousEntrySha256: map['previousEntrySha256'] as String,
      );
      if (map['recordKey'] != entry.recordKey) {
        throw const FormatException('Audit archive identity is corrupt.');
      }
      return entry;
    } on ArgumentError {
      throw const FormatException('Audit archive entry is corrupt.');
    }
  }

  String get recordKey => recordKeyFor(recordModule, recordId);
  String get archiveId => _sha256('$recordKey\u0000$ordinal');
  String get entrySha256 => _sha256(jsonEncode(toMap()));

  Map<String, Object> toMap() => {
    'schema': 'maintainiac_record_audit_archive_entry_v1',
    'recordKey': recordKey,
    'recordModule': recordModule,
    'recordId': recordId,
    'ordinal': ordinal,
    'event': event,
    'previousEntrySha256': previousEntrySha256,
  };

  static String _sha256(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  static String recordKeyFor(String module, String id) {
    _token(module, 'module', maximumLength: 80);
    _token(id, 'id', maximumLength: 160);
    return _sha256('$module\u0000$id');
  }

  static void _token(String value, String name, {required int maximumLength}) {
    if (!RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(value) ||
        value.length > maximumLength) {
      throw ArgumentError.value(value, name);
    }
  }
}

/// Builds a deterministic append-only archive from an ordered audit trail.
class MaintainiacRecordAuditArchive {
  const MaintainiacRecordAuditArchive._();

  static List<MaintainiacRecordAuditArchiveEntry> entriesFor({
    required String recordModule,
    required String recordId,
    required List<String> auditEvents,
  }) {
    var priorHash = MaintainiacRecordAuditArchiveEntry.genesisSha256;
    final entries = <MaintainiacRecordAuditArchiveEntry>[];
    for (var index = 0; index < auditEvents.length; index += 1) {
      final entry = MaintainiacRecordAuditArchiveEntry(
        recordModule: recordModule,
        recordId: recordId,
        ordinal: index + 1,
        event: auditEvents[index],
        previousEntrySha256: priorHash,
      );
      entries.add(entry);
      priorHash = entry.entrySha256;
    }
    return List.unmodifiable(entries);
  }

  static bool hasValidChain(
    Iterable<MaintainiacRecordAuditArchiveEntry> entries,
  ) {
    final ordered = entries.toList()
      ..sort((left, right) => left.ordinal.compareTo(right.ordinal));
    if (ordered.isEmpty) return true;
    final first = ordered.first;
    var expectedOrdinal = 1;
    var priorHash = MaintainiacRecordAuditArchiveEntry.genesisSha256;
    for (final entry in ordered) {
      if (entry.recordModule != first.recordModule ||
          entry.recordId != first.recordId ||
          entry.ordinal != expectedOrdinal ||
          entry.previousEntrySha256 != priorHash) {
        return false;
      }
      priorHash = entry.entrySha256;
      expectedOrdinal += 1;
    }
    return true;
  }
}
