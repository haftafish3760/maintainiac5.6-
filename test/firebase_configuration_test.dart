import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/firebase_options.dart';

void main() {
  group('Firebase mobile configuration', () {
    test('Android app id, namespace, Kotlin package, and Firebase JSON match', () {
      final buildGradle = File('android/app/build.gradle.kts').readAsStringSync();
      final mainActivity = File(
        'android/app/src/main/kotlin/com/maintainiac/MainActivity.kt',
      ).readAsStringSync();
      final googleServices = jsonDecode(
        File('android/app/google-services.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final client = (googleServices['client'] as List<Object?>).single
          as Map<String, Object?>;
      final clientInfo = client['client_info'] as Map<String, Object?>;
      final androidInfo =
          clientInfo['android_client_info'] as Map<String, Object?>;

      expect(buildGradle, contains('namespace = "com.maintainiac"'));
      expect(buildGradle, contains('applicationId = "com.maintainiac"'));
      expect(mainActivity, contains('package com.maintainiac'));
      expect(androidInfo['package_name'], 'com.maintainiac');
      expect(clientInfo['mobilesdk_app_id'], DefaultFirebaseOptions.android.appId);
      expect(
        googleServices.projectId,
        DefaultFirebaseOptions.android.projectId,
      );
    });

    test('iOS bundle ids, app group, plist, and Dart options match', () {
      final project = File('ios/Runner.xcodeproj/project.pbxproj')
          .readAsStringSync();
      final plist = File('ios/Runner/GoogleService-Info.plist')
          .readAsStringSync();
      final shareController = File('ios/ShareExtension/ShareViewController.swift')
          .readAsStringSync();

      expect(project, contains('PRODUCT_BUNDLE_IDENTIFIER = com.maintainiac;'));
      expect(
        project,
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.maintainiac.ShareExtension;'),
      );
      expect(project, contains('CUSTOM_GROUP_ID = group.com.maintainiac;'));
      expect(project, contains('GoogleService-Info.plist in Resources'));
      expect(plist, contains('<string>com.maintainiac</string>'));
      expect(plist, contains(DefaultFirebaseOptions.ios.appId));
      expect(plist, contains(DefaultFirebaseOptions.ios.projectId));
      expect(shareController, contains('com.maintainiac.ShareExtension'));
      expect(DefaultFirebaseOptions.ios.iosBundleId, 'com.maintainiac');
    });
  });
}

extension _GoogleServicesMap on Map<String, Object?> {
  String get projectId {
    final projectInfo = this['project_info'] as Map<String, Object?>;
    return projectInfo['project_id'] as String;
  }
}
