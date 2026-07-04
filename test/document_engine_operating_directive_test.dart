import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Document Engine directive preserves PDF lane requirements', () {
    final directive = File(
      'docs/document_engine_operating_directive.md',
    ).readAsStringSync();
    final normalizedDirective = directive.replaceAll(RegExp(r'\s+'), ' ');

    for (final phrase in const [
      'reusable Document Engine',
      'receipt PDFs',
      'invoice PDFs',
      'estimate PDFs',
      'expense reports',
      'daily recap reports',
      'inventory reports',
      'job packets',
      'read-only',
      'never modify source records',
      'Read confirmed data only',
      'Never export OCR suggestions',
      'decimal-safe money calculations',
      'offline generation',
      'sharing, printing, and exporting',
      'deterministic output',
      'Layout engine',
      'Table renderer',
      'Header renderer',
      'Footer renderer',
      'Pagination engine',
      'Image renderer',
      'Typography system',
      'Currency formatter',
      'Date formatter',
      'Export manager',
      'Receipt image embedding',
      'Golden snapshot tests',
      'PDF-to-receipt review transfer',
      'No private text in logs',
      'VINs',
      'License plates',
      'Passenger data',
      'Patient information',
      'Internal IDs unless explicitly required',
      'Stop on any failing analyze',
      'Fix failures properly before continuing',
    ]) {
      expect(
        normalizedDirective,
        contains(phrase),
        reason: 'Missing directive: $phrase',
      );
    }

    expect(normalizedDirective, contains('not a generic PDF generator'));
    expect(normalizedDirective, contains('not a generic PDF viewer'));
  });
}
