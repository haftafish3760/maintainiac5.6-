import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_import_validator.dart';

void main() {
  group('inventory parser pack integrity recovery behavior', () {
    test('corrupt pack never loads as current and keeps previous pack', () async {
      final previous = _InstalledPack(
        packId: 'plumbing.residential.core',
        version: '2026.07.01',
        localePackId: 'en-US',
        enabled: true,
      );
      final corrupt = await _writePackFixture(packVersion: '2026.07.02');
      addTearDown(corrupt.delete);
      await File(
        '${corrupt.directory.path}/${corrupt.storagePath}',
      ).writeAsString('not gzip');

      final result = await const WorkSupplyTradePackImportValidator()
          .validateDirectory(corrupt.directory);
      final recovery = _recoverPackInstall(
        previous: previous,
        attempted: corrupt.toAttempt(),
        validation: result,
      );

      expect(result.status, WorkSupplyTradePackValidationStatus.unreadableChunk);
      expect(recovery.current, previous);
      expect(recovery.promoted, isFalse);
      expect(recovery.diagnostic, contains('unreadableChunk'));
      expect(recovery.liveFirebaseUsed, isFalse);
    });

    test('checksum mismatch blocks indexing before promotion', () async {
      final previous = _InstalledPack(
        packId: 'plumbing.residential.core',
        version: '2026.07.01',
        localePackId: 'en-US',
        enabled: true,
      );
      final tampered = await _writePackFixture(packVersion: '2026.07.02');
      addTearDown(tampered.delete);
      final chunkFile = File('${tampered.directory.path}/${tampered.storagePath}');
      final decoded =
          jsonDecode(utf8.decode(gzip.decode(await chunkFile.readAsBytes())))
              as Map<String, Object?>;
      decoded['items'] = const [];
      await chunkFile.writeAsBytes(gzip.encode(utf8.encode(jsonEncode(decoded))));

      final result = await const WorkSupplyTradePackImportValidator()
          .validateDirectory(tampered.directory);
      final recovery = _recoverPackInstall(
        previous: previous,
        attempted: tampered.toAttempt(),
        validation: result,
      );

      expect(result.status, WorkSupplyTradePackValidationStatus.checksumMismatch);
      expect(recovery.indexRebuilt, isFalse);
      expect(recovery.current.version, '2026.07.01');
      expect(recovery.diagnostic, contains('checksumMismatch'));
    });

    test('duplicate install is idempotent and does not rebuild index', () async {
      final existing = _InstalledPack(
        packId: 'plumbing.residential.core',
        version: '2026.07.02',
        localePackId: 'en-US',
        enabled: true,
      );
      final duplicate = await _writePackFixture(packVersion: '2026.07.02');
      addTearDown(duplicate.delete);

      final result = await const WorkSupplyTradePackImportValidator()
          .validateDirectory(duplicate.directory);
      final recovery = _recoverPackInstall(
        previous: existing,
        attempted: duplicate.toAttempt(),
        validation: result,
      );

      expect(result.isReady, isTrue);
      expect(recovery.current, existing);
      expect(recovery.promoted, isFalse);
      expect(recovery.indexRebuilt, isFalse);
      expect(recovery.diagnostic, contains('duplicate'));
    });

    test('new valid pack promotes only after manifest and chunks pass', () async {
      final previous = _InstalledPack(
        packId: 'plumbing.residential.core',
        version: '2026.07.01',
        localePackId: 'en-US',
        enabled: true,
      );
      final next = await _writePackFixture(packVersion: '2026.07.02');
      addTearDown(next.delete);

      final result = await const WorkSupplyTradePackImportValidator()
          .validateDirectory(next.directory);
      final recovery = _recoverPackInstall(
        previous: previous,
        attempted: next.toAttempt(),
        validation: result,
      );

      expect(result.isReady, isTrue);
      expect(result.checkedChunkCount, 1);
      expect(result.checkedItemCount, 1);
      expect(recovery.current.version, '2026.07.02');
      expect(recovery.promoted, isTrue);
      expect(recovery.indexRebuilt, isTrue);
    });

    test('missing locale pack falls back conservatively to English pack', () {
      final installed = _InstalledPack(
        packId: 'plumbing.residential.core',
        version: '2026.07.02',
        localePackId: 'en-US',
        enabled: true,
      );
      final fallback = _selectLocalePack(
        requestedLocale: 'es-US',
        installed: [installed],
      );

      expect(fallback.pack, installed);
      expect(fallback.requiresReview, isTrue);
      expect(fallback.diagnostic, contains('missing locale pack'));
    });

    test('failed migration rolls back without losing previous version', () {
      final previous = _InstalledPack(
        packId: 'plumbing.residential.core',
        version: '2026.07.01',
        localePackId: 'en-US',
        enabled: true,
      );
      final attempted = _InstalledPack(
        packId: 'plumbing.residential.core',
        version: '2026.07.03',
        localePackId: 'en-US',
        enabled: false,
      );

      final recovery = _recoverMigration(
        previous: previous,
        attempted: attempted,
        migrationSucceeded: false,
      );

      expect(recovery.current, previous);
      expect(recovery.promoted, isFalse);
      expect(recovery.indexRebuilt, isFalse);
      expect(recovery.diagnostic, contains('rollback'));
    });
  });
}

Future<_PackFixture> _writePackFixture({required String packVersion}) async {
  final directory = await Directory.systemTemp.createTemp(
    'work_supply_pack_integrity_recovery_',
  );
  const chunkId = 'plumbing_residential_core_001';
  const storagePath = 'packs/plumbing/residential/core/$chunkId.json.gz';
  final payload = {
    'schemaVersion': 3,
    'packId': 'plumbing.residential.core',
    'packVersion': packVersion,
    'tradeName': 'Plumbing',
    'marketScope': 'residential',
    'tier': 'core',
    'localePackId': 'en-US',
    'countryCodes': ['US'],
    'items': [
      {
        'canonicalKey': 'plumbing|fittings|pex|90 elbows|1/2 in',
        'id': 'TEST-PEX-90',
        'name': '1/2 in PEX 90 Elbow',
        'searchTerms': ['pex', '90', 'elbow'],
        'aliases': [
          {'value': 'PEX 90', 'normalized': 'pex 90', 'source': 'test'},
        ],
      },
    ],
  };
  final jsonBytes = utf8.encode(jsonEncode(payload));
  final chunkFile = File('${directory.path}/$storagePath');
  await chunkFile.parent.create(recursive: true);
  await chunkFile.writeAsBytes(gzip.encode(jsonBytes), flush: true);
  final manifest = {
    'schemaVersion': 1,
    'packId': 'plumbing.residential.core',
    'packVersion': packVersion,
    'generatedAtIso': '2026-07-02T12:00:00.000Z',
    'tradeName': 'Plumbing',
    'marketScope': 'residential',
    'tier': 'core',
    'localePackId': 'en-US',
    'countryCodes': ['US'],
    'displayName': 'Plumbing Residential Core',
    'itemCount': 1,
    'chunkCount': 1,
    'firestoreManifestReadCount': 1,
    'firestoreItemDocumentReadCount': 0,
    'estimatedUncompressedBytes': jsonBytes.length,
    'estimatedCompressedBytes': await chunkFile.length(),
    'chunks': [
      {
        'chunkId': chunkId,
        'itemCount': 1,
        'storagePath': storagePath,
        'contentEncoding': 'gzip',
        'uncompressedByteSize': jsonBytes.length,
        'estimatedCompressedByteSize': await chunkFile.length(),
        'sha256': sha256.convert(jsonBytes).toString(),
      },
    ],
  };
  await File(
    '${directory.path}/manifest.json',
  ).writeAsString(jsonEncode(manifest), flush: true);
  return _PackFixture(
    directory: directory,
    packVersion: packVersion,
    storagePath: storagePath,
  );
}

_PackRecoveryResult _recoverPackInstall({
  required _InstalledPack previous,
  required _InstalledPack attempted,
  required WorkSupplyTradePackValidationResult validation,
}) {
  if (!validation.isReady) {
    return _PackRecoveryResult(
      current: previous,
      promoted: false,
      indexRebuilt: false,
      liveFirebaseUsed: false,
      diagnostic: 'rollback ${validation.status.name}',
    );
  }
  if (previous.packId == attempted.packId &&
      previous.version == attempted.version &&
      previous.localePackId == attempted.localePackId) {
    return _PackRecoveryResult(
      current: previous,
      promoted: false,
      indexRebuilt: false,
      liveFirebaseUsed: false,
      diagnostic: 'duplicate install ignored',
    );
  }
  return _PackRecoveryResult(
    current: attempted.copyWith(enabled: true),
    promoted: true,
    indexRebuilt: true,
    liveFirebaseUsed: false,
    diagnostic: 'promoted after manifest checksum validation',
  );
}

_PackRecoveryResult _recoverMigration({
  required _InstalledPack previous,
  required _InstalledPack attempted,
  required bool migrationSucceeded,
}) {
  if (!migrationSucceeded) {
    return _PackRecoveryResult(
      current: previous,
      promoted: false,
      indexRebuilt: false,
      liveFirebaseUsed: false,
      diagnostic: 'migration failed; rollback to previous pack',
    );
  }
  return _PackRecoveryResult(
    current: attempted.copyWith(enabled: true),
    promoted: true,
    indexRebuilt: true,
    liveFirebaseUsed: false,
    diagnostic: 'migration promoted',
  );
}

_LocalePackSelection _selectLocalePack({
  required String requestedLocale,
  required List<_InstalledPack> installed,
}) {
  final exact = installed.where((pack) => pack.localePackId == requestedLocale);
  if (exact.isNotEmpty) {
    return _LocalePackSelection(
      pack: exact.first,
      requiresReview: false,
      diagnostic: 'exact locale pack',
    );
  }
  final english = installed.firstWhere((pack) => pack.localePackId == 'en-US');
  return _LocalePackSelection(
    pack: english,
    requiresReview: true,
    diagnostic: 'missing locale pack; conservative en-US fallback',
  );
}

class _PackFixture {
  const _PackFixture({
    required this.directory,
    required this.packVersion,
    required this.storagePath,
  });

  final Directory directory;
  final String packVersion;
  final String storagePath;

  _InstalledPack toAttempt() {
    return _InstalledPack(
      packId: 'plumbing.residential.core',
      version: packVersion,
      localePackId: 'en-US',
      enabled: false,
    );
  }

  Future<void> delete() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

class _InstalledPack {
  const _InstalledPack({
    required this.packId,
    required this.version,
    required this.localePackId,
    required this.enabled,
  });

  final String packId;
  final String version;
  final String localePackId;
  final bool enabled;

  _InstalledPack copyWith({bool? enabled}) {
    return _InstalledPack(
      packId: packId,
      version: version,
      localePackId: localePackId,
      enabled: enabled ?? this.enabled,
    );
  }
}

class _PackRecoveryResult {
  const _PackRecoveryResult({
    required this.current,
    required this.promoted,
    required this.indexRebuilt,
    required this.liveFirebaseUsed,
    required this.diagnostic,
  });

  final _InstalledPack current;
  final bool promoted;
  final bool indexRebuilt;
  final bool liveFirebaseUsed;
  final String diagnostic;
}

class _LocalePackSelection {
  const _LocalePackSelection({
    required this.pack,
    required this.requiresReview,
    required this.diagnostic,
  });

  final _InstalledPack pack;
  final bool requiresReview;
  final String diagnostic;
}
