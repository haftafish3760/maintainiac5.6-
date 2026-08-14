import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('maintainiac/receipt_stitch_registration');

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('platform proposal rejects weak or malformed registration', () {
    final proposal = ReceiptNativeRegistrationProposal.fromPlatform({
      'pairIndex': 0,
      'scale': 1.0,
      'rotationDegrees': 0.0,
      'confidence': .9,
      'inlierCount': 2,
      'reprojectionError': 1.0,
      'anchors': const <Object?>[],
    });

    expect(proposal.isUsable, isFalse);
  });

  test('platform proposal rejects non-finite native anchors', () {
    final proposal = ReceiptNativeRegistrationProposal.fromPlatform({
      'pairIndex': 0,
      'scale': 1.0,
      'rotationDegrees': 0.0,
      'confidence': .9,
      'inlierCount': 8,
      'reprojectionError': 1.0,
      'anchors': [
        for (var index = 0; index < 6; index++)
          {
            'previousX': index == 3 ? double.nan : .2 + index * .1,
            'previousY': .72 + index * .02,
            'nextX': .2 + index * .1,
            'nextY': .02 + index * .02,
          },
      ],
    });

    expect(proposal.isUsable, isFalse);
  });

  test('platform proposal keeps bounded RANSAC anchors', () {
    final anchors = <Map<String, double>>[
      for (var index = 0; index < 6; index++)
        {
          'previousX': .2 + index * .1,
          'previousY': .72 + index * .02,
          'nextX': .2 + index * .1,
          'nextY': .02 + index * .02,
        },
    ];
    final proposal = ReceiptNativeRegistrationProposal.fromPlatform({
      'pairIndex': 1,
      'scale': 1.04,
      'rotationDegrees': -.8,
      'confidence': .82,
      'inlierCount': 8,
      'reprojectionError': 1.4,
      'anchors': anchors,
    });

    expect(proposal.isUsable, isTrue);
    expect(proposal.pairIndex, 1);
    expect(proposal.anchors, hasLength(6));
    expect(proposal.anchors.first.previousY, closeTo(.72, .0001));
  });

  test('Android packages OpenCV with one shared C++ runtime', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, contains('implementation("org.opencv:opencv:4.14.0")'));
    expect(gradle, contains('pickFirsts += "**/libc++_shared.so"'));
  });

  test('Android cancellation is scoped to the timed-out request', () {
    final source = File(
      'android/app/src/main/kotlin/com/maintainiac/'
      'ReceiptStitchRegistrationBridge.kt',
    ).readAsStringSync();

    expect(source, contains('pendingClientRequestId'));
    expect(source, contains('expectedClientRequestId'));
    expect(
      source,
      contains('pendingClientRequestId != expectedClientRequestId'),
    );
  });

  test(
    'native proposal work is bounded without changing reviewed paths',
    () async {
      List<String>? sentPaths;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            sentPaths = List<String>.from(
              (call.arguments as Map<Object?, Object?>)['paths']! as List,
            );
            return const <Object?>[];
          });
      final reviewedPaths = [
        for (var index = 0; index < 20; index++) '/$index',
      ];

      final proposals = await const ReceiptNativeStitchRegistration().propose(
        paths: reviewedPaths,
        comparisonWidth: 320,
      );

      expect(proposals, isEmpty);
      expect(sentPaths, reviewedPaths.take(13));
      expect(reviewedPaths, hasLength(20));
    },
  );

  test('a timed-out native proposal sends cancellation', () async {
    final proposalStarted = Completer<void>();
    final proposalResult = Completer<List<Object?>>();
    final cancellationReceived = Completer<void>();
    int? proposalRequestId;
    int? cancelledRequestId;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'cancelProposals') {
            cancelledRequestId =
                (call.arguments as Map<Object?, Object?>)['requestId']! as int;
            if (!cancellationReceived.isCompleted) {
              cancellationReceived.complete();
            }
            if (!proposalResult.isCompleted) proposalResult.complete(const []);
            return null;
          }
          proposalRequestId =
              (call.arguments as Map<Object?, Object?>)['requestId']! as int;
          if (!proposalStarted.isCompleted) proposalStarted.complete();
          return proposalResult.future;
        });

    final proposals = await const ReceiptNativeStitchRegistration().propose(
      paths: const ['/top', '/bottom'],
      comparisonWidth: 240,
    );
    await proposalStarted.future;
    await cancellationReceived.future.timeout(const Duration(seconds: 1));

    expect(proposals, isEmpty);
    expect(cancelledRequestId, proposalRequestId);
  });
}
