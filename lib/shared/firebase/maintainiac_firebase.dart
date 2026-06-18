import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class MaintainiacFirebase {
  const MaintainiacFirebase._();

  static Future<bool> initializeIfSupported() async {
    if (kIsWeb || !_isConfiguredPlatform(defaultTargetPlatform)) {
      return false;
    }

    if (Firebase.apps.isNotEmpty) {
      return true;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  }

  static bool _isConfiguredPlatform(TargetPlatform platform) {
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }
}
