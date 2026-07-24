import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'maintainiac_firebase_options.dart';

class MaintainiacFirebase {
  const MaintainiacFirebase._();

  static Future<bool> initializeIfSupported() async {
    if (kIsWeb || !_isConfiguredPlatform(defaultTargetPlatform)) {
      return false;
    }

    if (Firebase.apps.isNotEmpty) {
      return true;
    }

    final options = MaintainiacFirebaseOptions.currentPlatformOrNull;
    try {
      await Firebase.initializeApp(options: options);
    } on FirebaseException {
      return false;
    } on PlatformException {
      return false;
    }
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kReleaseMode
            ? const AndroidPlayIntegrityProvider()
            : const AndroidDebugProvider(),
        providerApple: kReleaseMode
            ? const AppleAppAttestWithDeviceCheckFallbackProvider()
            : const AppleDebugProvider(),
      );
    } on FirebaseException {
      return false;
    } on PlatformException {
      return false;
    }
    return true;
  }

  static bool _isConfiguredPlatform(TargetPlatform platform) {
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }
}
