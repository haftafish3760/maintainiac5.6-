import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepted photo warning profiles stay wired into OCR handoff', () {
    final reviewWarnings = File(
      'lib/shared/widgets/receipt_capture/'
      'receipt_capture_review_result_warnings.dart',
    ).readAsStringSync();
    final ocrHandoff = File(
      'lib/shared/widgets/receipt_capture/'
      'receipt_ocr_source_handoff_review.dart',
    ).readAsStringSync();

    final acceptedProfiles = _tokensInsideMethod(
      reviewWarnings,
      methodName: 'acceptedPhotoWarningProfile',
      tokenPrefix: 'saved_photo_',
    );
    final handoffProfiles =
        _tokensInsideMethod(
              ocrHandoff,
              methodName: 'warningProfileStatus',
              tokenPrefix: 'receipt_handoff_warning_saved_photo_',
            )
            .map((token) => token.replaceFirst('receipt_handoff_warning_', ''))
            .toSet();

    expect(acceptedProfiles, isNotEmpty);
    expect(
      handoffProfiles,
      containsAll(acceptedProfiles),
      reason:
          'Every acceptedPhotoWarningProfile must survive as an OCR handoff '
          'warningProfileStatus/reviewCueStatus token.',
    );
  });

  test('saved photo parser risks stay wired into OCR handoff', () {
    final warningDetails = File(
      'lib/shared/widgets/receipt_capture/'
      'receipt_native_saved_photo_warning_details.dart',
    ).readAsStringSync();
    final ocrHandoff = File(
      'lib/shared/widgets/receipt_capture/'
      'receipt_ocr_source_handoff_review.dart',
    ).readAsStringSync();
    final diagnosticsHelpers = File(
      'lib/shared/widgets/receipt_capture/'
      'receipt_ocr_diagnostics_helpers.dart',
    ).readAsStringSync();

    final parserRisks = _tokensInsideMethod(
      warningDetails,
      methodName: 'parserRiskCode',
      tokenPrefix: 'ocr_',
    )..remove('ocr_review_if_needed');

    expect(parserRisks, isNotEmpty);
    for (final risk in parserRisks) {
      final handoffToken = 'ocr_source_parser_risk_$risk';
      expect(
        ocrHandoff,
        contains(handoffToken),
        reason: '$handoffToken must influence OCR source handoff status.',
      );
      expect(
        diagnosticsHelpers,
        contains(handoffToken),
        reason: '$handoffToken must influence parser/admin diagnostics.',
      );
    }
  });
}

Set<String> _tokensInsideMethod(
  String source, {
  required String methodName,
  required String tokenPrefix,
}) {
  final methodStart = source.indexOf(methodName);
  expect(methodStart, isNonNegative, reason: '$methodName not found');
  final methodEnd = source.indexOf('\n  }', methodStart);
  expect(methodEnd, isNonNegative, reason: '$methodName end not found');
  final body = source.substring(methodStart, methodEnd);
  return RegExp(
    "'(${RegExp.escape(tokenPrefix)}[^']+)'",
  ).allMatches(body).map((match) => match.group(1)!).toSet();
}
