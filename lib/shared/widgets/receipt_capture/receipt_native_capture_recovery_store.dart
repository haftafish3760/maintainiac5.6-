import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import 'receipt_capture_models.dart';
import 'receipt_native_capture_diagnostics_sanitizer.dart';

class ReceiptNativeCaptureRecoveryIndexEntry {
  ReceiptNativeCaptureRecoveryIndexEntry({
    required this.sessionId,
    required this.manifestPath,
    required this.engineName,
    required this.capturedAt,
    required this.dataSaverLevelName,
    required this.photoCount,
    required List<String> stagedPhotoPaths,
    required List<ReceiptAttachmentRecord> attachments,
    required this.captureDiagnostics,
    this.recoverySafety = const {},
  }) : stagedPhotoPaths = List<String>.unmodifiable(stagedPhotoPaths),
       attachments = List<ReceiptAttachmentRecord>.unmodifiable(attachments);

  factory ReceiptNativeCaptureRecoveryIndexEntry.fromMap(
    Map<dynamic, dynamic> map,
  ) {
    return ReceiptNativeCaptureRecoveryIndexEntry(
      sessionId: (map['sessionId'] as String? ?? '').trim(),
      manifestPath: (map['manifestPath'] as String? ?? '').trim(),
      engineName: (map['engineName'] as String? ?? '').trim(),
      capturedAt:
          DateTime.tryParse(map['capturedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dataSaverLevelName: (map['dataSaverLevelName'] as String? ?? '').trim(),
      photoCount: map['photoCount'] is int ? map['photoCount'] as int : 0,
      stagedPhotoPaths:
          (map['stagedPhotoPaths'] as List?)
              ?.map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList(growable: false) ??
          const [],
      attachments:
          (map['attachments'] as List?)
              ?.whereType<Map>()
              .map(ReceiptAttachmentRecord.fromMap)
              .toList(growable: false) ??
          const [],
      captureDiagnostics: receiptNativeCaptureSanitizedDiagnostics(
        map['captureDiagnostics'],
      ),
      recoverySafety: receiptNativeCaptureSanitizedDiagnostics(
        map['recoverySafety'],
      ),
    );
  }

  final String sessionId;
  final String manifestPath;
  final String engineName;
  final DateTime capturedAt;
  final String dataSaverLevelName;
  final int photoCount;
  final List<String> stagedPhotoPaths;
  final List<ReceiptAttachmentRecord> attachments;
  final Map<String, Object?> captureDiagnostics;
  final Map<String, Object?> recoverySafety;

  bool get hasExistingManifest {
    return manifestPath.trim().isNotEmpty && File(manifestPath).existsSync();
  }

  bool get hasExistingPhotos {
    return stagedPhotoPaths.any((photoPath) => File(photoPath).existsSync());
  }

  Map<String, Object?> toMap() {
    return {
      'schema': ReceiptNativeCaptureRecoveryStore.entrySchema,
      'sessionId': sessionId,
      'manifestPath': manifestPath,
      'engineName': engineName,
      'capturedAt': capturedAt.toIso8601String(),
      'dataSaverLevelName': dataSaverLevelName,
      'photoCount': photoCount,
      'stagedPhotoPaths': stagedPhotoPaths,
      'attachments': [for (final attachment in attachments) attachment.toMap()],
      'captureDiagnostics': captureDiagnostics,
      if (recoverySafety.isNotEmpty) 'recoverySafety': recoverySafety,
      'privacy': {
        'storesReceiptImageContent': false,
        'storesReceiptText': false,
        'storesCustomerContent': false,
      },
    };
  }
}

class ReceiptNativeCaptureRecoveryStore {
  const ReceiptNativeCaptureRecoveryStore._(this._box);

  static const boxName = 'receipt_native_capture_recovery_index';
  static const entrySchema = 'receipt_native_capture_recovery_index_v1';

  static Future<ReceiptNativeCaptureRecoveryStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return ReceiptNativeCaptureRecoveryStore._(box);
  }

  final Box<dynamic> _box;

  List<ReceiptNativeCaptureRecoveryIndexEntry> get entries {
    final result = <ReceiptNativeCaptureRecoveryIndexEntry>[];
    for (final value in _box.values) {
      if (value is! Map || value['schema'] != entrySchema) continue;
      result.add(ReceiptNativeCaptureRecoveryIndexEntry.fromMap(value));
    }
    result.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return result;
  }

  Future<void> save(ReceiptNativeCaptureRecoveryIndexEntry entry) {
    return _box.put(
      _keyFor(entry.sessionId, entry.manifestPath),
      entry.toMap(),
    );
  }

  Future<void> updateDiagnosticsByManifestPath(
    String manifestPath,
    Map<String, Object?> diagnostics,
  ) async {
    final normalized = manifestPath.trim();
    if (normalized.isEmpty) return;
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value is! Map || value['schema'] != entrySchema) continue;
      if ((value['manifestPath'] as String? ?? '').trim() != normalized) {
        continue;
      }
      final updated = Map<dynamic, dynamic>.from(value);
      final existingDiagnostics = receiptNativeCaptureSanitizedDiagnostics(
        updated['captureDiagnostics'],
      );
      updated['captureDiagnostics'] = receiptNativeCaptureSanitizedDiagnostics({
        ...existingDiagnostics,
        ...diagnostics,
      });
      await _box.put(key, updated);
      return;
    }
  }

  Future<void> deleteByManifestPath(String manifestPath) async {
    final normalized = manifestPath.trim();
    if (normalized.isEmpty) return;
    final keysToDelete = <dynamic>[];
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value is! Map) continue;
      if ((value['manifestPath'] as String? ?? '').trim() == normalized) {
        keysToDelete.add(key);
      }
    }
    for (final key in keysToDelete) {
      await _box.delete(key);
    }
  }

  Future<void> deleteMissingManifestEntries() async {
    final keysToDelete = <dynamic>[];
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value is! Map || value['schema'] != entrySchema) continue;
      final entry = ReceiptNativeCaptureRecoveryIndexEntry.fromMap(value);
      if (!entry.hasExistingManifest && !entry.hasExistingPhotos) {
        keysToDelete.add(key);
      }
    }
    for (final key in keysToDelete) {
      await _box.delete(key);
    }
  }

  Future<void> deleteUnrecoverableEntries({
    Iterable<String> retainedPaths = const [],
  }) async {
    final retained = retainedPaths
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    final keysToDelete = <dynamic>[];
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value is! Map || value['schema'] != entrySchema) continue;
      final entry = ReceiptNativeCaptureRecoveryIndexEntry.fromMap(value);
      final hasRetainedPhoto = entry.stagedPhotoPaths.any(retained.contains);
      if (hasRetainedPhoto) continue;
      if (!entry.hasExistingManifest && !entry.hasExistingPhotos) {
        keysToDelete.add(key);
      }
    }
    for (final key in keysToDelete) {
      await _box.delete(key);
    }
  }

  Future<void> deleteOldEntries({
    Iterable<String> retainedPaths = const [],
    Duration olderThan = const Duration(days: 7),
    DateTime? now,
  }) async {
    final retained = retainedPaths
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    final reference = now ?? DateTime.now();
    final cutoff = reference.subtract(olderThan);
    final keysToDelete = <dynamic>[];
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value is! Map || value['schema'] != entrySchema) continue;
      final entry = ReceiptNativeCaptureRecoveryIndexEntry.fromMap(value);
      final hasRetainedPhoto = entry.stagedPhotoPaths.any(retained.contains);
      if (hasRetainedPhoto) continue;
      if (entry.capturedAt.isAfter(cutoff)) continue;
      keysToDelete.add(key);
    }
    for (final key in keysToDelete) {
      await _box.delete(key);
    }
  }

  static String _keyFor(String sessionId, String manifestPath) {
    final safeSession = sessionId.trim();
    if (safeSession.isNotEmpty) return safeSession;
    return manifestPath.trim();
  }
}
