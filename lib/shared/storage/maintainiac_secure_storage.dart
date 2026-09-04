import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// One Keychain configuration for every Maintainiac secret.
///
/// The Data Protection Keychain is unsuitable for the app's local macOS debug
/// workflow because it repeatedly asks for Keychain authorization after a
/// rebuilt app changes identity. A product-specific service name also avoids
/// stale records created by older ad-hoc debug builds. The standard macOS
/// Keychain remains encrypted at rest and works with the app's stable local
/// signature.
const maintainiacSecureStorage = FlutterSecureStorage(
  mOptions: MacOsOptions(
    accountName: 'com.rbbie.maintaniac',
    usesDataProtectionKeychain: false,
  ),
);
