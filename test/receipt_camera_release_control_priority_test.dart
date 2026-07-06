import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release-one camera controls prioritize receipt workflow over pro tools', () {
    final map = File(
      'docs/receipt_camera_completion_map.md',
    ).readAsStringSync().toLowerCase();
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraReviewSettings.kt',
    ).readAsStringSync();
    final androidLabels = File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraDiagnosticsLabels.kt',
    ).readAsStringSync();
    final ios = File(
      'ios/Runner/ReceiptCameraViewControllerControls.swift',
    ).readAsStringSync();
    final iosLabels = File(
      'ios/Runner/ReceiptCameraViewControllerLabels.swift',
    ).readAsStringSync();
    final nativeSpec = File(
      'docs/receipt_native_camera_service_spec.md',
    ).readAsStringSync().toLowerCase();
    final androidGuidance = _androidGuidanceTextBlock(androidLabels);
    final iosGuidance = _iosGuidanceTextBlock(iosLabels);
    final androidAnalysis = File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraAnalysis.kt',
    ).readAsStringSync();
    final iosReadability = File(
      'ios/Runner/ReceiptCameraViewControllerLiveReadability.swift',
    ).readAsStringSync();
    final androidDiagnostics = File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraDiagnosticsPayload.kt',
    ).readAsStringSync();
    final iosDiagnostics = File(
      'ios/Runner/ReceiptCameraViewControllerDiagnostics.swift',
    ).readAsStringSync();

    expect(map, contains('manual shutter'));
    expect(map, contains('torch when'));
    expect(map, contains('basic brightness control'));
    expect(map, contains('phone-native autofocus'));
    expect(map, contains('unproven live quality claims are default-off'));
    expect(map, contains('neutral receipt framing/readability guidance'));
    expect(map, contains('optional experimental blur/focus'));
    expect(map, contains('focus slider'));
    expect(map, contains('focus slider is not a'));
    expect(map, contains('release blocker'));
    expect(
      map,
      isNot(
        contains(
          'the app can warn about blur, glare, low light, crop/edge risk',
        ),
      ),
    );
    expect(
      map,
      isNot(contains('add blur, glare, low-light, edge, and crop contracts')),
    );
    expect(nativeSpec, contains('experimental receipt-quality guidance'));
    expect(
      nativeSpec,
      contains('default release-one guidance remains neutral'),
    );
    final expenseBlueprint = File(
      'docs/expense_release_one_blueprint.md',
    ).readAsStringSync().toLowerCase();
    expect(
      expenseBlueprint,
      contains('neutral receipt framing, crop, edge, bottom-coverage'),
    );
    expect(
      expenseBlueprint,
      contains('experimental blur, glare, low-light, shadow, dirty-lens'),
    );
    expect(
      expenseBlueprint,
      isNot(
        contains(
          'blur, glare, low-light, crop, edge, and bottom-coverage warnings',
        ),
      ),
    );
    expect(
      nativeSpec,
      isNot(
        contains(
          'to warn `Hold steady so the receipt text stays sharp`, with only motion signal/score stored in diagnostics.',
        ),
      ),
    );
    expect(android, contains('enableTorch(torchOn)'));
    expect(android, contains('Turn light on'));
    expect(ios, contains('cameraDevice.torchMode'));
    expect(ios, contains('Turn light on'));
    for (final source in [androidAnalysis, iosReadability]) {
      expect(source, contains('updateExperimentalReceiptQualityGuidance'));
      expect(source, contains('stableExperimentalReceiptQualitySignal'));
      expect(source, contains('resetExperimentalReceiptQualityCandidate'));
      expect(source, contains('Receipt has heavy shadows'));
      expect(source, contains('Lens may be smudged'));
    }
    for (final source in [androidDiagnostics, iosDiagnostics]) {
      expect(source, contains('motionBlurWarningEnabled'));
      expect(source, contains('glareWarningEnabled'));
      expect(source, contains('dirtyLensWarningEnabled'));
      expect(source, contains('lowLightWarningEnabled'));
      expect(source, contains('shadowWarningEnabled'));
      expect(source, contains('experimentalReceiptQualityCandidateSignal'));
      expect(source, contains('experimentalReceiptQualityCandidateCount'));
    }
    for (final guidance in [androidGuidance, iosGuidance]) {
      expect(guidance, contains('Fill the screen with readable receipt text'));
      expect(guidance, isNot(contains('Receipt has heavy shadows')));
      expect(guidance, isNot(contains('Lens may be smudged')));
      expect(guidance, isNot(contains('Receipt looks dark')));
      expect(guidance, isNot(contains('Receipt is very bright')));
      expect(guidance, isNot(contains('Receipt quality needs another look')));
    }
  });
}

String _androidGuidanceTextBlock(String source) {
  const startToken = 'internal fun ReceiptCameraActivity.guidanceText()';
  const endToken = 'internal fun ReceiptCameraActivity.dataSaverLabel()';
  return _sourceBlock(source, startToken, endToken);
}

String _iosGuidanceTextBlock(String source) {
  const startToken = 'func guidanceText() -> String';
  const endToken = 'func settingsStatusText() -> String';
  return _sourceBlock(source, startToken, endToken);
}

String _sourceBlock(String source, String startToken, String endToken) {
  final start = source.indexOf(startToken);
  final end = source.indexOf(endToken, start);
  expect(start, greaterThanOrEqualTo(0));
  expect(end, greaterThan(start));
  return source.substring(start, end);
}
