import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

const _defaultRoots = [
  'lib',
  'android',
  'ios',
  'macos',
  'windows',
  'linux',
  'web',
  'functions',
  'tool',
];
const _codeExtensions = {
  '.dart',
  '.kt',
  '.java',
  '.swift',
  '.m',
  '.mm',
  '.h',
  '.c',
  '.cc',
  '.cpp',
  '.js',
  '.ts',
  '.tsx',
  '.jsx',
  '.py',
  '.sh',
};

void main(List<String> arguments) async {
  final options = _ScanOptions.parse(arguments);
  final files = await _collectCodeFiles(options);
  final report = await _scan(
    files,
    minimumLines: options.minimumLines,
    maximumGroups: options.maximumGroups,
  );

  final encoded = jsonEncode(report.toJson());
  if (options.reportPath != null) {
    final reportFile = File(options.reportPath!);
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString('$encoded\n');
    stdout.writeln(
      'Duplicate code scan: files=${report.filesScanned}, '
      'groups=${report.totalDuplicateGroups}, report=${reportFile.path}',
    );
  } else if (options.json) {
    stdout.writeln(encoded);
  } else {
    _writeHumanReport(report);
  }
  if (options.failOnDuplicates && report.hasDuplicates) exitCode = 1;
}

class _ScanOptions {
  const _ScanOptions({
    required this.roots,
    required this.minimumLines,
    required this.maximumGroups,
    required this.includeGenerated,
    required this.json,
    required this.failOnDuplicates,
    required this.reportPath,
  });

  final List<String> roots;
  final int minimumLines;
  final int maximumGroups;
  final bool includeGenerated;
  final bool json;
  final bool failOnDuplicates;
  final String? reportPath;

  factory _ScanOptions.parse(List<String> arguments) {
    final roots = <String>[];
    var minimumLines = 16;
    var maximumGroups = 100;
    var includeGenerated = false;
    var json = false;
    var failOnDuplicates = false;
    String? reportPath;
    for (final argument in arguments) {
      if (argument == '--json') {
        json = true;
      } else if (argument == '--include-generated') {
        includeGenerated = true;
      } else if (argument == '--fail-on-duplicates') {
        failOnDuplicates = true;
      } else if (argument.startsWith('--min-lines=')) {
        minimumLines = int.tryParse(argument.substring(12)) ?? minimumLines;
      } else if (argument.startsWith('--max-groups=')) {
        maximumGroups =
            int.tryParse(argument.substring('--max-groups='.length)) ??
            maximumGroups;
      } else if (argument.startsWith('--report=')) {
        reportPath = argument.substring('--report='.length);
      } else if (!argument.startsWith('-')) {
        roots.add(argument);
      }
    }
    if (minimumLines < 4) minimumLines = 4;
    if (maximumGroups < 1) maximumGroups = 1;
    return _ScanOptions(
      roots: roots.isEmpty ? _defaultRoots : roots,
      minimumLines: minimumLines,
      maximumGroups: maximumGroups,
      includeGenerated: includeGenerated,
      json: json,
      failOnDuplicates: failOnDuplicates,
      reportPath: reportPath,
    );
  }
}

class _DuplicateCodeReport {
  const _DuplicateCodeReport({
    required this.filesScanned,
    required this.exactFiles,
    required this.blocks,
    required this.totalBlockGroups,
  });

  final int filesScanned;
  final List<List<String>> exactFiles;
  final List<List<_CodeOccurrence>> blocks;
  final int totalBlockGroups;

  int get totalDuplicateGroups => exactFiles.length + totalBlockGroups;
  bool get hasDuplicates => totalDuplicateGroups > 0;

  Map<String, Object?> toJson() => {
    'filesScanned': filesScanned,
    'totalDuplicateGroups': totalDuplicateGroups,
    'reportedBlockGroups': blocks.length,
    'truncated': blocks.length < totalBlockGroups,
    'exactFiles': exactFiles,
    'blocks': [
      for (final group in blocks)
        [for (final occurrence in group) occurrence.toJson()],
    ],
  };
}

class _CodeOccurrence {
  const _CodeOccurrence({
    required this.file,
    required this.startLine,
    required this.endLine,
  });

  final String file;
  final int startLine;
  final int endLine;

  Map<String, Object?> toJson() => {
    'file': file,
    'startLine': startLine,
    'endLine': endLine,
  };
}

Future<List<File>> _collectCodeFiles(_ScanOptions options) async {
  final files = <File>[];
  for (final root in options.roots) {
    final entity = FileSystemEntity.typeSync(root);
    if (entity == FileSystemEntityType.file &&
        _isCodeFile(root, includeGenerated: options.includeGenerated)) {
      files.add(File(root));
      continue;
    }
    if (entity != FileSystemEntityType.directory) continue;
    await for (final file in Directory(
      root,
    ).list(recursive: true, followLinks: false)) {
      if (file is File &&
          _isCodeFile(file.path, includeGenerated: options.includeGenerated)) {
        files.add(file);
      }
    }
  }
  files.sort((left, right) => left.path.compareTo(right.path));
  return files;
}

bool _isCodeFile(String value, {required bool includeGenerated}) {
  final normalized = path.normalize(value);
  if (normalized.contains('${path.separator}.dart_tool${path.separator}') ||
      normalized.contains('${path.separator}build${path.separator}')) {
    return false;
  }
  if (_isTestCodePath(normalized)) return false;
  if (!includeGenerated && _isGeneratedCodePath(normalized)) return false;
  return _codeExtensions.contains(path.extension(normalized));
}

bool _isTestCodePath(String value) {
  final normalized = value.replaceAll('\\', '/').toLowerCase();
  final name = path.basename(normalized);
  return normalized.contains('/test/') ||
      normalized.contains('/tests/') ||
      name.startsWith('test_') ||
      name.endsWith('_test.dart') ||
      name.endsWith('_test.py') ||
      name.endsWith('.test.js') ||
      name.endsWith('.test.ts');
}

bool _isGeneratedCodePath(String value) {
  final normalized = value.replaceAll('\\', '/').toLowerCase();
  final name = path.basename(normalized);
  return normalized.contains('/.symlinks/') ||
      normalized.contains('/.plugin_symlinks/') ||
      normalized.contains('/ephemeral/') ||
      normalized.contains('/pods/') ||
      normalized.contains('/node_modules/') ||
      normalized.contains('/deriveddata/') ||
      normalized.contains('/.gradle/') ||
      normalized.contains('/third_party/') ||
      normalized.contains('/vendor/') ||
      normalized.contains('/generated/') ||
      normalized.contains('/generated_') ||
      name.endsWith('.g.dart') ||
      name.endsWith('.freezed.dart') ||
      name == 'generated_plugin_registrant.dart' ||
      name == 'generated_plugin_registrant.cc' ||
      name == 'generated_plugin_registrant.h';
}

Future<_DuplicateCodeReport> _scan(
  List<File> files, {
  required int minimumLines,
  required int maximumGroups,
}) async {
  final fileGroups = <String, List<String>>{};
  final blocks = <String, List<_CodeOccurrence>>{};
  for (final file in files) {
    final source = await file.readAsString();
    final normalized = _normalize(source);
    if (_meaningfulLineCount(source) >= minimumLines) {
      fileGroups
          .putIfAbsent(
            sha256.convert(utf8.encode(normalized)).toString(),
            () => [],
          )
          .add(file.path);
    }
    _addDuplicateBlocks(blocks, file.path, source, minimumLines);
  }
  final duplicateBlocks =
      _mergeDuplicateBlocks(
        blocks.values.where(_hasDistinctOccurrences),
        minimumLines,
      )..sort(
        (left, right) => _occurrenceKey(left).compareTo(_occurrenceKey(right)),
      );
  return _DuplicateCodeReport(
    filesScanned: files.length,
    exactFiles: fileGroups.values.where((group) => group.length > 1).toList(),
    blocks: duplicateBlocks.take(maximumGroups).toList(),
    totalBlockGroups: duplicateBlocks.length,
  );
}

int _meaningfulLineCount(String source) => source.split('\n').where((line) {
  final trimmed = line.trim();
  return trimmed.isNotEmpty &&
      !trimmed.startsWith('//') &&
      !trimmed.startsWith('/*') &&
      !trimmed.startsWith('*');
}).length;

bool _hasDistinctOccurrences(List<_CodeOccurrence> group) =>
    group.map((item) => '${item.file}:${item.startLine}').toSet().length > 1;

List<List<_CodeOccurrence>> _mergeDuplicateBlocks(
  Iterable<List<_CodeOccurrence>> groups,
  int minimumLines,
) {
  final runs = <String, List<List<_CodeOccurrence>>>{};
  for (final group in groups) {
    final occurrences = [...group]
      ..sort((left, right) {
        final fileOrder = left.file.compareTo(right.file);
        return fileOrder != 0
            ? fileOrder
            : left.startLine.compareTo(right.startLine);
      });
    for (var leftIndex = 0; leftIndex < occurrences.length; leftIndex++) {
      for (
        var rightIndex = leftIndex + 1;
        rightIndex < occurrences.length;
        rightIndex++
      ) {
        final left = occurrences[leftIndex];
        final right = occurrences[rightIndex];
        if (left.file == right.file &&
            (left.startLine - right.startLine).abs() < minimumLines) {
          continue;
        }
        final offset = left.startLine - right.startLine;
        runs.putIfAbsent('${left.file}|${right.file}|$offset', () => []).add([
          left,
          right,
        ]);
      }
    }
  }

  final merged = <List<_CodeOccurrence>>[];
  for (final windows in runs.values) {
    windows.sort(
      (left, right) => left.first.startLine.compareTo(right.first.startLine),
    );
    List<_CodeOccurrence>? current;
    for (final window in windows) {
      if (current == null) {
        current = window;
        continue;
      }
      final adjacentLeft = window.first.startLine <= current.first.endLine + 1;
      final adjacentRight = window.last.startLine <= current.last.endLine + 1;
      if (adjacentLeft && adjacentRight) {
        current = [
          _CodeOccurrence(
            file: current.first.file,
            startLine: current.first.startLine,
            endLine: window.first.endLine > current.first.endLine
                ? window.first.endLine
                : current.first.endLine,
          ),
          _CodeOccurrence(
            file: current.last.file,
            startLine: current.last.startLine,
            endLine: window.last.endLine > current.last.endLine
                ? window.last.endLine
                : current.last.endLine,
          ),
        ];
      } else {
        merged.add(current);
        current = window;
      }
    }
    if (current != null) merged.add(current);
  }
  return merged;
}

String _occurrenceKey(List<_CodeOccurrence> group) => group
    .map((item) => '${item.file}:${item.startLine.toString().padLeft(9, '0')}')
    .join('|');

void _addDuplicateBlocks(
  Map<String, List<_CodeOccurrence>> blocks,
  String file,
  String source,
  int minimumLines,
) {
  final lines = source.split('\n');
  for (var index = 0; index + minimumLines <= lines.length; index++) {
    final window = lines.sublist(index, index + minimumLines);
    final normalized = _normalize(window.join('\n'));
    if (normalized.length < minimumLines * 18 || !_hasCode(normalized)) {
      continue;
    }
    final key = sha256.convert(utf8.encode(normalized)).toString();
    blocks
        .putIfAbsent(key, () => [])
        .add(
          _CodeOccurrence(
            file: file,
            startLine: index + 1,
            endLine: index + minimumLines,
          ),
        );
  }
}

bool _hasCode(String text) {
  return text.split('\n').any((line) {
    final trimmed = line.trimLeft();
    return trimmed.isNotEmpty &&
        !trimmed.startsWith('//') &&
        !trimmed.startsWith('*') &&
        !trimmed.startsWith('/*');
  });
}

String _normalize(String source) {
  return source
      .split('\n')
      .map((line) => line.trimRight())
      .where((line) => line.trim().isNotEmpty)
      .join('\n')
      .trim();
}

void _writeHumanReport(_DuplicateCodeReport report) {
  stdout.writeln('Duplicate code scan: files=${report.filesScanned}');
  for (final group in report.exactFiles) {
    stdout.writeln('Exact duplicate files: ${group.join(' | ')}');
  }
  for (final group in report.blocks) {
    stdout.writeln(
      'Duplicate ${group.first.endLine - group.first.startLine + 1}-line block: '
      '${group.map((item) => '${item.file}:${item.startLine}').join(' | ')}',
    );
  }
  if (report.blocks.length < report.totalBlockGroups) {
    stdout.writeln(
      'Output limited to ${report.blocks.length} of '
      '${report.totalBlockGroups} duplicate block groups.',
    );
  }
  if (!report.hasDuplicates) stdout.writeln('No duplicate code found.');
}
