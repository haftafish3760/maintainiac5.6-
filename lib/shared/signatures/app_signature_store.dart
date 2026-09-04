import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app_signature_models.dart';
import '../storage/maintainiac_secure_storage.dart';

class AppSignatureStore extends ChangeNotifier {
  AppSignatureStore._(this._box, {required this.canPersistOwnerSignature});

  static const boxName = 'app_signature_store';
  static const unavailableBoxName = 'app_signature_store_unavailable';
  static const _ownerSignatureKey = 'owner_signature';
  static const _encryptionKeyName = 'maintainiac_owner_signature_box_key';

  final Box<dynamic> _box;
  final bool canPersistOwnerSignature;

  static Future<AppSignatureStore> create() async {
    try {
      final encryptionKey = await _loadOrCreateEncryptionKey(
        maintainiacSecureStorage,
      );
      final box = await Hive.openBox<dynamic>(
        boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
      return AppSignatureStore._(box, canPersistOwnerSignature: true);
    } on MissingPluginException {
      return _createUnavailable();
    } on PlatformException {
      return _createUnavailable();
    }
  }

  static Future<AppSignatureStore> createForTesting({
    List<int>? encryptionKey,
    bool canPersistOwnerSignature = true,
  }) async {
    final box = await Hive.openBox<dynamic>(
      boxName,
      encryptionCipher: encryptionKey == null
          ? null
          : HiveAesCipher(encryptionKey),
    );
    return AppSignatureStore._(
      box,
      canPersistOwnerSignature: canPersistOwnerSignature,
    );
  }

  AppSignatureResult? get ownerSignature {
    if (!canPersistOwnerSignature) return null;
    final signature = appSignatureFromMap(_box.get(_ownerSignatureKey));
    if (signature?.role != AppSignatureRole.owner) return null;
    return signature;
  }

  bool get hasOwnerSignature => ownerSignature?.hasInk ?? false;

  Future<void> saveOwnerSignature(AppSignatureResult signature) async {
    if (signature.role != AppSignatureRole.owner) {
      throw ArgumentError('Only the app user signature can be saved globally.');
    }
    if (!canPersistOwnerSignature) return;
    if (!signature.hasInk) return;
    await _box.put(_ownerSignatureKey, appSignatureToMap(signature));
    notifyListeners();
  }

  Future<void> clearOwnerSignature() async {
    if (!canPersistOwnerSignature) return;
    await _box.delete(_ownerSignatureKey);
    notifyListeners();
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

  static Future<AppSignatureStore> _createUnavailable() async {
    final box = await Hive.openBox<dynamic>(unavailableBoxName);
    return AppSignatureStore._(box, canPersistOwnerSignature: false);
  }
}

class AppSignatureStoreScope extends InheritedNotifier<AppSignatureStore> {
  const AppSignatureStoreScope({
    super.key,
    required AppSignatureStore store,
    required super.child,
  }) : super(notifier: store);

  static AppSignatureStore of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppSignatureStoreScope>();
    assert(scope != null, 'AppSignatureStoreScope is missing.');
    return scope!.notifier!;
  }

  static AppSignatureStore? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppSignatureStoreScope>()
        ?.notifier;
  }
}
