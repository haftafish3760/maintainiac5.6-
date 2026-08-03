import 'dart:convert';
import 'dart:io';

part 'receipt_flow_route_audit_report.dart';

/// Read-only receipt-flow source audit.
///
/// This tool does not delete, rewrite, format, build, or launch anything. It
/// traces the current app import graph from lib/main.dart, inventories every
/// receipt entry route, and reports duplicate/legacy/dead-code candidates with
/// the evidence needed for a human decision.
void main(List<String> arguments) {
  final options = _Options.parse(arguments);
  final root = Directory.current.absolute;
  final lib = Directory('${root.path}/lib');
  if (!lib.existsSync()) {
    stderr.writeln('Run this tool from the Maintainiac repository root.');
    exitCode = 64;
    return;
  }

  final allFiles = _dartFiles(lib);
  final sources = <String, String>{
    for (final file in allFiles) _relative(root, file): file.readAsStringSync(),
  };
  final scopeFiles = sources.keys.where(_isReceiptAuditScope).toList()..sort();
  final graph = _buildGraph(sources);
  final reachable = _reachableFrom('lib/main.dart', graph);
  final declarations = _screenDeclarations(scopeFiles, sources);
  final routeSites = _routeSites(scopeFiles, sources);
  final legacyMarkers = _legacyMarkers(scopeFiles, sources);
  final oversized = _oversizedFiles(scopeFiles, sources);
  final exactDuplicates = _exactDuplicateFiles(scopeFiles, sources);
  final similarUi = _similarUiCandidates(scopeFiles, sources);
  final unreachable = scopeFiles
      .where((path) => !reachable.contains(path))
      .map((path) => _UnreachableFile(path, graph.incoming[path] ?? const []))
      .toList();
  final lowReferenceScreens = _lowReferenceScreens(declarations, sources);

  final report = _AuditReport(
    generatedAt: DateTime.now().toUtc(),
    filesScanned: scopeFiles.length,
    routeSites: routeSites,
    legacyMarkers: legacyMarkers,
    oversized: oversized,
    exactDuplicates: exactDuplicates,
    similarUi: similarUi,
    unreachable: unreachable,
    lowReferenceScreens: lowReferenceScreens,
  );

  final outDirectory = Directory(options.outputDirectory)
    ..createSync(recursive: true);
  final markdown = File('${outDirectory.path}/receipt-flow-source-audit.md');
  final json = File('${outDirectory.path}/receipt-flow-source-audit.json');
  markdown.writeAsStringSync(report.toMarkdown());
  json.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report.toJson())}\n',
  );

  stdout.writeln(report.consoleSummary());
  stdout.writeln('Markdown: ${markdown.path}');
  stdout.writeln('JSON: ${json.path}');
}

class _Options {
  const _Options(this.outputDirectory);

  final String outputDirectory;

  factory _Options.parse(List<String> arguments) {
    var outputDirectory =
        '${Directory.systemTemp.path}/maintainiac-receipt-flow-audit';
    for (final argument in arguments) {
      if (argument.startsWith('--out-dir=')) {
        outputDirectory = argument.substring('--out-dir='.length).trim();
      } else if (argument == '--help') {
        stdout.writeln(
          'dart tool/receipt_flow_route_audit.dart [--out-dir=/path]',
        );
        exit(0);
      } else {
        stderr.writeln('Unknown argument: $argument');
        exit(64);
      }
    }
    return _Options(outputDirectory);
  }
}

class _SourceGraph {
  const _SourceGraph(this.outgoing, this.incoming);

  final Map<String, List<String>> outgoing;
  final Map<String, List<String>> incoming;
}

List<File> _dartFiles(Directory root) {
  return root
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList()
    ..sort((left, right) => left.path.compareTo(right.path));
}

bool _isReceiptAuditScope(String path) {
  return path == 'lib/main.dart' ||
      path.startsWith('lib/app/') ||
      path.startsWith('lib/screens/dashboard/') ||
      path.startsWith('lib/screens/expenses/') ||
      path.startsWith('lib/shared/navigation/') ||
      path.startsWith('lib/shared/widgets/receipt_capture/');
}

_SourceGraph _buildGraph(Map<String, String> sources) {
  final outgoing = <String, List<String>>{};
  final incoming = <String, List<String>>{};
  final directive = RegExp(
    r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );
  for (final entry in sources.entries) {
    final targets = <String>[];
    for (final match in directive.allMatches(entry.value)) {
      final resolved = _resolveDirective(entry.key, match.group(1)!);
      if (resolved == null || !sources.containsKey(resolved)) continue;
      if (!targets.contains(resolved)) targets.add(resolved);
      incoming.putIfAbsent(resolved, () => []).add(entry.key);
    }
    outgoing[entry.key] = targets;
  }
  return _SourceGraph(outgoing, incoming);
}

String? _resolveDirective(String from, String uri) {
  if (uri.startsWith('dart:') ||
      (uri.startsWith('package:') && !uri.startsWith('package:maintaniac/'))) {
    return null;
  }
  if (uri.startsWith('package:maintaniac/')) {
    return 'lib/${uri.substring('package:maintaniac/'.length)}';
  }
  final parts = from.split('/')..removeLast();
  for (final segment in uri.split('/')) {
    if (segment == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (segment != '.' && segment.isNotEmpty) {
      parts.add(segment);
    }
  }
  return parts.join('/');
}

Set<String> _reachableFrom(String root, _SourceGraph graph) {
  final reached = <String>{};
  final pending = <String>[root];
  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    if (!reached.add(current)) continue;
    pending.addAll(graph.outgoing[current] ?? const []);
  }
  return reached;
}

List<_Evidence> _routeSites(List<String> paths, Map<String, String> sources) {
  final receiptEntryPattern = RegExp(
    r'(ExpenseReceiptEntryScreen\s*\(|SharedReceiptAttachmentPanel\s*\('
    r'|ReceiptPhotoReviewScreen\s*\(|ReceiptImportSourceSheet'
    r'|ExpenseReceiptStartGuide|openReceipt|showReceipt)',
  );
  final navigationPattern = RegExp(
    r'Navigator\.(?:of\([^\n]+\)\.)?(?:push|pop|maybePop|popUntil)\b'
    r'|PageRouteBuilder\s*\(|MaterialPageRoute\s*[<(]',
  );
  final output = <_Evidence>[];
  for (final path in paths) {
    final receiptNamedFile = path.toLowerCase().contains('receipt');
    final lines = sources[path]!.split('\n');
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (receiptEntryPattern.hasMatch(line) ||
          (receiptNamedFile && navigationPattern.hasMatch(line))) {
        output.add(_Evidence(path, index + 1, line.trim()));
      }
    }
  }
  return output;
}

List<_Evidence> _legacyMarkers(
  List<String> paths,
  Map<String, String> sources,
) {
  final pattern = RegExp(
    r'\b(?:legacy|deprecated|obsolete|old flow|old layout|three[- ]step|wizard)\b'
    r'|Details\s*[>→]\s*Items\s*[>→]\s*Review'
    r'|Manual Receipt',
    caseSensitive: false,
  );
  return _matchingLines(paths, sources, pattern);
}

List<_Evidence> _matchingLines(
  List<String> paths,
  Map<String, String> sources,
  RegExp pattern,
) {
  final matches = <_Evidence>[];
  for (final path in paths) {
    final lines = sources[path]!.split('\n');
    for (var index = 0; index < lines.length; index++) {
      if (pattern.hasMatch(lines[index])) {
        matches.add(_Evidence(path, index + 1, lines[index].trim()));
      }
    }
  }
  return matches;
}

List<_ScreenDeclaration> _screenDeclarations(
  List<String> paths,
  Map<String, String> sources,
) {
  final declaration = RegExp(
    r'^\s*class\s+([A-Z][A-Za-z0-9]*(?:Screen|Page|Flow|Wizard))\b',
    multiLine: true,
  );
  final output = <_ScreenDeclaration>[];
  for (final path in paths) {
    for (final match in declaration.allMatches(sources[path]!)) {
      final name = match.group(1)!;
      final before = sources[path]!.substring(0, match.start);
      final line = '\n'.allMatches(before).length + 1;
      output.add(_ScreenDeclaration(name, _Evidence(path, line, name), 0));
    }
  }
  return output;
}

List<_ScreenDeclaration> _lowReferenceScreens(
  List<_ScreenDeclaration> declarations,
  Map<String, String> sources,
) {
  final allSource = sources.values.join('\n');
  return declarations
      .map((item) {
        final count = RegExp(
          '\\b${RegExp.escape(item.name)}\\b',
        ).allMatches(allSource).length;
        return _ScreenDeclaration(item.name, item.location, count);
      })
      .where((item) => item.referenceCount <= 1)
      .toList();
}

List<_FileSize> _oversizedFiles(
  List<String> paths,
  Map<String, String> sources,
) {
  return [
    for (final path in paths)
      if (_lineCount(sources[path]!) > 500)
        _FileSize(path, _lineCount(sources[path]!)),
  ]..sort((left, right) => right.lines.compareTo(left.lines));
}

List<List<String>> _exactDuplicateFiles(
  List<String> paths,
  Map<String, String> sources,
) {
  final groups = <String, List<String>>{};
  for (final path in paths) {
    final normalized = sources[path]!
        .replaceAll(RegExp(r'//[^\n]*'), '')
        .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.length < 160) continue;
    groups.putIfAbsent(normalized, () => []).add(path);
  }
  return groups.values.where((group) => group.length > 1).toList();
}

List<_SimilarUiPair> _similarUiCandidates(
  List<String> paths,
  Map<String, String> sources,
) {
  final labels = <String, Set<String>>{};
  final quoted = RegExp(r'''['"]([^'"\n]{4,80})['"]''');
  for (final path in paths) {
    final lowerPath = path.toLowerCase();
    if (!lowerPath.contains('receipt') ||
        !RegExp(
          r'(screen|flow|panel|sheet|entry|review)',
        ).hasMatch(lowerPath)) {
      continue;
    }
    final values = <String>{};
    for (final match in quoted.allMatches(sources[path]!)) {
      final value = match.group(1)!.trim();
      if (!_looksUserFacing(value)) continue;
      values.add(value.toLowerCase());
    }
    if (values.length >= 4) labels[path] = values;
  }
  final candidates = <_SimilarUiPair>[];
  final files = labels.keys.toList()..sort();
  for (var firstIndex = 0; firstIndex < files.length; firstIndex++) {
    for (
      var secondIndex = firstIndex + 1;
      secondIndex < files.length;
      secondIndex++
    ) {
      final first = labels[files[firstIndex]]!;
      final second = labels[files[secondIndex]]!;
      final shared = first.intersection(second).toList()..sort();
      if (shared.length < 4) continue;
      final unionCount = first.union(second).length;
      final score = unionCount == 0 ? 0.0 : shared.length / unionCount;
      if (score < .42) continue;
      candidates.add(
        _SimilarUiPair(files[firstIndex], files[secondIndex], shared, score),
      );
    }
  }
  candidates.sort((left, right) => right.score.compareTo(left.score));
  return candidates.take(80).toList();
}

bool _looksUserFacing(String value) {
  if (!RegExp(r'[A-Za-z]').hasMatch(value)) return false;
  if (value.contains('/') || value.contains('_') || value.contains(r'${')) {
    return false;
  }
  return value.contains(' ') || RegExp(r'^[A-Z][a-z]+$').hasMatch(value);
}

int _lineCount(String source) => '\n'.allMatches(source).length + 1;

String _relative(Directory root, File file) {
  final prefix = '${root.path}${Platform.pathSeparator}';
  return file.absolute.path.startsWith(prefix)
      ? file.absolute.path.substring(prefix.length).replaceAll('\\', '/')
      : file.path.replaceAll('\\', '/');
}
