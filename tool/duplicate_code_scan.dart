import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

const _defaultRoots = ['lib', 'test', 'android/app/src', 'ios/Runner'];
const _codeExtensions = {'.dart', '.kt', '.java', '.swift'};

void main(List<String> arguments) async {
  final options = _ScanOptions.parse(arguments);
  final files = await _collectCodeFiles(options.roots);
  final report = await _scan(files, minimumLines: options.minimumLines);

  if (options.json) {
    stdout.writeln(jsonEncode(report.toJson()));
  } else {
    _writeHumanReport(report);
  }
  if (options.failOnDuplicates && report.hasDuplicates) exitCode = 1;
}

class _ScanOptions {
  const _ScanOptions({
    required this.roots,
    required this.minimumLines,
    required this.json,
    required this.failOnDuplicates,
  });

  final List<String> roots;
  final int minimumLines;
  final bool json;
  final bool failOnDuplicates;

  factory _ScanOptions.parse(List<String> arguments) {
    final roots = <String>[];
    var minimumLines = 10;
    var json = false;
    var failOnDuplicates = false;
    for (final argument in arguments) {
      if (argument == '--json') {
        json = true;
      } else if (argument == '--fail-on-duplicates') {
        failOnDuplicates = true;
      } else if (argument.startsWith('--min-lines=')) {
        minimumLines = int.tryParse(argument.substring(12)) ?? minimumLines;
      } else if (!argument.startsWith('-')) {
        roots.add(argument);
      }
    }
    if (minimumLines < 4) minimumLines = 4;
    return _ScanOptions(
      roots: roots.isEmpty ? _defaultRoots : roots,
      minimumLines: minimumLines,
      json: json,
      failOnDuplicates: failOnDuplicates,
    );
  }
}

class _DuplicateCodeReport {
  const _DuplicateCodeReport({
    required this.filesScanned,
    required this.exactFiles,
    required this.blocks,
  });

  final int filesScanned;
  final List<List<String>> exactFiles;
  final List<List<_CodeOccurrence>> blocks;

  bool get hasDuplicates => exactFiles.isNotEmpty || blocks.isNotEmpty;

  Map<String, Object?> toJson() => {
    'filesScanned': filesScanned,
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

Future<List<File>> _collectCodeFiles(List<String> roots) async {
  final files = <File>[];
  for (final root in roots) {
    final entity = FileSystemEntity.typeSync(root);
    if (entity == FileSystemEntityType.file && _isCodeFile(root)) {
      files.add(File(root));
      continue;
    }
    if (entity != FileSystemEntityType.directory) continue;
    await for (final file in Directory(root).list(recursive: true)) {
      if (file is File && _isCodeFile(file.path)) files.add(file);
    }
  }
  files.sort((left, right) => left.path.compareTo(right.path));
  return files;
}

bool _isCodeFile(String value) {
  final normalized = path.normalize(value);
  if (normalized.contains('${path.separator}.dart_tool${path.separator}') ||
      normalized.contains('${path.separator}build${path.separator}')) {
    return false;
  }
  return _codeExtensions.contains(path.extension(normalized));
}

Future<_DuplicateCodeReport> _scan(
  List<File> files, {
  required int minimumLines,
}) async {
  final fileGroups = <String, List<String>>{};
  final blocks = <String, List<_CodeOccurrence>>{};
  for (final file in files) {
    final source = await file.readAsString();
    final normalized = _normalize(source);
    if (normalized.isNotEmpty) {
      fileGroups
          .putIfAbsent(
            sha256.convert(utf8.encode(normalized)).toString(),
            () => [],
          )
          .add(file.path);
    }
    _addDuplicateBlocks(blocks, file.path, source, minimumLines);
  }
  return _DuplicateCodeReport(
    filesScanned: files.length,
    exactFiles: fileGroups.values.where((group) => group.length > 1).toList(),
    blocks: blocks.values.where((group) => group.length > 1).toList(),
  );
}

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
  if (!report.hasDuplicates) stdout.writeln('No duplicate code found.');
}
