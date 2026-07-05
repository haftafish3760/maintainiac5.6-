import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Document Engine directive preserves PDF requirements', () {
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
      'Shared receipt proof flow for expenses, inventory/material receipts',
      'without changing parser, OCR, inventory, or expense classification logic',
      'Portrait, landscape, mixed-orientation, rotated, and cropped receipt pages',
      'Golden snapshot tests',
      'PDF-to-receipt review transfer',
      'No private text in logs',
      'VINs',
      'License plates',
      'Passenger data',
      'Patient information',
      'Internal IDs unless explicitly required',
      'Support And Debugging Privacy Boundary',
      'The owner/developer must not see raw user PDFs',
      'Human-visible support surfaces may show only non-identifying operational evidence',
      'Codex may inspect user-provided PDFs or extracted text only when that access is required',
      'Codex must not store, publish, quote, train on, summarize for unrelated use',
      'regression created from a real issue must use synthetic or redacted fixtures',
      'Command 1 may monitor PDF health and failure patterns',
      'must not become a private PDF viewer for the owner',
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
