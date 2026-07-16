import 'package:hive_flutter/hive_flutter.dart';

import '../../../shared/storage/app_storage_guard.dart';
import 'expense_cloud_proof_cache.dart';
import 'expense_cloud_proof_storage.dart';
import 'expense_cloud_restore_session.dart';
import 'expense_cloud_restore_storage_plan.dart';

/// Downloads full-restore proof files into the app-owned, hash-verified cache.
/// Each proof is checkpointed before session progress advances, so an
/// interruption resumes without re-downloading completed evidence.
class ExpenseCloudRestoreProofCoordinator {
  const ExpenseCloudRestoreProofCoordinator({
    required this.cache,
    required this.sessions,
    required this.checkpoints,
  });

  final ExpenseCloudProofCache cache;
  final ExpenseCloudRestoreSessionStore sessions;
  final ExpenseCloudRestoreProofCheckpointStore checkpoints;

  Future<ExpenseCloudRestoreProofResult> restoreFullProofs({
    required String sessionId,
    required Iterable<ExpenseCloudProofReference> references,
    DateTime? nowUtc,
  }) async {
    final session = sessions.sessionById(sessionId);
    if (session == null) throw StateError('Restore session was not found.');
    if (session.mode != ExpenseCloudRestoreMode.full) {
      throw StateError('Only a full restore may download receipt proofs.');
    }

    var restored = 0;
    try {
      await _checkpointProgress(sessionId, nowUtc: nowUtc);
      for (final reference in references) {
        if (await checkpoints.contains(sessionId, reference)) {
          // A checkpoint is valid only while the app-owned cache can still
          // verify this exact proof. A corrupt/missing cache copy is repaired
          // before the restore can report completion.
          await cache.restore(reference);
          continue;
        }
        await cache.restore(reference);
        await checkpoints.markCompleted(sessionId, reference);
        restored += 1;
        await _checkpointProgress(sessionId, nowUtc: nowUtc);
      }
    } catch (error) {
      await sessions.fail(
        sessionId,
        'Proof restore could not continue.',
        nowUtc: nowUtc,
      );
      rethrow;
    }

    final current = sessions.sessionById(sessionId);
    if (current != null && current.hasCompletedTransfer) {
      await sessions.complete(sessionId, nowUtc: nowUtc);
      await checkpoints.clear(sessionId);
    }
    return ExpenseCloudRestoreProofResult(restoredCount: restored);
  }

  Future<void> _checkpointProgress(String sessionId, {DateTime? nowUtc}) async {
    final current = sessions.sessionById(sessionId);
    if (current == null) throw StateError('Restore session was not found.');
    await sessions.updateProgress(
      id: sessionId,
      completedDownloadBytes: await checkpoints.completedBytes(sessionId),
      completedRecords: current.completedRecords,
      nowUtc: nowUtc,
    );
  }
}

class ExpenseCloudRestoreProofResult {
  const ExpenseCloudRestoreProofResult({required this.restoredCount});

  final int restoredCount;
}

/// Checkpoints are app-owned bookkeeping only: no local proof path, auth
/// token, or raw receipt content is persisted. The cache itself is the proof
/// file source of truth after hash verification succeeds.
class ExpenseCloudRestoreProofCheckpointStore {
  ExpenseCloudRestoreProofCheckpointStore._(this._box, {this.storageCheck});

  static const boxName = 'expense_cloud_restore_proof_checkpoints_v1';

  static Future<ExpenseCloudRestoreProofCheckpointStore> create({
    ExpenseCloudRestoreProofCheckpointStorageCheck? storageCheck,
  }) async => ExpenseCloudRestoreProofCheckpointStore._(
    await Hive.openBox<dynamic>(boxName),
    storageCheck: storageCheck ?? _defaultStorageCheck,
  );

  final Box<dynamic> _box;
  final ExpenseCloudRestoreProofCheckpointStorageCheck? storageCheck;
  Future<void> _writeTail = Future<void>.value();

  Future<bool> contains(
    String sessionId,
    ExpenseCloudProofReference reference,
  ) async => _box.containsKey(_key(sessionId, reference));

  Future<void> markCompleted(
    String sessionId,
    ExpenseCloudProofReference reference,
  ) => _enqueue(() async {
    await _ensureStorage();
    await _box.put(_key(sessionId, reference), reference.byteCount);
  });

  Future<int> completedBytes(String sessionId) async {
    final prefix = '${sessionId.trim()}|';
    return _box.toMap().entries.fold<int>(0, (total, entry) {
      if (!entry.key.toString().startsWith(prefix)) return total;
      final bytes = entry.value is int ? entry.value as int : 0;
      return bytes > 0 ? total + bytes : total;
    });
  }

  Future<void> clear(String sessionId) => _enqueue(() async {
    final prefix = '${sessionId.trim()}|';
    final keys = _box.keys
        .where((key) => key.toString().startsWith(prefix))
        .toList(growable: false);
    await _box.deleteAll(keys);
  });

  Future<void> _ensureStorage() async {
    final check = storageCheck;
    if (check == null) return;
    final storage = await check();
    if (!storage.hasEnoughSpace) throw StateError(storage.blockingMessage());
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _writeTail.then((_) => operation());
    _writeTail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  static String _key(String sessionId, ExpenseCloudProofReference reference) {
    final session = sessionId.trim();
    if (session.isEmpty) throw StateError('Restore session ID is required.');
    return '$session|${reference.organizationId}|${reference.userId}'
        '|${reference.receiptId}|${reference.proofId}'
        '|${reference.contentHashSha256}';
  }
}

typedef ExpenseCloudRestoreProofCheckpointStorageCheck =
    Future<AppStorageCheck> Function();

Future<AppStorageCheck> _defaultStorageCheck() =>
    AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);
