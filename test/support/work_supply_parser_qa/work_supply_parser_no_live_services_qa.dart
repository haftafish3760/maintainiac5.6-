import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserNoLiveServicesSuite extends QaSuite {
  const WorkSupplyParserNoLiveServicesSuite()
    : super('inventory.no_live_services_contract');

  static const _scannedRoots = [
    'test/support/qa_harness',
    'test/support/work_supply_parser_qa',
    'test/work_supply_parser_qa_harness_test.dart',
    'test/qa_report_artifact_test.dart',
  ];

  static const _documentedContracts = [
    _NoLiveServiceDocContract('explicit_no_live_services', [
      'No test profile may hit live Firebase',
      'production network services',
    ]),
    _NoLiveServiceDocContract('future_integration_profile_requires_approval', [
      'future explicit integration profile',
      'separately approved',
    ]),
    _NoLiveServiceDocContract('firebase_boundary', [
      'Firebase writes are still off-limits',
      'no live hosted writes in tests',
    ]),
    _NoLiveServiceDocContract('local_first_cloud_opt_in', [
      'Local pack mode',
      'Cloud fallback',
      'opt-in',
    ]),
  ];

  static const _forbiddenRuntimeTokens = {
    'firebase_runtime': [
      'Firebase.initializeApp',
      'FirebaseFirestore.instance',
      'FirebaseFunctions.instance',
      'FirebaseStorage.instance',
      'FirebaseAuth.instance',
    ],
    'network_runtime': [
      'HttpClient(',
      'http.get(',
      'http.post(',
      'http.put(',
      'http.delete(',
      'WebSocket.connect',
      'Socket.connect',
    ],
    'live_credentials': [
      'GOOGLE_APPLICATION_CREDENTIALS',
      'serviceAccount',
      'private_key',
      'client_email',
      'refresh_token',
    ],
    'live_process_shell': [
      'Process.run(',
      'Process.start(',
      'adb shell am start',
      'firebase deploy',
      'gcloud ',
    ],
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final files = _filesToScan();
    final sourceByPath = <String, String>{};
    var checked = 0;

    for (final file in files) {
      final path = file.path.replaceAll('\\', '/');
      if (path.endsWith('work_supply_parser_no_live_services_qa.dart') ||
          path.endsWith('work_supply_parser_boundary_qa.dart')) {
        continue;
      }
      final source = file.readAsStringSync();
      sourceByPath[path] = source;
      for (final entry in _forbiddenRuntimeTokens.entries) {
        for (final token in entry.value) {
          checked++;
          if (!source.contains(token)) continue;
          failures.add(
            QaFailure(
              suite: name,
              id: 'live_service_token:${entry.key}:$path:$token',
              message: 'Parser QA harness contains a live-service token.',
              severity: QaSeverity.critical,
              expected:
                  'local-only parser QA with no Firebase/network/credential/process integration',
              actual: '$path contains $token',
              suggestedFix:
                  'Move live integration work to a separately approved integration profile outside inventory parser QA.',
              metadata: const {'triageCategory': QaFailureTriage.security},
            ),
          );
        }
      }
    }

    final docSource = _readDoc(
      'docs/inventory_parser_qa_harness_plan.md',
      failures,
    );
    final presentDocs = <String>[];
    for (final contract in _documentedContracts) {
      checked++;
      if (contract.isPresentIn(docSource)) {
        presentDocs.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_no_live_service_doc:${contract.name}',
          message: 'No-live-services contract is not documented.',
          severity: QaSeverity.error,
          expected: contract.tokens.join(' + '),
          actual: 'not found',
          suggestedFix:
              'Document the local-only/parser-only boundary before running large catalog QA or cloud pack work.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked + sourceByPath.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'filesScanned': sourceByPath.keys.toList()..sort(),
        'forbiddenTokenGroups': _forbiddenRuntimeTokens.keys.toList(),
        'presentDocContracts': presentDocs,
        'networkAllowed': false,
        'firebaseAllowed': false,
      },
    );
  }

  String _readDoc(String path, List<QaFailure> failures) {
    final file = File(path);
    if (file.existsSync()) return file.readAsStringSync();
    failures.add(
      QaFailure(
        suite: name,
        id: 'missing_no_live_service_doc_file:$path',
        message: 'No-live-services documentation file is missing.',
        expected: path,
        actual: 'not found',
        suggestedFix: 'Update this suite if the harness plan moves.',
        metadata: const {'triageCategory': QaFailureTriage.schema},
      ),
    );
    return '';
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
    files.sort((left, right) => left.path.compareTo(right.path));
    return files;
  }
}

class _NoLiveServiceDocContract {
  const _NoLiveServiceDocContract(this.name, this.tokens);

  final String name;
  final List<String> tokens;

  bool isPresentIn(String source) {
    final normalizedSource = _normalizeContractText(source);
    return tokens.every(
      (token) => normalizedSource.contains(_normalizeContractText(token)),
    );
  }
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
