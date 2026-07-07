import 'dart:io';

const _defaultLedgerPath = 'docs/receipt_bug_regression_ledger.md';
const _defaultArchivePath =
    'docs/receipt_bug_regression_ledger_archive_0001.md';
const _defaultKeepRows = 120;

void main(List<String> args) {
  final ledgerPath = _option(args, 'ledger') ?? _defaultLedgerPath;
  final archivePath = _option(args, 'archive') ?? _defaultArchivePath;
  final keepRows =
      int.tryParse(_option(args, 'keep') ?? '') ?? _defaultKeepRows;
  if (keepRows < 1) {
    stderr.writeln('keep must be greater than zero.');
    exitCode = 64;
    return;
  }

  final ledgerFile = File(ledgerPath);
  if (!ledgerFile.existsSync()) {
    stderr.writeln('Missing ledger: $ledgerPath');
    exitCode = 66;
    return;
  }

  final parsed = _parseLedger(ledgerFile.readAsStringSync());
  if (parsed.rows.length <= keepRows) {
    stdout.writeln(
      'Receipt bug ledger archive: rows=${parsed.rows.length} keep=$keepRows '
      'nothing to archive.',
    );
    return;
  }

  final keptRows = parsed.rows.take(keepRows).toList(growable: false);
  final archivedRows = parsed.rows.skip(keepRows).toList(growable: false);
  final archiveFile = File(archivePath);
  final mergedArchiveRows = _mergeArchiveRows(archiveFile, archivedRows);

  ledgerFile.writeAsStringSync(_renderLedger(parsed.preamble, keptRows));
  archiveFile.createSync(recursive: true);
  archiveFile.writeAsStringSync(_renderArchive(mergedArchiveRows));

  stdout.writeln(
    'Receipt bug ledger archive: kept=${keptRows.length} '
    'archived=${archivedRows.length} archive=$archivePath',
  );
}

String? _option(List<String> args, String name) {
  final prefix = '--$name=';
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

_ParsedLedger _parseLedger(String text) {
  final lines = text.split('\n');
  final rows = <String>[];
  final preamble = <String>[];
  for (final line in lines) {
    if (line.startsWith('| `BUG-RECEIPT-')) {
      rows.add(line);
    } else if (rows.isEmpty) {
      preamble.add(line);
    }
  }
  if (rows.isEmpty) {
    throw StateError('Ledger must contain bug rows before archiving.');
  }
  return _ParsedLedger(preamble, rows);
}

List<String> _mergeArchiveRows(File archiveFile, List<String> newRows) {
  final rows = <String>[];
  final seen = <String>{};
  void addRow(String row) {
    final id = _bugId(row);
    if (id == null || !seen.add(id)) return;
    rows.add(row);
  }

  for (final row in newRows) {
    addRow(row);
  }
  if (archiveFile.existsSync()) {
    final archived = _parseLedger(archiveFile.readAsStringSync()).rows;
    for (final row in archived) {
      addRow(row);
    }
  }
  return rows;
}

String? _bugId(String row) {
  final match = RegExp(r'`(BUG-RECEIPT-\d+)`').firstMatch(row);
  return match?.group(1);
}

String _renderLedger(List<String> preamble, List<String> rows) =>
    [...preamble, ...rows, ''].join('\n');

String _renderArchive(List<String> rows) => [
  '# Receipt Bug Regression Ledger Archive 0001',
  '',
  'Older closed receipt bug rows live here so the active ledger can stay '
      'under the project line-count cap without losing regression history.',
  '',
  '| Bug ID | Category | Symptom | Root cause | Fix | Regression coverage | Status |',
  '| --- | --- | --- | --- | --- | --- | --- |',
  ...rows,
  '',
].join('\n');

class _ParsedLedger {
  const _ParsedLedger(this.preamble, this.rows);

  final List<String> preamble;
  final List<String> rows;
}
