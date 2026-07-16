import '../../../shared/widgets/receipt_capture/receipt_capture_models.dart';
import '../../../shared/records/maintainiac_record_lifecycle.dart';
import '../../../shared/state/app_state.dart';
import 'expense_ledger_models.dart';
import 'expense_reminder_store.dart';
import 'expense_work_profile_store.dart';

/// Converts trusted Expense backup metadata into local record candidates.
///
/// This is deliberately network-free and does not write to Hive. A restore
/// coordinator must review available storage and merge policy before persisting
/// a decoded record. Cloud proof pointers remain separate because metadata
/// restore must never pretend a proof file is already on this device.
class ExpenseCloudRestoreCodec {
  const ExpenseCloudRestoreCodec._();

  static ExpenseCloudRestoredReceipt decodeReceipt(Map<dynamic, dynamic> data) {
    if ('${data['schema']}'.trim() != 'expense_receipt_backup_v1') {
      throw const FormatException('Unsupported Expense receipt backup schema.');
    }
    final id = _text(data['id']);
    if (id.isEmpty) {
      throw const FormatException('Expense receipt backup is missing its ID.');
    }
    final receiptDate = _date(data['receiptDate']);
    if (receiptDate == null) {
      throw const FormatException(
        'Expense receipt backup is missing its receipt date.',
      );
    }
    final createdAt = _date(data['createdAt']);
    final updatedAt = _date(data['updatedAt']);
    if (createdAt == null || updatedAt == null) {
      throw const FormatException(
        'Expense receipt backup is missing its lifecycle timestamps.',
      );
    }
    final recordState = _recordState(data['recordState']);
    final deletedAt = _deletedAt(data['deletedAt']);
    _validateReceiptLifecycle(
      createdAt: createdAt,
      updatedAt: updatedAt,
      recordState: recordState,
      deletedAt: deletedAt,
    );
    final proofPointers = _proofPointers(data['proofs']);
    final receipt = ExpenseReceiptRecord(
      id: id,
      receiptDate: receiptDate,
      receiptTimeMinutes: _integer(data['receiptTimeMinutes']),
      merchantName: _text(data['merchantName']),
      phone: _text(data['phone']),
      street: _text(data['street']),
      city: _text(data['city']),
      state: _text(data['state']),
      zip: _text(data['zip']),
      email: _text(data['email']),
      website: _text(data['website']),
      notes: _text(data['notes']),
      receiptNumber: _text(data['receiptNumber']),
      paymentMethod: _text(data['paymentMethod']),
      hasReceiptProof:
          _boolean(data['hasReceiptProof']) || proofPointers.isNotEmpty,
      enteredSubtotal: _cents(data['enteredSubtotalCents']),
      enteredTax: _cents(data['enteredTaxCents']),
      enteredTotal: _cents(data['enteredTotalCents']),
      trackMaterialsInInventory: _boolean(data['trackMaterialsInInventory']),
      vehicleId: _nullableText(data['vehicleId']),
      workProfileId: _nullableText(data['workProfileId']),
      odometerReading: _integer(data['odometerReading']),
      sourceScreen: _text(data['sourceScreen'], fallback: 'expenses'),
      createdAt: createdAt,
      updatedAt: updatedAt,
      localRevision: _recordRevision(data['localRevision']),
      recordState: recordState,
      deletedAt: deletedAt,
      auditEvents: _auditEvents(data['auditEvents'], recordId: id),
      fileHashSha256: _text(data['fileHashSha256']),
      duplicateCheckStatus: ExpenseDuplicateCheckStatus.fromName(
        _text(data['duplicateCheckStatus']),
      ),
      duplicateOverride: _boolean(data['duplicateOverride']),
      duplicateOverrideReason: _text(data['duplicateOverrideReason']),
      duplicateCheckedAt: _date(data['duplicateCheckedAt']),
      ocrReview: ExpenseReceiptOcrReview.fromMap(_map(data['ocrReview'])),
      lines: _lines(data['lines']),
    );
    return ExpenseCloudRestoredReceipt(
      receipt: receipt,
      proofPointers: proofPointers,
    );
  }

  static ExpenseCloudRestoredWorkProfiles decodeWorkProfileDirectory(
    Map<dynamic, dynamic> data,
  ) {
    if ('${data['schema']}'.trim() !=
        'expense_work_profile_directory_backup_v1') {
      throw const FormatException(
        'Unsupported Expense work-profile backup schema.',
      );
    }
    final profiles = <ExpenseWorkProfile>[];
    final source = data['profiles'];
    if (source != null && source is! List) {
      throw const FormatException('Expense work-profile backup is corrupt.');
    }
    if (source is List) {
      for (final entry in source) {
        if (entry is! Map) {
          throw const FormatException(
            'Expense work-profile backup is corrupt.',
          );
        }
        if (_text(entry['id']).isEmpty ||
            _text(entry['name']).isEmpty ||
            _date(entry['createdAt']) == null ||
            _date(entry['updatedAt']) == null) {
          throw const FormatException(
            'Expense work-profile backup is incomplete.',
          );
        }
        if (entry['archivedAt'] != null && _date(entry['archivedAt']) == null) {
          throw const FormatException(
            'Expense work-profile archive date is invalid.',
          );
        }
        profiles.add(ExpenseWorkProfile.fromMap(entry));
      }
    }
    return ExpenseCloudRestoredWorkProfiles(
      activeProfileId: _nullableText(data['activeWorkProfileId']),
      profiles: List.unmodifiable(profiles),
    );
  }

  static ExpenseCloudRestoredVehicles decodeVehicleDirectory(
    Map<dynamic, dynamic> data,
  ) {
    if ('${data['schema']}'.trim() != 'expense_vehicle_directory_backup_v1') {
      throw const FormatException('Unsupported Expense vehicle backup schema.');
    }
    final vehicles = <VehicleProfile>[];
    final source = data['vehicles'];
    if (source != null && source is! List) {
      throw const FormatException('Expense vehicle backup is corrupt.');
    }
    if (source is List) {
      for (final entry in source) {
        if (entry is! Map || _text(entry['id']).isEmpty) {
          throw const FormatException('Expense vehicle backup is corrupt.');
        }
        if (entry['archivedAt'] != null && _date(entry['archivedAt']) == null) {
          throw const FormatException(
            'Expense vehicle archive date is invalid.',
          );
        }
        vehicles.add(VehicleProfile.fromMap(entry));
      }
    }
    return ExpenseCloudRestoredVehicles(
      activeVehicleId: _nullableText(data['activeVehicleId']),
      vehicles: List.unmodifiable(vehicles),
    );
  }

  static ExpenseCloudRestoredReminder decodeReminder(
    Map<dynamic, dynamic> data,
  ) {
    if ('${data['schema']}'.trim() != 'expense_reminder_backup_v1') {
      throw const FormatException(
        'Unsupported Expense reminder backup schema.',
      );
    }
    final id = _text(data['id']);
    final dueAt = _date(data['dueAt']);
    if (id.isEmpty || dueAt == null) {
      throw const FormatException('Expense reminder backup is incomplete.');
    }
    final createdAt = _date(data['createdAt']) ?? dueAt;
    final updatedAt = _date(data['updatedAt']) ?? createdAt;
    final record = ExpenseReminderRecord.fromMap({
      'id': id,
      'title': _text(data['title']),
      'category': _text(data['category'], fallback: 'Other'),
      'channel': _text(data['channel'], fallback: 'in_app'),
      'dueAt': dueAt.toIso8601String(),
      'cadence': _text(data['cadence']),
      'details': _text(data['details']),
      'active': _boolean(data['active'], fallback: true),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lifecycle': {
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'revision': _recordRevision(data['localRevision']),
        'state': _recordState(data['recordState']).name,
        'deletedAt': _deletedAt(data['deletedAt'])?.toIso8601String(),
      },
    });
    return ExpenseCloudRestoredReminder(record);
  }

  static List<ExpenseReceiptLineRecord> _lines(Object? value) {
    if (value == null) return const [];
    if (value is! List) {
      throw const FormatException('Expense receipt line metadata is corrupt.');
    }
    final lines = <ExpenseReceiptLineRecord>[];
    final ids = <String>{};
    for (final item in value) {
      final id = item is Map ? _text(item['id']) : '';
      if (item is! Map || id.isEmpty || !ids.add(id)) {
        throw const FormatException(
          'Expense receipt line metadata is corrupt.',
        );
      }
      lines.add(
        ExpenseReceiptLineRecord.fromMap({
          ...item,
          'subtotal': _cents(item['subtotalCents']) ?? 0,
          'unitPrice': _cents(item['unitPriceCents']),
          'rawReceiptText': '',
        }),
      );
    }
    return List.unmodifiable(lines);
  }

  static List<ExpenseCloudProofPointer> _proofPointers(Object? value) {
    if (value == null) return const [];
    if (value is! List) {
      throw const FormatException('Expense receipt proof metadata is corrupt.');
    }
    final pointers = <ExpenseCloudProofPointer>[];
    final ids = <String>{};
    for (final item in value) {
      final id = item is Map ? _text(item['id']) : '';
      if (item is! Map || id.isEmpty || !ids.add(id)) {
        throw const FormatException(
          'Expense receipt proof metadata is corrupt.',
        );
      }
      final availability = ExpenseCloudProofAvailability.fromBackupValue(
        item['cloudProofState'],
      );
      final storagePath = _nullableText(item['storagePath']);
      if (availability == ExpenseCloudProofAvailability.available &&
          storagePath == null) {
        throw const FormatException(
          'Cloud receipt proof metadata is missing its storage path.',
        );
      }
      if (storagePath != null && !_isSafeCloudProofPath(storagePath)) {
        throw const FormatException('Cloud receipt proof path is unsafe.');
      }
      pointers.add(
        ExpenseCloudProofPointer(
          id: _text(item['id']),
          storagePath: availability == ExpenseCloudProofAvailability.available
              ? storagePath
              : null,
          uploadGrantId: availability == ExpenseCloudProofAvailability.available
              ? _nullableText(item['uploadGrantId'])
              : null,
          availability: availability,
          kind: ReceiptAttachmentKind.fromName(_text(item['kind'])),
          mimeType: _text(item['mimeType']),
          byteSize: _integer(item['backupByteSize'] ?? item['byteSize']),
          fileHashSha256: _text(item['fileHashSha256']),
          dataSaverLevel: ReceiptDataSaverLevel.fromName(
            _text(item['dataSaverLevel']),
          ),
        ),
      );
    }
    return List.unmodifiable(pointers);
  }

  static bool _isSafeCloudProofPath(String path) {
    final segments = path.split('/');
    return segments.length >= 2 &&
        segments.every(
          (segment) =>
              RegExp(r'^[A-Za-z0-9._-]{1,160}$').hasMatch(segment) &&
              segment != '.' &&
              segment != '..',
        );
  }

  static List<String> _auditEvents(Object? value, {required String recordId}) {
    if (value == null) return const [];
    if (value is! List) {
      throw const FormatException('Expense receipt audit metadata is corrupt.');
    }
    final events = <String>[];
    for (final item in value) {
      if (item is! Map ||
          _date(item['occurredAt']) == null ||
          _text(item['action']).isEmpty ||
          _text(item['recordId']) != recordId) {
        throw const FormatException(
          'Expense receipt audit metadata is corrupt.',
        );
      }
      events.add(
        '${_date(item['occurredAt'])!.toUtc().toIso8601String()} '
        '${_text(item['action'])} receipt ${_text(item['recordId'])}',
      );
    }
    return List.unmodifiable(events);
  }

  static Map<dynamic, dynamic> _map(Object? value) =>
      value is Map ? value : const {};

  static String _text(Object? value, {String fallback = ''}) {
    final result = '${value ?? ''}'.trim();
    return result.isEmpty ? fallback : result;
  }

  static String? _nullableText(Object? value) {
    final result = _text(value);
    return result.isEmpty ? null : result;
  }

  static DateTime? _date(Object? value) =>
      DateTime.tryParse(_text(value))?.toUtc();

  static MaintainiacRecordState _recordState(Object? value) {
    if (value == null || _text(value).isEmpty) {
      return MaintainiacRecordState.active;
    }
    final name = _text(value).toLowerCase();
    for (final state in MaintainiacRecordState.values) {
      if (state.name == name) return state;
    }
    throw const FormatException('Expense record lifecycle state is corrupt.');
  }

  static DateTime? _deletedAt(Object? value) {
    if (value == null || _text(value).isEmpty) return null;
    final date = _date(value);
    if (date == null) {
      throw const FormatException(
        'Expense record deletion timestamp is corrupt.',
      );
    }
    return date;
  }

  static void _validateReceiptLifecycle({
    required DateTime createdAt,
    required DateTime updatedAt,
    required MaintainiacRecordState recordState,
    required DateTime? deletedAt,
  }) {
    if (updatedAt.isBefore(createdAt)) {
      throw const FormatException(
        'Expense receipt lifecycle timestamps are out of order.',
      );
    }
    if (recordState == MaintainiacRecordState.deleted && deletedAt == null) {
      throw const FormatException(
        'Deleted Expense receipt backup is missing its deletion timestamp.',
      );
    }
    if (recordState == MaintainiacRecordState.active && deletedAt != null) {
      throw const FormatException(
        'Active Expense receipt backup has a deletion timestamp.',
      );
    }
    if (deletedAt != null &&
        (deletedAt.isBefore(createdAt) || deletedAt.isAfter(updatedAt))) {
      throw const FormatException(
        'Expense receipt deletion timestamp is out of order.',
      );
    }
  }

  static int _recordRevision(Object? value) {
    if (value == null || _text(value).isEmpty) return 1;
    final revision = switch (value) {
      int number => number,
      double number when number.isFinite && number == number.truncate() =>
        number.toInt(),
      String text => int.tryParse(text.trim()),
      _ => null,
    };
    if (revision == null || revision < 1) {
      throw const FormatException(
        'Expense record lifecycle revision is corrupt.',
      );
    }
    return revision;
  }

  static int? _integer(Object? value) {
    if (value is num) return value.isFinite ? value.round() : null;
    return int.tryParse(_text(value));
  }

  static double? _cents(Object? value) {
    if (value is! num || !value.isFinite) return null;
    return value.toDouble() / 100;
  }

  static bool _boolean(Object? value, {bool fallback = false}) {
    if (value == null) return fallback;
    return value == true || value == 'true';
  }
}

class ExpenseCloudRestoredReceipt {
  const ExpenseCloudRestoredReceipt({
    required this.receipt,
    required this.proofPointers,
  });

  final ExpenseReceiptRecord receipt;
  final List<ExpenseCloudProofPointer> proofPointers;
}

class ExpenseCloudRestoredWorkProfiles {
  const ExpenseCloudRestoredWorkProfiles({
    required this.activeProfileId,
    required this.profiles,
  });

  final String? activeProfileId;
  final List<ExpenseWorkProfile> profiles;
}

class ExpenseCloudRestoredVehicles {
  const ExpenseCloudRestoredVehicles({
    required this.activeVehicleId,
    required this.vehicles,
  });

  final String? activeVehicleId;
  final List<VehicleProfile> vehicles;
}

class ExpenseCloudRestoredReminder {
  const ExpenseCloudRestoredReminder(this.record);

  final ExpenseReminderRecord record;
}

/// Storage facts for a user-authorized restore choice.
///
/// The estimate intentionally separates structured records from proof files:
/// records-only restores do not require downloading proof bytes, while a full
/// restore can disclose the known proof-file total before it starts.
class ExpenseCloudRestoreEstimate {
  const ExpenseCloudRestoreEstimate({
    required this.recordCount,
    required this.proofCount,
    required this.cloudProofCount,
    required this.metadataOnlyProofCount,
    required this.knownProofBytes,
    required this.proofsWithUnknownSize,
  });

  factory ExpenseCloudRestoreEstimate.fromReceipts(
    Iterable<ExpenseCloudRestoredReceipt> receipts,
  ) {
    var recordCount = 0;
    var proofCount = 0;
    var cloudProofCount = 0;
    var metadataOnlyProofCount = 0;
    var knownProofBytes = 0;
    var proofsWithUnknownSize = 0;
    for (final receipt in receipts) {
      recordCount += 1;
      for (final proof in receipt.proofPointers) {
        proofCount += 1;
        if (!proof.isCloudBacked) {
          metadataOnlyProofCount += 1;
          continue;
        }
        cloudProofCount += 1;
        final byteSize = proof.byteSize;
        if (byteSize == null || byteSize < 0) {
          proofsWithUnknownSize += 1;
        } else {
          knownProofBytes += byteSize;
        }
      }
    }
    return ExpenseCloudRestoreEstimate(
      recordCount: recordCount,
      proofCount: proofCount,
      cloudProofCount: cloudProofCount,
      metadataOnlyProofCount: metadataOnlyProofCount,
      knownProofBytes: knownProofBytes,
      proofsWithUnknownSize: proofsWithUnknownSize,
    );
  }

  final int recordCount;
  final int proofCount;
  final int cloudProofCount;
  final int metadataOnlyProofCount;
  final int knownProofBytes;
  final int proofsWithUnknownSize;

  bool get hasCompleteProofByteEstimate => proofsWithUnknownSize == 0;
}

enum ExpenseCloudProofAvailability {
  metadataOnly,
  available;

  static ExpenseCloudProofAvailability fromBackupValue(Object? value) {
    final normalized = '${value ?? ''}'.trim().toLowerCase();
    return switch (normalized) {
      '' || 'metadata_only' => metadataOnly,
      'available' => available,
      _ => throw const FormatException('Cloud receipt proof state is corrupt.'),
    };
  }
}

class ExpenseCloudProofPointer {
  const ExpenseCloudProofPointer({
    required this.id,
    required this.storagePath,
    this.uploadGrantId,
    required this.availability,
    required this.kind,
    required this.mimeType,
    required this.byteSize,
    required this.fileHashSha256,
    required this.dataSaverLevel,
  });

  final String id;
  final String? storagePath;
  final String? uploadGrantId;
  final ExpenseCloudProofAvailability availability;
  final ReceiptAttachmentKind kind;
  final String mimeType;
  final int? byteSize;
  final String fileHashSha256;
  final ReceiptDataSaverLevel dataSaverLevel;

  bool get isCloudBacked =>
      availability == ExpenseCloudProofAvailability.available;
}
