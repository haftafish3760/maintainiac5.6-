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
  '## Required Target Evidence Matrix',
  '- Galaxy S24 Ultra flagship:',
  '- Galaxy S25 Ultra additional flagship:',
  '- Galaxy S9 Plus older flagship:',
  '- Constrained Android emulator:',
  '- iPhone SE third generation:',
  '- Future budget Android:',
  'A newer flagship does not satisfy the S24 row',
  'Do not copy results between rows.',
  '## Flow Results',
  '### Flow 1: Single Photo Receipt',
  '### Flow 2: Multi-Photo Capture And Long-Receipt Reconstruction',
  '### Flow 3: Save-Space Preview',
  '### Flow 4: Receipt-Review Handoff',
  '### Flow 5: Manual Or No-Assist Photo Handoff',
  '### Flow 6: Interruption And Recovery',
  '## Android Stitch Runtime Evidence',
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
  '## Required Target Evidence Matrix',
  '- Galaxy S24 Ultra flagship:',
  '- Galaxy S25 Ultra additional flagship:',
  '- Galaxy S9 Plus older flagship:',
  '- Constrained Android emulator:',
  '- iPhone SE third generation:',
  '- Future budget Android:',
  '## Flow Results',
  '### Flow 1: Single Photo Receipt',
  '### Flow 3: Save-Space Preview',
  '### Flow 6: Interruption And Recovery',
  '## Android Stitch Runtime Evidence',
  '## Failure Reports',
  '## Privacy And Diagnostics Check',
  '## Exit Summary',
];

const _acceptedRunFlowHeadingSets = <List<String>>[
  [
    '### Flow 2: Multi-Photo Capture And Long-Receipt Reconstruction',
    '### Flow 4: Receipt-Review Handoff',
    '### Flow 5: Manual Or No-Assist Photo Handoff',
  ],
  [
    '### Flow 2: Multi-Photo Capture Handoff',
    '### Flow 4: Receipt-Review Handoff',
    '### Flow 5: Manual Or No-Assist Photo Handoff',
  ],
  [
    '### Flow 2: Long Receipt Multi-Photo',
    '### Flow 4: App-Assisted Filled Receipt Review',
    '### Flow 5: Manual Or No-Assist Receipt',
  ],
];

const _forbiddenRunContent = <String>[
  '![', // no inline receipt images in proof notes
  '<image',
];

const _forbiddenDeviceOutputSignatures = <String>[
  'Found 4 connected devices:',
  'Checking for wireless devices...',
  'List of devices attached',
  '== Devices ==',
  '== Simulators ==',
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
    if (!_acceptedRunFlowHeadingSets.any(
      (headings) => headings.every(text.contains),
    )) {
      _fail(
        'Receipt real-device result gate failed.\n'
        'Run note ${runFile.path} is missing a supported receipt-flow heading set.',
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

    final forbiddenDeviceOutput = [
      for (final token in _forbiddenDeviceOutputSignatures)
        if (text.contains(token)) token,
    ];
    if (forbiddenDeviceOutput.isNotEmpty) {
      _fail(
        'Receipt real-device result gate failed.\n'
        'Run note ${runFile.path} contains raw device output: '
        '${forbiddenDeviceOutput.join(', ')}',
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
