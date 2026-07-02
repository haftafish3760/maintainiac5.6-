import 'dart:io';

const _defaultMaxLines = 500;
const _defaultMaxLineLength = 220;
const _disabledMaxLineLength = 0;

const _ignoredPathParts = {
  '.dart_tool',
  '.git',
  'build',
  'Pods',
  'node_modules',
};

const _receiptScopeRoots = [
  'lib/shared/widgets/receipt_capture',
  'lib/shared/receipts',
  'lib/screens/expenses/data',
  'lib/screens/expenses/entry',
  'android/app/src/main/kotlin/com/maintainiac',
  'ios/Runner',
];

const _receiptTestRoots = ['test'];

const _receiptTestNameNeedles = {'receipt', 'ocr', 'telemetry'};

const _sourceExtensions = {'.dart', '.kt', '.swift'};

void main(List<String> args) {
  final config = _AuditConfig.fromArgs(args);
  final files = _sourceFiles(config).toList()..sort();
  final lineCountViolations = <_FileLineReport>[];
  final lineLengthViolations = <_FileLineReport>[];

  for (final file in files) {
    final report = _lineReport(file);
    if (report.lineCount > config.maxLines) {
      lineCountViolations.add(report);
    }
    if (config.maxLineLength > _disabledMaxLineLength &&
        report.maxLineLength > config.maxLineLength) {
      lineLengthViolations.add(report);
    }
  }

  stdout.writeln(
    'Maintainiac source audit: files=${files.length} '
    'maxLines=${config.maxLines} maxLineLength=${config.maxLineLength} '
    'scope=${config.scopeLabel}',
  );

  if (lineCountViolations.isEmpty && lineLengthViolations.isEmpty) {
    stdout.writeln('PASS: no source files exceed ${config.maxLines} lines.');
    return;
  }

  if (lineCountViolations.isNotEmpty) {
    stdout.writeln(
      'FAIL: ${lineCountViolations.length} source file(s) exceed '
      '${config.maxLines} lines.',
    );
    for (final violation in lineCountViolations) {
      stdout.writeln(
        '${violation.lineCount.toString().padLeft(5)} lines  '
        '${violation.path}',
      );
    }
  }
  if (lineLengthViolations.isNotEmpty) {
    stdout.writeln(
      'FAIL: ${lineLengthViolations.length} source file(s) exceed '
      '${config.maxLineLength} characters on one line.',
    );
    for (final violation in lineLengthViolations) {
      stdout.writeln(
        '${violation.maxLineLength.toString().padLeft(5)} chars  '
        '${violation.path}',
      );
    }
  }

  exitCode = 1;
}

Iterable<String> _sourceFiles(_AuditConfig config) sync* {
  for (final root in config.roots) {
    final entity = FileSystemEntity.typeSync(root);
    if (entity == FileSystemEntityType.notFound) continue;
    if (entity == FileSystemEntityType.file && _isSourceFile(root)) {
      yield root;
      continue;
    }
    if (entity != FileSystemEntityType.directory) continue;

    final directory = Directory(root);
    for (final entry in directory.listSync(recursive: true)) {
      if (entry is! File) continue;
      final path = entry.path;
      if (_isIgnored(path) || !_isSourceFile(path)) continue;
      if (!_isIncludedTestPath(path, config)) continue;
      yield path;
    }
  }
}

bool _isIncludedTestPath(String path, _AuditConfig config) {
  final normalized = path.replaceAll('\\', '/');
  if (!normalized.startsWith('test/')) return true;
  if (!config.includeTests) return false;
  final name = normalized.split('/').last.toLowerCase();
  return _receiptTestNameNeedles.any(name.contains);
}

bool _isIgnored(String path) {
  final parts = path.split(Platform.pathSeparator);
  return parts.any(_ignoredPathParts.contains);
}

bool _isSourceFile(String path) {
  return _sourceExtensions.any(path.endsWith);
}

_FileLineReport _lineReport(String path) {
  final lines = File(path).readAsLinesSync();
  final maxLineLength = lines.isEmpty
      ? 0
      : lines.map((line) => line.length).reduce((a, b) => a > b ? a : b);
  return _FileLineReport(
    path: path,
    lineCount: lines.length,
    maxLineLength: maxLineLength,
  );
}

class _AuditConfig {
  const _AuditConfig({
    required this.roots,
    required this.includeTests,
    required this.maxLines,
    required this.maxLineLength,
    required this.scopeLabel,
  });

  factory _AuditConfig.fromArgs(List<String> args) {
    var maxLines = _defaultMaxLines;
    var maxLineLength = _defaultMaxLineLength;
    var receiptScope = true;
    var includeTests = false;
    var testsOnly = false;
    final roots = <String>[];

    for (final arg in args) {
      if (arg == '--all') {
        receiptScope = false;
        continue;
      }
      if (arg == '--include-tests') {
        includeTests = true;
        continue;
      }
      if (arg == '--tests-only') {
        includeTests = true;
        testsOnly = true;
        continue;
      }
      if (arg.startsWith('--max-lines=')) {
        maxLines = int.parse(arg.substring('--max-lines='.length));
        continue;
      }
      if (arg.startsWith('--max-line-length=')) {
        maxLineLength = int.parse(arg.substring('--max-line-length='.length));
        continue;
      }
      if (!arg.startsWith('--')) {
        roots.add(arg);
      }
    }

    if (roots.isEmpty) {
      if (testsOnly) {
        roots.addAll(_receiptTestRoots);
      } else {
        roots.addAll(
          receiptScope ? _receiptScopeRoots : ['lib', 'android', 'ios'],
        );
        if (includeTests) roots.addAll(_receiptTestRoots);
      }
    }

    return _AuditConfig(
      roots: roots,
      includeTests: includeTests,
      maxLines: maxLines,
      maxLineLength: maxLineLength,
      scopeLabel: receiptScope && roots.length == _receiptScopeRoots.length
          ? 'receipt'
          : 'custom',
    );
  }

  final List<String> roots;
  final bool includeTests;
  final int maxLines;
  final int maxLineLength;
  final String scopeLabel;
}

class _FileLineReport {
  const _FileLineReport({
    required this.path,
    required this.lineCount,
    required this.maxLineLength,
  });

  final String path;
  final int lineCount;
  final int maxLineLength;
}
