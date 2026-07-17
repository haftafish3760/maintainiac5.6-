import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppInstallationIdentity {
  const AppInstallationIdentity({
    required this.installationId,
    required this.createdAt,
  });

  final String installationId;
  final DateTime createdAt;

  Map<String, dynamic> toSignupSignalPayload() => {
    'appInstallationId': installationId,
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

  final InstallationIdentityVault _vault;
  final DateTime Function() _now;
  final String Function() _idFactory;

  Future<AppInstallationIdentity> getOrCreate() async {
    final storedId = await _vault.read(installIdKey);
    final storedCreatedAt = await _vault.read(installCreatedAtKey);
    if (_isValidInstallId(storedId) && storedCreatedAt != null) {
      return AppInstallationIdentity(
        installationId: storedId!,
        createdAt:
            DateTime.tryParse(storedCreatedAt)?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    }

    final createdAt = _now().toUtc();
    final id = _idFactory();
    await _vault.write(installIdKey, id);
    await _vault.write(installCreatedAtKey, createdAt.toIso8601String());
    return AppInstallationIdentity(installationId: id, createdAt: createdAt);
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
