import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('QA fingerprint is stable across file order and line endings', () {
    const builder = MaintainiacQaFingerprintBuilder();

    final first = builder.signatureFor(
      label: 'inventory-core-fixtures',
      files: const [
        MaintainiacQaSourceFile(
          path: 'test/fixtures/work_supply_parser/golden_fixtures.json',
          content: 'PVC EL 3/4\r\nPEX CRMP 90 1/2\r\n',
        ),
        MaintainiacQaSourceFile(
          path: 'test/work_supply_parser_generated_fixture_runner_test.dart',
          content: 'test("generated fixtures", () {});\n',
        ),
      ],
    );
    final second = builder.signatureFor(
      label: 'inventory-core-fixtures',
      files: const [
        MaintainiacQaSourceFile(
          path: 'test/work_supply_parser_generated_fixture_runner_test.dart',
          content: 'test("generated fixtures", () {});\n',
        ),
        MaintainiacQaSourceFile(
          path: 'test/fixtures/work_supply_parser/golden_fixtures.json',
          content: 'PVC EL 3/4\nPEX CRMP 90 1/2\n',
        ),
      ],
    );

    expect(first, second);
  });

  test('QA fingerprint changes when fixture content changes', () {
    const builder = MaintainiacQaFingerprintBuilder();

    final before = builder.signatureFor(
      label: 'expense-receipts',
      files: const [
        MaintainiacQaSourceFile(
          path: 'test/fixtures/expenses/gas_receipts.json',
          content: 'subtotal 10.00\ntax 0.60\ntotal 10.60\n',
        ),
      ],
    );
    final after = builder.signatureFor(
      label: 'expense-receipts',
      files: const [
        MaintainiacQaSourceFile(
          path: 'test/fixtures/expenses/gas_receipts.json',
          content: 'subtotal 11.00\ntax 0.66\ntotal 11.66\n',
        ),
      ],
    );

    expect(before, isNot(after));
  });

  test('QA fingerprint rejects unlabeled and unnormalized evidence', () {
    const builder = MaintainiacQaFingerprintBuilder();

    expect(
      () => builder.signatureFor(label: '', files: const []),
      throwsArgumentError,
    );
    expect(
      () => builder.signatureFor(
        label: 'bad-path',
        files: const [
          MaintainiacQaSourceFile(
            path: r'test\bad_fixture.json',
            content: '{}',
          ),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('QA fingerprint rejects duplicate source paths', () {
    const builder = MaintainiacQaFingerprintBuilder();

    expect(
      () => builder.signatureFor(
        label: 'duplicate-fixtures',
        files: const [
          MaintainiacQaSourceFile(
            path: 'test/fixtures/expenses/gas_receipts.json',
            content: 'total 10.00',
          ),
          MaintainiacQaSourceFile(
            path: 'test/fixtures/expenses/gas_receipts.json',
            content: 'total 11.00',
          ),
        ],
      ),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains(
            'duplicate-fixtures has duplicate source path '
            'test/fixtures/expenses/gas_receipts.json',
          ),
        ),
      ),
    );
  });
}
