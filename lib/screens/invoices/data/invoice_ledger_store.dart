import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../shared/storage/app_storage_guard.dart';
import 'invoice_ledger_models.dart';
import 'invoice_record.dart';

class InvoiceLedgerStore extends ChangeNotifier {
  InvoiceLedgerStore._(
    this._box, {
    required this.canPersist,
    required this.encryptedAtRest,
    InvoiceNumberSettings? memorySettings,
  }) : _memorySettings = memorySettings ?? const InvoiceNumberSettings();

  InvoiceLedgerStore.memory({
    bool canPersist = true,
    bool encryptedAtRest = false,
    InvoiceNumberSettings? settings,
  }) : this._(
         null,
         canPersist: canPersist,
         encryptedAtRest: encryptedAtRest,
         memorySettings: settings,
       );

  static const boxName = 'invoice_ledger_records';
  static const _settingsKey = 'settings:numbering';
  static const _recordPrefix = 'record:';
  static const _encryptionKeyName = 'maintainiac_invoice_ledger_box_key';

  final Box<dynamic>? _box;
  final bool canPersist;
  final bool encryptedAtRest;
  final _memoryRecords = <String, InvoiceRecord>{};
  InvoiceNumberSettings _memorySettings;

  static Future<InvoiceLedgerStore> create() async {
    try {
      final storageCheck = await AppStorageGuard.check(
        AppStoragePurpose.smallRecordWrite,
      );
      if (!storageCheck.hasEnoughSpace) {
        return InvoiceLedgerStore.memory(canPersist: false);
      }
      final encryptionKey = await _loadOrCreateEncryptionKey(
        const FlutterSecureStorage(),
      );
      final box = await Hive.openBox<dynamic>(
        boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
      return InvoiceLedgerStore._(box, canPersist: true, encryptedAtRest: true);
    } on MissingPluginException {
      return InvoiceLedgerStore.memory(canPersist: false);
    } on PlatformException {
      return InvoiceLedgerStore.memory(canPersist: false);
    }
  }

  InvoiceNumberSettings get numberSettings {
    final value = _box?.get(_settingsKey);
    if (value is Map) return InvoiceNumberSettings.fromMap(value);
    return _memorySettings;
  }

  List<InvoiceRecord> get records {
    final source = _box == null
        ? _memoryRecords.values
        : _box.values.whereType<Map>().where(_isRecordMap);
    final records = <InvoiceRecord>[];
    for (final value in source) {
      if (value is InvoiceRecord) {
        records.add(value);
      } else if (value is Map) {
        records.add(InvoiceRecord.fromMap(value));
      }
    }
    records.sort((a, b) => b.meta.updatedAt.compareTo(a.meta.updatedAt));
    return records;
  }

  List<InvoiceRecord> dirtyRecords() {
    return records.where((record) => record.dirty).toList(growable: false);
  }

  InvoiceRecord? recordById(String id) {
    final value = _box == null ? _memoryRecords[id] : _box.get(_recordKey(id));
    if (value is InvoiceRecord) return value;
    if (value is Map) return InvoiceRecord.fromMap(value);
    return null;
  }

  List<InvoiceRecord> recordsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return records
        .where((record) {
          final issue = DateTime(
            record.issueDate.year,
            record.issueDate.month,
            record.issueDate.day,
          );
          return issue == key;
        })
        .toList(growable: false);
  }

  Future<void> saveNumberSettings(InvoiceNumberSettings settings) async {
    if (!canPersist) {
      throw StateError('Invoice ledger persistence is not available.');
    }
    _memorySettings = settings;
    if (_box != null) await _box.put(_settingsKey, settings.toMap());
    notifyListeners();
  }

  Future<InvoiceRecord> createDraft({
    required InvoiceDocumentType type,
    String? manualNumber,
    DateTime? now,
    String title = '',
    String vehicleId = '',
    String profileId = '',
  }) async {
    final createdAt = now ?? DateTime.now();
    var settings = numberSettings;
    final numberMode = manualNumber == null || manualNumber.trim().isEmpty
        ? settings.mode
        : InvoiceNumberMode.manual;
    final number = numberMode == InvoiceNumberMode.automatic
        ? settings.numberFor(type)
        : manualNumber!.trim();
    if (numberMode == InvoiceNumberMode.automatic) {
      settings = settings.advanceFor(type);
      await saveNumberSettings(settings);
    }
    final record = InvoiceRecord(
      id: _newInvoiceId(type, createdAt),
      documentType: type,
      invoiceNumber: number,
      numberMode: numberMode,
      status: InvoiceRecordStatus.draft,
      title: title,
      issueDate: createdAt,
      dueDate: type == InvoiceDocumentType.invoice
          ? createdAt.add(const Duration(days: 30))
          : null,
      vehicleId: vehicleId,
      profileId: profileId,
      meta: InvoiceSyncMetadata(createdAt: createdAt, updatedAt: createdAt),
      auditEvents: [
        '${createdAt.toIso8601String()} created ${type.name} draft $number',
      ],
    );
    return saveRecord(record, now: createdAt);
  }

  Future<InvoiceRecord> saveRecord(
    InvoiceRecord record, {
    DateTime? now,
  }) async {
    if (!canPersist) {
      throw StateError('Invoice ledger persistence is not available.');
    }
    final savedAt = now ?? DateTime.now();
    final existing = recordById(record.id);
    final meta = existing == null
        ? record.meta.copyWith(
            updatedAt: savedAt,
            syncStatus: InvoiceSyncStatus.dirty,
          )
        : existing.meta.markDirty(savedAt);
    final saved = record.copyWith(
      meta: meta,
      auditEvents: [
        ...record.auditEvents,
        '${savedAt.toIso8601String()} ${existing == null ? 'saved' : 'updated'} ${record.documentType.name} ${record.invoiceNumber}',
      ],
    );
    if (_box == null) {
      _memoryRecords[saved.id] = saved;
    } else {
      await _box.put(_recordKey(saved.id), saved.toMap());
    }
    notifyListeners();
    return saved;
  }

  Future<void> markSynced({
    required String id,
    required DateTime syncedAt,
    String firebasePath = '',
  }) async {
    final record = recordById(id);
    if (record == null) return;
    final saved = record.copyWith(
      meta: record.meta.markSynced(syncedAt, firebasePath: firebasePath),
    );
    if (_box == null) {
      _memoryRecords[id] = saved;
    } else {
      await _box.put(_recordKey(id), saved.toMap());
    }
    notifyListeners();
  }

  Future<void> deleteRecord(String id, {DateTime? now}) async {
    final record = recordById(id);
    if (record == null) return;
    final deletedAt = now ?? DateTime.now();
    final pendingDelete = record.copyWith(
      status: InvoiceRecordStatus.voided,
      meta: record.meta.copyWith(
        updatedAt: deletedAt,
        revision: record.meta.revision + 1,
        deletedAt: deletedAt,
        syncStatus: InvoiceSyncStatus.pendingDelete,
        clearLastSyncedAt: true,
      ),
    );
    if (_box == null) {
      _memoryRecords[id] = pendingDelete;
    } else {
      await _box.put(_recordKey(id), pendingDelete.toMap());
    }
    notifyListeners();
  }

  List<InvoiceDailyBackupBatch> dirtyDailyBatches() {
    final grouped = <String, List<InvoiceRecord>>{};
    for (final record in dirtyRecords()) {
      final key = _dayKey(record.meta.updatedAt);
      grouped.putIfAbsent(key, () => []).add(record);
    }
    return [
      for (final entry in grouped.entries)
        InvoiceDailyBackupBatch(dayKey: entry.key, records: entry.value),
    ]..sort((a, b) => a.dayKey.compareTo(b.dayKey));
  }

  Future<void> clear() async {
    _memoryRecords.clear();
    if (_box != null) {
      await _box.clear();
    }
    notifyListeners();
  }

  static String _recordKey(String id) => '$_recordPrefix$id';

  static bool _isRecordMap(Map<dynamic, dynamic> map) {
    return (map['id'] as String? ?? '').isNotEmpty &&
        map.containsKey('documentType');
  }

  static String _dayKey(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }

  static String _newInvoiceId(InvoiceDocumentType type, DateTime now) {
    final random = Random.secure().nextInt(0xFFFFFF).toRadixString(16);
    return '${type.name}_${now.microsecondsSinceEpoch}_$random';
  }

  static Future<List<int>> _loadOrCreateEncryptionKey(
    FlutterSecureStorage storage,
  ) async {
    final existing = await storage.read(key: _encryptionKeyName);
    if (existing != null && existing.isNotEmpty) {
      return base64Url.decode(existing);
    }
    final key = Hive.generateSecureKey();
    await storage.write(key: _encryptionKeyName, value: base64Url.encode(key));
    return key;
  }
}

class InvoiceDailyBackupBatch {
  const InvoiceDailyBackupBatch({required this.dayKey, required this.records});

  final String dayKey;
  final List<InvoiceRecord> records;

  Map<String, dynamic> toMap() {
    return {
      'dayKey': dayKey,
      'records': [for (final record in records) record.toMap()],
    };
  }
}

class InvoiceLedgerScope extends InheritedNotifier<InvoiceLedgerStore> {
  const InvoiceLedgerScope({
    super.key,
    required InvoiceLedgerStore controller,
    required super.child,
  }) : super(notifier: controller);

  static InvoiceLedgerStore of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<InvoiceLedgerScope>();
    assert(scope != null, 'InvoiceLedgerScope is missing above this context.');
    return scope!.notifier!;
  }

  static InvoiceLedgerStore? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InvoiceLedgerScope>()
        ?.notifier;
  }
}
