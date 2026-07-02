part of 'receipt_qa_runner.dart';

void _addPrivacyAdminIssues({
  required _ReceiptQaFixture fixture,
  required ExpenseReceiptParseResult parsed,
  required List<String> issues,
}) {
  final summary = _privacyAdminSummary(fixture.text);
  if (fixture.expectedSensitiveLineCount != null &&
      summary.sensitiveLineCount != fixture.expectedSensitiveLineCount) {
    issues.add('privacy_admin_sensitive_line_count_mismatch');
  }
  if (fixture.expectedTenderPrivacyLineCount != null &&
      summary.tenderPrivacyLineCount !=
          fixture.expectedTenderPrivacyLineCount) {
    issues.add('privacy_admin_tender_line_count_mismatch');
  }
  if (fixture.expectedAddressContactLineCount != null &&
      summary.addressContactLineCount !=
          fixture.expectedAddressContactLineCount) {
    issues.add('privacy_admin_address_contact_count_mismatch');
  }
  if (fixture.expectedPrivateNameLineCount != null &&
      summary.privateNameLineCount != fixture.expectedPrivateNameLineCount) {
    issues.add('privacy_admin_private_name_count_mismatch');
  }
  if (!_sensitiveNeedlesExcluded(fixture, parsed)) {
    issues.add('privacy_admin_sensitive_needles_reached_purchase_lines');
  }
}

void _addPrivacyAdminChecks({
  required _ReceiptQaFixture fixture,
  required ExpenseReceiptParseResult parsed,
  required List<_ReceiptQaCheck> checks,
}) {
  final summary = _privacyAdminSummary(fixture.text);

  void addCheck(String name, bool passed) {
    checks.add(
      _ReceiptQaCheck(dimension: 'privacy_admin', name: name, passed: passed),
    );
  }

  if (fixture.expectedSensitiveLineCount != null) {
    addCheck(
      'sensitive_line_count_matched',
      summary.sensitiveLineCount == fixture.expectedSensitiveLineCount,
    );
  }
  if (fixture.expectedTenderPrivacyLineCount != null) {
    addCheck(
      'tender_privacy_line_count_matched',
      summary.tenderPrivacyLineCount == fixture.expectedTenderPrivacyLineCount,
    );
  }
  if (fixture.expectedAddressContactLineCount != null) {
    addCheck(
      'address_contact_line_count_matched',
      summary.addressContactLineCount ==
          fixture.expectedAddressContactLineCount,
    );
  }
  if (fixture.expectedPrivateNameLineCount != null) {
    addCheck(
      'private_name_line_count_matched',
      summary.privateNameLineCount == fixture.expectedPrivateNameLineCount,
    );
  }
  if (fixture.expectedSensitiveNeedlesExcluded.isNotEmpty) {
    addCheck(
      'sensitive_needles_excluded_from_purchase_lines',
      _sensitiveNeedlesExcluded(fixture, parsed),
    );
  }
}

bool _sensitiveNeedlesExcluded(
  _ReceiptQaFixture fixture,
  ExpenseReceiptParseResult parsed,
) {
  final purchaseText = parsed.lines
      .map((line) => line.description.toUpperCase())
      .join('\n');
  return fixture.expectedSensitiveNeedlesExcluded.every((needle) {
    return !purchaseText.contains(needle.toUpperCase());
  });
}

_PrivacyAdminSummary _privacyAdminSummary(String text) {
  final lines = text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  var tender = 0;
  var addressContact = 0;
  var privateName = 0;
  for (final line in lines) {
    if (_looksLikeTenderPrivacyLine(line)) tender++;
    if (_looksLikeAddressContactLine(line)) addressContact++;
    if (_looksLikePrivateNameLine(line)) privateName++;
  }
  return _PrivacyAdminSummary(
    tenderPrivacyLineCount: tender,
    addressContactLineCount: addressContact,
    privateNameLineCount: privateName,
  );
}

bool _looksLikeTenderPrivacyLine(String line) {
  final upper = line.toUpperCase();
  return upper.contains('AUTH') ||
      upper.contains('TRACE') ||
      upper.contains('CARD') ||
      upper.contains('VISA') ||
      upper.contains('MASTERCARD') ||
      upper.contains('FLEET');
}

bool _looksLikeAddressContactLine(String line) {
  final upper = line.toUpperCase();
  final hasPhone = RegExp(r'\(?\d{3}\)?[- ]\d{3}[- ]\d{4}').hasMatch(line);
  final hasZip = RegExp(r'\b\d{5}(?:-\d{4})?\b').hasMatch(line);
  final hasState = RegExp(r'\b[A-Z]{2}\b').hasMatch(upper);
  final hasAddressWord = RegExp(
    r'\b(ST|STREET|RD|ROAD|AVE|AUSTIN|TX|CITY)\b',
  ).hasMatch(upper);
  return hasPhone || (hasZip && hasState) || (hasZip && hasAddressWord);
}

bool _looksLikePrivateNameLine(String line) {
  final upper = line.toUpperCase();
  return RegExp(r'\b(CUSTOMER|MEMBER|LOYALTY)\b').hasMatch(upper) &&
      !RegExp(r'\d+[.,]\d{2}\b').hasMatch(line);
}

class _PrivacyAdminSummary {
  const _PrivacyAdminSummary({
    required this.tenderPrivacyLineCount,
    required this.addressContactLineCount,
    required this.privateNameLineCount,
  });

  final int tenderPrivacyLineCount;
  final int addressContactLineCount;
  final int privateNameLineCount;

  int get sensitiveLineCount {
    return tenderPrivacyLineCount +
        addressContactLineCount +
        privateNameLineCount;
  }
}
