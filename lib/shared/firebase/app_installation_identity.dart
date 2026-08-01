import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'account_creation_gate_contract.dart';

class AppInstallationIdentity {
  const AppInstallationIdentity({
    required this.installationId,
    required this.createdAt,
  });

  final String installationId;
  final DateTime createdAt;

  /// The cloud-facing identifier. The raw random installation secret remains
  /// only in secure local storage and is never added to durable record data.
  String get installationIdSha256 =>
      sha256.convert(utf8.encode(installationId)).toString();

  Map<String, dynamic> toSignupSignalPayload() => {
    AccountCreationGateContract.appInstallationHashField: installationIdSha256,
    'installationIdVersion': AppInstallationIdentityStore.identityVersion,
    'createdAt': createdAt.toIso8601String(),
  };
}

abstract class InstallationIdentityVault {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SecureInstallationIdentityVault implements InstallationIdentityVault {
  const SecureInstallationIdentityVault({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }
}

class AppInstallationIdentityStore {
  AppInstallationIdentityStore({
    InstallationIdentityVault vault = const SecureInstallationIdentityVault(),
    DateTime Function()? now,
    String Function()? idFactory,
  }) : _vault = vault,
       _now = now ?? DateTime.now,
       _idFactory = idFactory ?? _newInstallId;

  static const identityVersion = 1;
  static const installIdKey = 'maintainiac_app_installation_id_v1';
  static const installCreatedAtKey =
      'maintainiac_app_installation_created_at_v1';
  static Future<void> _identityOperationTail = Future<void>.value();

  final InstallationIdentityVault _vault;
  final DateTime Function() _now;
  final String Function() _idFactory;

  Future<AppInstallationIdentity> getOrCreate() {
    return _serializeIdentityOperation(_getOrCreate);
  }

  Future<AppInstallationIdentity> _getOrCreate() async {
    final storedId = await _vault.read(installIdKey);
    final storedCreatedAt = await _vault.read(installCreatedAtKey);
    if (_isValidInstallId(storedId)) {
      final parsedCreatedAt = DateTime.tryParse(storedCreatedAt ?? '');
      if (parsedCreatedAt != null) {
        return AppInstallationIdentity(
          installationId: storedId!,
          createdAt: parsedCreatedAt.toUtc(),
        );
      }
      final repairedCreatedAt = _now().toUtc();
      await _vault.write(
        installCreatedAtKey,
        repairedCreatedAt.toIso8601String(),
      );
      return AppInstallationIdentity(
        installationId: storedId!,
        createdAt: repairedCreatedAt,
      );
    }

    final createdAt = _now().toUtc();
    final id = _idFactory();
    if (!_isValidInstallId(id)) {
      throw StateError('Installation identity factory returned an invalid ID.');
    }
    // The ID is the commit marker. A failed final write cannot expose a
    // partially initialized identity to the next process operation.
    await _vault.write(installCreatedAtKey, createdAt.toIso8601String());
    await _vault.write(installIdKey, id);
    return AppInstallationIdentity(installationId: id, createdAt: createdAt);
  }

  static Future<T> _serializeIdentityOperation<T>(
    Future<T> Function() operation,
  ) async {
    final previous = _identityOperationTail;
    final release = Completer<void>();
    _identityOperationTail = release.future;
    await previous;
    try {
      return await operation();
    } finally {
      release.complete();
    }
  }

  static bool _isValidInstallId(String? value) {
    if (value == null) return false;
    return RegExp(r'^mai_install_[A-Za-z0-9_-]{32,}$').hasMatch(value);
  }
}

String _newInstallId() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return 'mai_install_${base64UrlEncode(bytes).replaceAll('=', '')}';
}
