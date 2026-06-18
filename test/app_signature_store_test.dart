import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/signatures/app_signature_models.dart';
import 'package:maintaniac/shared/signatures/app_signature_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'app_signature_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('saves and reloads the app user signature locally', () async {
    final store = await AppSignatureStore.createForTesting(
      encryptionKey: List<int>.filled(32, 7),
    );
    final signature = _signature(AppSignatureRole.owner);

    await store.saveOwnerSignature(signature);
    await Hive.close();
    Hive.init(hiveDirectory.path);

    final reloaded = await AppSignatureStore.createForTesting(
      encryptionKey: List<int>.filled(32, 7),
    );

    expect(reloaded.ownerSignature, isNotNull);
    expect(reloaded.ownerSignature!.role, AppSignatureRole.owner);
    expect(reloaded.ownerSignature!.hasInk, isTrue);
    expect(reloaded.ownerSignature!.strokes.single.points.last.dx, 24);
  });

  test('does not allow customer signatures to be saved globally', () async {
    final store = await AppSignatureStore.createForTesting(
      encryptionKey: List<int>.filled(32, 8),
    );

    expect(
      () => store.saveOwnerSignature(_signature(AppSignatureRole.customer)),
      throwsArgumentError,
    );
    expect(store.ownerSignature, isNull);
  });

  test('clears only the saved owner signature', () async {
    final store = await AppSignatureStore.createForTesting(
      encryptionKey: List<int>.filled(32, 9),
    );

    await store.saveOwnerSignature(_signature(AppSignatureRole.owner));
    expect(store.hasOwnerSignature, isTrue);

    await store.clearOwnerSignature();

    expect(store.hasOwnerSignature, isFalse);
    expect(store.ownerSignature, isNull);
  });

  test(
    'does not crash or persist when secure signature storage is unavailable',
    () async {
      final store = await AppSignatureStore.createForTesting(
        canPersistOwnerSignature: false,
      );

      await store.saveOwnerSignature(_signature(AppSignatureRole.owner));

      expect(store.canPersistOwnerSignature, isFalse);
      expect(store.hasOwnerSignature, isFalse);
      expect(store.ownerSignature, isNull);
    },
  );
}

AppSignatureResult _signature(AppSignatureRole role) {
  return AppSignatureResult(
    role: role,
    signedAt: DateTime(2026, 6, 15, 10, 30),
    strokes: const [
      AppSignatureStroke([Offset(4, 5), Offset(14, 15), Offset(24, 25)]),
    ],
  );
}
