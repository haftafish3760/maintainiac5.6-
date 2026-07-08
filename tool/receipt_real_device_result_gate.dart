import 'dart:io';

final _templatePath =
    Platform.environment['RECEIPT_REAL_DEVICE_TEMPLATE_PATH'] ??
    'docs/receipt_real_device_result_template.md';
final _runsDir =
    Platform.environment['RECEIPT_REAL_DEVICE_RUNS_DIR'] ??
    'docs/receipt_real_device_runs';

const _templateRequirements = <String>[
  '# Receipt Real-Device Result Template',
  '## Session Metadata',
  '## Environment And Device Matrix',
  '- Metadata snapshot summary:',
  '- Flutter devices snapshot log:',
  '- ADB devices snapshot log:',
  '- Xcode devices snapshot log:',
  '## Flow Results',
  '### Flow 1: Single Photo Receipt',
  '### Flow 2: Long Receipt Multi-Photo',
  '### Flow 3: Save-Space Preview',
  '### Flow 4: App-Assisted Filled Receipt Review',
  '### Flow 5: Manual Or No-Assist Receipt',
  '### Flow 6: Interruption And Recovery',
  '## Failure Reports',
  '## Privacy And Diagnostics Check',
  '## Exit Summary',
  'Do not paste full receipt text.',
  'Do not paste receipt images into this note.',
  'If a flow was not run, mark it `NOT RUN`.',
];

const _runRequirements = <String>[
  '## Session Metadata',
  '## Environment And Device Matrix',
  '- Metadata snapshot summary:',
  '- Flutter devices snapshot log:',
  '- ADB devices snapshot log:',
  '- Xcode devices snapshot log:',
  '## Flow Results',
  '### Flow 1: Single Photo Receipt',
  '### Flow 2: Long Receipt Multi-Photo',
  '### Flow 3: Save-Space Preview',
  '### Flow 4: App-Assisted Filled Receipt Review',
  '### Flow 5: Manual Or No-Assist Receipt',
  '### Flow 6: Interruption And Recovery',
  '## Failure Reports',
  '## Privacy And Diagnostics Check',
  '## Exit Summary',
];

const _forbiddenRunContent = <String>[
  '![', // no inline receipt images in proof notes
  '<image',
];

const _snapshotPathLabels = <String>[
  'Metadata snapshot summary',
  'Flutter devices snapshot log',
  'ADB devices snapshot log',
  'Xcode devices snapshot log',
];

void main() {
  final template = File(_templatePath);
  if (!template.existsSync()) {
    _fail('Missing real-device result template: $_templatePath');
  }

  final templateText = template.readAsStringSync();
  final templateMissing = _missing(templateText, _templateRequirements);
  if (templateMissing.isNotEmpty) {
    _fail(
      'Receipt real-device result gate failed.\n'
      'Template missing: ${templateMissing.join(', ')}',
    );
  }

  final runDir = Directory(_runsDir);
  final runFiles = runDir.existsSync()
      ? runDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.md'))
          .toList()
      : <File>[];

  for (final runFile in runFiles) {
    final text = runFile.readAsStringSync();
    final missing = _missing(text, _runRequirements);
    if (missing.isNotEmpty) {
      _fail(
        'Receipt real-device result gate failed.\n'
        'Run note ${runFile.path} missing: ${missing.join(', ')}',
      );
    }

    final forbidden = [
      for (final token in _forbiddenRunContent)
        if (text.contains(token)) token,
    ];
    if (forbidden.isNotEmpty) {
      _fail(
        'Receipt real-device result gate failed.\n'
        'Run note ${runFile.path} contains forbidden content: ${forbidden.join(', ')}',
      );
    }

    final missingSnapshotPaths = <String>[];
    for (final label in _snapshotPathLabels) {
      final path = _extractBacktickPath(text, label);
      if (path == null || path.trim().isEmpty) {
        missingSnapshotPaths.add(label);
        continue;
      }

      if (!File(path).existsSync()) {
        _fail(
          'Receipt real-device result gate failed.\n'
          'Run note ${runFile.path} points to a missing snapshot file for '
          '$label: $path',
        );
      }
    }

    if (missingSnapshotPaths.isNotEmpty) {
      _fail(
        'Receipt real-device result gate failed.\n'
        'Run note ${runFile.path} is missing snapshot file paths for: '
        '${missingSnapshotPaths.join(', ')}',
      );
    }
  }

  stdout.writeln(
    'Receipt real-device result gate: template=ok run_notes=${runFiles.length}',
  );
}

List<String> _missing(String source, List<String> requirements) => [
  for (final requirement in requirements)
    if (!source.contains(requirement)) requirement,
];

String? _extractBacktickPath(String source, String label) {
  final pattern = RegExp('- ${RegExp.escape(label)}: `([^`]+)`');
  return pattern.firstMatch(source)?.group(1);
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
