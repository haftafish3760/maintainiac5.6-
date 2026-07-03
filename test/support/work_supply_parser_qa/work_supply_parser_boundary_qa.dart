import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserBoundarySuite extends QaSuite {
  const WorkSupplyParserBoundarySuite() : super('inventory.boundary_guard');

  static const _scannedRoots = [
    'test/support/parser_qa_platform',
    'test/support/work_supply_parser_qa',
    'test/work_supply_parser_qa_harness_test.dart',
  ];

  static const _forbiddenPatterns = {
    'firebase': [
      'package:firebase_',
      'package:cloud_firestore',
      'FirebaseFirestore',
      'FirebaseApp',
    ],
    'camera_ocr_expenses': [
      'package:camera',
      'package:image_picker',
      'package:google_mlkit',
      'package:google_mlkit_text_recognition',
      '/expenses/',
      r'\expenses\',
    ],
    'live_network': [
      'package:http/',
      'HttpClient(',
      'WebSocket.connect',
      'Socket.connect',
    ],
    'platform_device_api': [
      'package:device_info_plus',
      'MethodChannel(',
      'EventChannel(',
    ],
    'unstable_ui_qa': [
      'testWidgets(',
      'WidgetTester',
      'pumpWidget(',
      'find.byWidget',
      'find.byType',
      'find.text(',
      'matchesGoldenFile',
    ],
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final files = _filesToScan();
    var checked = 0;

    for (final file in files) {
      final lines = file
          .readAsLinesSync()
          .where((line) => !_isQuotedConfigurationLine(line))
          .toList(growable: false);
      for (final entry in _forbiddenPatterns.entries) {
        for (final pattern in entry.value) {
          checked++;
          if (!lines.any((line) => line.contains(pattern))) continue;
          failures.add(
            QaFailure(
              suite: name,
              id: 'forbidden_${entry.key}:${file.path.replaceAll('\\', '/')}:$pattern',
              message:
                  'Inventory parser QA harness crossed a forbidden boundary.',
              severity: QaSeverity.critical,
              expected:
                  'Harness must stay local, parser-only, and independent of OCR/camera/Firebase/unstable UI.',
              actual: '${file.path} contains "$pattern"',
              suggestedFix:
                  'Move integration/UI work to an explicit approved profile after that screen is stable, not the parser QA harness.',
            ),
          );
        }
      }
    }

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'filesScanned': files.length,
        'forbiddenGroups': _forbiddenPatterns.keys.toList(growable: false),
      },
    );
  }

  bool _isQuotedConfigurationLine(String line) {
    final trimmed = line.trimLeft();
    return trimmed.startsWith("'") ||
        trimmed.startsWith('"') ||
        trimmed.startsWith("r'") ||
        trimmed.startsWith('r"');
  }

  List<File> _filesToScan() {
    final files = <File>[];
    for (final root in _scannedRoots) {
      final file = File(root);
      if (file.existsSync()) {
        files.add(file);
        continue;
      }
      final directory = Directory(root);
      if (!directory.existsSync()) continue;
      files.addAll(
        directory
            .listSync(recursive: true)
            .whereType<File>()
            .where((entry) => entry.path.endsWith('.dart')),
      );
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }
}
