import 'maintainiac_surgical_rerun_router.dart';
import 'maintainiac_surgical_test_selector.dart';

class MaintainiacSurgicalGranularityContract {
  const MaintainiacSurgicalGranularityContract({
    required this.registry,
    required this.router,
    this.maxSelectorsPerChangedFile = 6,
    this.minSingleBehaviorPercent = 80,
  });

  final MaintainiacSurgicalTestSelectorRegistry registry;
  final MaintainiacSurgicalRerunRouter router;
  final int maxSelectorsPerChangedFile;
  final int minSingleBehaviorPercent;

  List<String> validate() {
    final failures = <String>[];
    failures.addAll(registry.validate());
    failures.addAll(router.validate());
    failures.addAll(_validateSelectorShape());
    failures.addAll(_validateRouterShape());
    failures.addAll(_validateSurgicalCoverage());
    return failures;
  }

  List<String> _validateSelectorShape() {
    final failures = <String>[];
    final filePlainPairs = <String>{};
    for (final selector in registry.selectors) {
      final pair = '${selector.file}::${selector.plainName}';
      if (!filePlainPairs.add(pair)) {
        failures.add('duplicate surgical selector target $pair');
      }
      if (selector.scope != MaintainiacSurgicalTestScope.singleBehavior &&
          !selector.tags.contains('release-gate')) {
        failures.add(
          '${selector.id} broad selector must be explicitly release-gated',
        );
      }
      if (_looksLikeBatchCommand(selector.command)) {
        failures.add('${selector.id} command looks like a batch run');
      }
      if (_looksLikeBroadTestName(selector.plainName)) {
        failures.add('${selector.id} plain-name looks too broad');
      }
    }
    return failures;
  }

  List<String> _validateRouterShape() {
    final failures = <String>[];
    for (final rule in router.rules) {
      if (rule.selectorIds.length > maxSelectorsPerChangedFile) {
        failures.add(
          '${rule.id} selects ${rule.selectorIds.length} tests; '
          'max is $maxSelectorsPerChangedFile',
        );
      }
      if (rule.changedPathContains.endsWith('/') ||
          rule.changedPathContains.endsWith('\\')) {
        failures.add('${rule.id} must target a file, not a folder');
      }
    }
    return failures;
  }

  List<String> _validateSurgicalCoverage() {
    final failures = <String>[];
    if (registry.selectors.isEmpty) {
      failures.add('surgical granularity has no selectors');
      return failures;
    }
    final singleBehaviorCount = registry.selectors
        .where(
          (selector) =>
              selector.scope == MaintainiacSurgicalTestScope.singleBehavior,
        )
        .length;
    final percent = (singleBehaviorCount * 100 / registry.selectors.length)
        .floor();
    if (percent < minSingleBehaviorPercent) {
      failures.add(
        'surgical selectors are only $percent% single-behavior; '
        'minimum is $minSingleBehaviorPercent%',
      );
    }
    for (final requiredTag in {
      'inventory',
      'expenses',
      'parser-consumer',
      'security',
      'regression',
      'release-gate',
    }) {
      final count = registry.selectors
          .where((selector) => selector.tags.contains(requiredTag))
          .length;
      if (count < 2) {
        failures.add('surgical granularity needs more $requiredTag selectors');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    final singleBehaviorCount = registry.selectors
        .where(
          (selector) =>
              selector.scope == MaintainiacSurgicalTestScope.singleBehavior,
        )
        .length;
    return {
      'selectorCount': registry.selectors.length,
      'singleBehaviorCount': singleBehaviorCount,
      'singleBehaviorPercent': registry.selectors.isEmpty
          ? 0
          : (singleBehaviorCount * 100 / registry.selectors.length).floor(),
      'maxSelectorsPerChangedFile': maxSelectorsPerChangedFile,
      'minSingleBehaviorPercent': minSingleBehaviorPercent,
      'routerRuleCount': router.rules.length,
      'individualPlainNameRequired': true,
      'batchCommandsRejected': true,
    };
  }
}

bool _looksLikeBatchCommand(String command) {
  final normalized = command.toLowerCase();
  return !normalized.contains(' --plain-name ') ||
      normalized.contains(' test/') && !normalized.endsWith('"') ||
      normalized.contains('test/all') ||
      normalized.contains('test/full') ||
      normalized.contains('test/integration') ||
      normalized.contains('--coverage') ||
      normalized.contains('--concurrency') ||
      normalized.contains('&&') ||
      normalized.contains(';') ||
      normalized.contains('|');
}

bool _looksLikeBroadTestName(String plainName) {
  final normalized = plainName.toLowerCase();
  return normalized == 'main' ||
      normalized == 'all' ||
      normalized.contains('entire suite') ||
      normalized.contains('all tests') ||
      normalized.contains('full app') ||
      normalized.contains('everything');
}

const maintainiacSurgicalGranularityContract =
    MaintainiacSurgicalGranularityContract(
      registry: maintainiacSurgicalTestSelectorRegistry,
      router: maintainiacSurgicalRerunRouter,
    );
