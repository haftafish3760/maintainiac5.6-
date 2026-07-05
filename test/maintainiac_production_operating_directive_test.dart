import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production directive preserves trust and regression rules', () {
    final directive = File(
      'docs/maintainiac_production_operating_directive.md',
    ).readAsStringSync();
    final projectRules = File('PROJECT_RULES.md').readAsStringSync();
    final readme = File('README.md').readAsStringSync();

    expect(
      projectRules,
      contains('docs/maintainiac_production_operating_directive.md'),
    );
    expect(
      readme,
      contains('docs/maintainiac_production_operating_directive.md'),
    );
    expect(directive, contains('Do not build on a failing analyzer'));
    expect(
      directive,
      contains('Every confirmed bug fix must include a regression test'),
    );
    expect(directive, contains('bug family'));
    expect(
      directive,
      contains('Hive/local storage is the immediate source of truth'),
    );
    expect(
      directive,
      contains('Firestore/cloud sync is a mirror or backup, not the brain'),
    );
    expect(directive, contains('User-confirmed data outranks OCR'));
    expect(
      directive,
      contains('Never overwrite user-confirmed financial data silently'),
    );
    expect(
      directive,
      contains(
        'Never store VINs, license plates, passenger data, or patient data',
      ),
    );
    expect(
      directive,
      contains('NEMT is not a separate driver type or category'),
    );
    expect(directive, contains('Do not try to out-Google Google'));
    expect(
      directive,
      contains('Google ML Kit is the primary local OCR engine'),
    );
    expect(
      directive,
      contains('temporary full-quality capture for OCR before saved proof'),
    );
    expect(
      directive,
      contains(
        'full-quality original proof retention is an explicit user choice',
      ),
    );
    expect(directive, isNot(contains('Preserve original receipt captures')));
    expect(
      directive,
      contains('Support simple and detailed receipt review modes'),
    );
    expect(
      directive,
      contains('per-line business/personal classification and line numbering'),
    );
  });
}
