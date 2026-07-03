import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReleaseOneTierRoleSuite extends QaSuite {
  const WorkSupplyParserReleaseOneTierRoleSuite()
    : super('inventory.release_one_tier_role_contract');

  static const _contractSources = [
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_harness_plan.md',
    'docs/inventory_parser_qa_progress_memory.md',
  ];

  static const _requiredTierRoles = {
    'release one is residential-first',
    'core comes before standard',
    'standard comes before professional',
    'core and standard are priority one',
    'service truck',
    'everyday',
    'most common',
    'normal residential items',
    'no special order appliance bloat in core',
    'professional and complete later',
  };

  static const _requiredReleaseAxes = {
    'plumbing',
    'electrical',
    'hvac',
    'en-us',
    'es-us',
    'core',
    'standard',
    'residential',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readContractSource().toLowerCase();

    for (final role in _requiredTierRoles) {
      if (source.contains(role)) continue;
      failures.add(
        _failure(
          id: 'missing_tier_role:${_safeId(role)}',
          message: 'Release-one Core/Standard tier role is not locked.',
          expected: role,
          actual: 'not found in QA contract docs',
          fix:
              'Document the tier role so Core stays everyday/service-truck focused and Standard expands common residential coverage without jumping to long-tail rows.',
        ),
      );
    }

    for (final axis in _requiredReleaseAxes) {
      if (source.contains(axis)) continue;
      failures.add(
        _failure(
          id: 'missing_release_axis:$axis',
          message: 'Release-one QA contract is missing a priority axis.',
          expected: axis,
          actual: 'not found in QA contract docs',
          fix:
              'Keep release-one coverage explicit for US residential Plumbing, Electrical, HVAC, Core, Standard, English, and Spanish.',
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _requiredTierRoles.length + _requiredReleaseAxes.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'contractSources': _contractSources,
        'requiredTierRoles': _requiredTierRoles.toList()..sort(),
        'requiredReleaseAxes': _requiredReleaseAxes.toList()..sort(),
      },
    );
  }

  String _readContractSource() {
    final buffer = StringBuffer();
    for (final path in _contractSources) {
      final file = File(path);
      if (file.existsSync()) buffer.writeln(file.readAsStringSync());
    }
    return buffer.toString();
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.error,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: const {'triageCategory': QaFailureTriage.governance},
    );
  }
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
