import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'app_document_models.dart';

class AppDocumentStore extends ChangeNotifier {
  AppDocumentStore._(this._box);
  AppDocumentStore.memory() : _box = null;

  static const boxName = 'app_document_records';

  final Box<dynamic>? _box;
  final _memoryRecords = <String, AppDocumentRecord>{};

  static Future<AppDocumentStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return AppDocumentStore._(box);
  }

  List<AppDocumentRecord> get records {
    final source = _box == null ? _memoryRecords.values : _box.values;
    final records = <AppDocumentRecord>[];
    for (final value in source) {
      if (value is AppDocumentRecord) {
        records.add(value);
      } else if (value is Map) {
        records.add(AppDocumentRecord.fromMap(value));
      }
    }
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return records;
  }

  List<AppDocumentRecord> recordsForKind(AppDocumentKind kind) {
    return records.where((record) => record.kind == kind).toList();
  }

  AppDocumentRecord? recordById(String id) {
    final value = _box == null ? _memoryRecords[id] : _box.get(id);
    if (value is AppDocumentRecord) return value;
    if (value is Map) return AppDocumentRecord.fromMap(value);
    return null;
  }

  Future<AppDocumentRecord> saveRecord(AppDocumentRecord record) async {
    final now = DateTime.now();
    final existing = recordById(record.id);
    final saved = record.copyWith(
      createdAt: existing?.createdAt ?? record.createdAt,
      updatedAt: now,
    );
    if (_box == null) {
      _memoryRecords[saved.id] = saved;
    } else {
      await _box.put(saved.id, saved.toMap());
    }
    notifyListeners();
    return saved;
  }

  Future<void> deleteRecord(
    String id, {
    bool deleteAttachmentFiles = true,
  }) async {
    final existing = recordById(id);
    if (_box == null) {
      _memoryRecords.remove(id);
    } else {
      await _box.delete(id);
    }
    if (deleteAttachmentFiles && existing != null) {
      await deleteAppOwnedAttachmentFiles(existing.attachments);
    }
    notifyListeners();
  }

  Future<void> deleteAppOwnedAttachmentFiles(
    Iterable<dynamic> attachments, {
    Set<String> keepPaths = const {},
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final rootPath = path.normalize(path.absolute(root.path));
    final retained = keepPaths
        .map((item) => path.normalize(path.absolute(item.trim())))
        .where((item) => item.isNotEmpty)
        .toSet();
    for (final attachment in attachments) {
      final attachmentPath = attachment.path?.toString().trim() ?? '';
      if (attachmentPath.isEmpty) continue;
      final normalized = path.normalize(path.absolute(attachmentPath));
      if (retained.contains(normalized)) continue;
      if (!path.isWithin(rootPath, normalized)) continue;
      try {
        final type = await FileSystemEntity.type(
          normalized,
          followLinks: false,
        );
        if (type == FileSystemEntityType.file) {
          await File(normalized).delete();
        } else if (type == FileSystemEntityType.link) {
          await Link(normalized).delete();
        }
      } catch (_) {
        continue;
      }
    }
  }

  Future<void> clear({bool deleteAttachmentFiles = false}) async {
    final existingRecords = deleteAttachmentFiles
        ? records.toList(growable: false)
        : const <AppDocumentRecord>[];
    _memoryRecords.clear();
    await _box?.clear();
    if (deleteAttachmentFiles) {
      for (final record in existingRecords) {
        await deleteAppOwnedAttachmentFiles(record.attachments);
      }
    }
    notifyListeners();
  }
}
