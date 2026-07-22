import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Build-safe Firebase configuration.
///
/// Secrets and project identifiers are supplied at build time. A clean source
/// checkout intentionally leaves Firebase disabled instead of committing
/// machine-local Google configuration files or failing to compile.
class MaintainiacFirebaseOptions {
  const MaintainiacFirebaseOptions._();

  static FirebaseOptions? get currentPlatformOrNull {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _android,
      TargetPlatform.iOS => _ios,
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.fuchsia => null,
    };
  }

  static FirebaseOptions? get _android => _configuredOptions(
    appId: const String.fromEnvironment('MAINTAINIAC_FIREBASE_ANDROID_APP_ID'),
  );

  static FirebaseOptions? get _ios => _configuredOptions(
    appId: const String.fromEnvironment('MAINTAINIAC_FIREBASE_IOS_APP_ID'),
    iosBundleId: 'com.maintainiac',
  );

  static FirebaseOptions? _configuredOptions({
    required String appId,
    String? iosBundleId,
  }) {
    const apiKey = String.fromEnvironment('MAINTAINIAC_FIREBASE_API_KEY');
    const messagingSenderId = String.fromEnvironment(
      'MAINTAINIAC_FIREBASE_MESSAGING_SENDER_ID',
    );
    const projectId = String.fromEnvironment('MAINTAINIAC_FIREBASE_PROJECT_ID');
    const storageBucket = String.fromEnvironment(
      'MAINTAINIAC_FIREBASE_STORAGE_BUCKET',
    );
    if ([
      apiKey,
      appId,
      messagingSenderId,
      projectId,
    ].any((value) => value.trim().isEmpty)) {
      return null;
    }
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket.trim().isEmpty ? null : storageBucket,
      iosBundleId: iosBundleId,
    );
  }
}
