import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firebase_options.dart';

void main() {
  group('Firebase mobile configuration', () {
    test(
      'Android identifiers are stable and local Firebase JSON is optional',
      () {
        final buildGradle = File(
          'android/app/build.gradle.kts',
        ).readAsStringSync();
        final mainActivity = File(
          'android/app/src/main/kotlin/com/maintainiac/MainActivity.kt',
        ).readAsStringSync();
        expect(buildGradle, contains('namespace = "com.maintainiac"'));
        expect(buildGradle, contains('applicationId = "com.maintainiac"'));
        expect(mainActivity, contains('package com.maintainiac'));
        expect(
          buildGradle,
          contains('if (file("google-services.json").exists())'),
        );
        final configFile = File('android/app/google-services.json');
        if (!configFile.existsSync()) return;
        final googleServices =
            jsonDecode(configFile.readAsStringSync()) as Map<String, Object?>;
        final client =
            (googleServices['client'] as List<Object?>).single
                as Map<String, Object?>;
        final clientInfo = client['client_info'] as Map<String, Object?>;
        final androidInfo =
            clientInfo['android_client_info'] as Map<String, Object?>;
        expect(androidInfo['package_name'], 'com.maintainiac');
        expect(clientInfo['mobilesdk_app_id'], isNotEmpty);
        expect(googleServices.projectId, isNotEmpty);
      },
    );

    test('iOS identifiers are stable and local Firebase plist is optional', () {
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      final shareController = File(
        'ios/ShareExtension/ShareViewController.swift',
      ).readAsStringSync();

      expect(project, contains('PRODUCT_BUNDLE_IDENTIFIER = com.maintainiac;'));
      expect(
        project,
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.maintainiac.ShareExtension;'),
      );
      expect(project, contains('CUSTOM_GROUP_ID = group.com.maintainiac;'));
      expect(project, isNot(contains('GoogleService-Info.plist in Resources')));
      expect(project, contains('Copy Optional Firebase Configuration'));
      expect(
        project,
        contains(
          'No local Firebase configuration; hosted Firebase remains disabled.',
        ),
      );
      expect(shareController, contains('com.maintainiac.ShareExtension'));
      final configFile = File('ios/Runner/GoogleService-Info.plist');
      if (!configFile.existsSync()) return;
      final plist = configFile.readAsStringSync();
      expect(plist, contains('<string>com.maintainiac</string>'));
    });

    test(
      'clean checkout keeps Firebase disabled without build configuration',
      () {
        expect(MaintainiacFirebaseOptions.currentPlatformOrNull, isNull);
        final source = File(
          'lib/shared/firebase/maintainiac_firebase_options.dart',
        ).readAsStringSync();
        expect(source, contains('String.fromEnvironment'));
        expect(source, contains('MAINTAINIAC_FIREBASE_ANDROID_APP_ID'));
        expect(source, contains('MAINTAINIAC_FIREBASE_IOS_APP_ID'));
        final initializer = File(
          'lib/shared/firebase/maintainiac_firebase.dart',
        ).readAsStringSync();
        expect(
          initializer,
          contains('Firebase.initializeApp(options: options)'),
        );
        expect(
          initializer,
          isNot(contains('if (options == null) return false')),
        );
      },
    );

    test(
      'App Check is initialized with release device attestation providers',
      () {
        final pubspec = File('pubspec.yaml').readAsStringSync();
        final initializer = File(
          'lib/shared/firebase/maintainiac_firebase.dart',
        ).readAsStringSync();

        expect(pubspec, contains('firebase_app_check:'));
        expect(initializer, contains('FirebaseAppCheck.instance.activate'));
        expect(initializer, contains('AndroidPlayIntegrityProvider'));
        expect(
          initializer,
          contains('AppleAppAttestWithDeviceCheckFallbackProvider'),
        );
        expect(initializer, contains('AndroidDebugProvider'));
        expect(initializer, contains('AppleDebugProvider'));
        expect(initializer, contains('kReleaseMode'));
      },
    );

    test('hosted auth dependencies are Google and Apple only', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final policy = File(
        'lib/shared/firebase/maintainiac_auth_policy.dart',
      ).readAsStringSync();
      final service = File(
        'lib/shared/firebase/maintainiac_auth_service.dart',
      ).readAsStringSync();

      expect(pubspec, contains('firebase_auth:'));
      expect(pubspec, contains('google_sign_in:'));
      expect(pubspec, contains('sign_in_with_apple:'));
      expect(policy, contains('google.com'));
      expect(policy, contains('apple.com'));
      expect(policy, contains("'password'"));
      expect(policy, contains("'phone'"));
      expect(policy, contains("'anonymous'"));
      expect(policy, contains("'emailLink'"));
      expect(service, contains('GoogleSignIn.instance'));
      expect(service, contains('.initialize()'));
      expect(service, contains('supportsAuthenticate'));
      expect(service, isNot(contains('signInWithEmailAndPassword')));
      expect(service, isNot(contains('signInAnonymously')));
      expect(service, isNot(contains('verifyPhoneNumber')));
    });

    test('account creation gate uses secure install identity signals', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final identity = File(
        'lib/shared/firebase/app_installation_identity.dart',
      ).readAsStringSync();
      final contract = File(
        'lib/shared/firebase/account_creation_gate_contract.dart',
      ).readAsStringSync();

      expect(pubspec, contains('flutter_secure_storage:'));
      expect(identity, contains('FlutterSecureStorage'));
      expect(identity, contains('maintainiac_app_installation_id_v1'));
      expect(identity, contains('mai_install_'));
      expect(contract, contains('requestHostedAccountCreation'));
      expect(contract, contains('beforeCreateAccountGate'));
      expect(contract, contains('accountAbuseInstalls'));
      expect(contract, contains('accountAbuseIpWindows'));
    });

    test('iOS app target has Sign in with Apple entitlement', () {
      final entitlements = File(
        'ios/Runner/Runner.entitlements',
      ).readAsStringSync();

      expect(entitlements, contains('com.apple.developer.applesignin'));
      expect(entitlements, contains('<string>Default</string>'));
    });

    test('Firestore rules include employee invite security state', () {
      final rules = File('firestore.rules').readAsStringSync();

      expect(rules, contains('match /invites/{inviteId}'));
      expect(rules, contains('invitedByUid == request.auth.uid'));
      expect(
        rules,
        contains('resource.data.email == request.auth.token.email'),
      );
      expect(rules, contains('allow delete: if false;'));
    });

    test('Firestore rules keep account abuse counters server-only', () {
      final rules = File('firestore.rules').readAsStringSync();

      expect(rules, contains('match /abuseSignals/{signalId}'));
      expect(rules, contains('match /accountAbuseInstalls/{installId}'));
      expect(rules, contains('match /accountAbuseIpWindows/{ipWindowId}'));
      expect(rules, contains('match /accountCreationReviews/{reviewId}'));
      expect(rules, contains('allow read, write: if false;'));
    });

    test('Firebase emulator harness is demo-only and has no deploy script', () {
      final firebaseRc = File('.firebaserc').readAsStringSync();
      final packageJson = File(
        'firebase_emulator_tests/package.json',
      ).readAsStringSync();
      final guard = File(
        'firebase_emulator_tests/test/emulatorGuard.mjs',
      ).readAsStringSync();
      final runner = File(
        'tool/run_firebase_emulator_tests.sh',
      ).readAsStringSync();

      expect(firebaseRc, contains('demo-maintainiac-rules-test'));
      expect(packageJson, contains('firebase emulators:exec'));
      expect(packageJson, isNot(contains('firebase deploy')));
      expect(guard, contains('assertEmulatorOnly'));
      expect(guard, contains('FIRESTORE_EMULATOR_HOST'));
      expect(runner, contains(r'--project "$PROJECT_ID"'));
      expect(runner, contains('--only firestore'));
    });

    test('tracked files do not contain server-side API secrets', () {
      final files = Process.runSync('git', [
        'ls-files',
      ], workingDirectory: Directory.current.path);
      expect(files.exitCode, 0);

      final trackedFiles = (files.stdout as String)
          .split('\n')
          .where((path) => path.trim().isNotEmpty)
          .where(
            (path) =>
                path != '.gitignore' &&
                path != 'test/firebase_configuration_test.dart' &&
                !path.startsWith('test/support/') &&
                !path.endsWith('package-lock.json'),
          )
          .where((path) => File(path).existsSync());
      final forbidden = RegExp(
        [
          r'-----BEGIN (?:RSA |EC |OPENSSH |PRIVATE )?KEY-----',
          '"private_" "key"',
          "'private_' 'key'",
          r'sk-[A-Za-z0-9_-]{20,}',
          r'ya29\.',
          r'github_pat_',
          r'ghp_[A-Za-z0-9_]{20,}',
          r'xox[baprs]-',
        ].join('|'),
        caseSensitive: false,
      );
      final offenders = <String>[];

      for (final path in trackedFiles) {
        final file = File(path);
        if (file.lengthSync() > 1024 * 1024) continue;
        String content;
        try {
          content = file.readAsStringSync();
        } catch (_) {
          continue;
        }
        if (forbidden.hasMatch(content)) offenders.add(path);
      }

      expect(offenders, isEmpty);
    });
  });
}

extension _GoogleServicesMap on Map<String, Object?> {
  String get projectId {
    final projectInfo = this['project_info'] as Map<String, Object?>;
    return projectInfo['project_id'] as String;
  }
}
