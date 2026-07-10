import 'maintainiac_qa_case_registry.dart';
import 'maintainiac_qa_environment.dart';

enum MaintainiacModuleSuiteStatus { planned, scaffolded, executable }

class MaintainiacModuleSuiteContract {
  const MaintainiacModuleSuiteContract({
    required this.id,
    required this.module,
    required this.label,
    required this.owner,
    required this.status,
    required this.priority,
    required this.behaviors,
    this.command = '',
    this.liveServicesAllowed = false,
    this.firebaseWritesAllowed = false,
    this.tags = const {},
  });

  final String id;
  final MaintainiacQaModule module;
  final String label;
  final String owner;
  final MaintainiacModuleSuiteStatus status;
  final MaintainiacQaCasePriority priority;
  final List<String> behaviors;
  final String command;
  final bool liveServicesAllowed;
  final bool firebaseWritesAllowed;
  final Set<String> tags;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('module suite missing id');
    if (label.trim().isEmpty) failures.add('$id missing label');
    if (owner.trim().isEmpty) failures.add('$id missing owner');
    if (behaviors.isEmpty) failures.add('$id missing behavior list');
    if (behaviors.any((behavior) => behavior.trim().isEmpty)) {
      failures.add('$id has blank behavior');
    }
    if (tags.isEmpty) failures.add('$id needs searchable tags');
    if (liveServicesAllowed) {
      failures.add('$id must not allow live services');
    }
    if (firebaseWritesAllowed) {
      failures.add('$id must not allow Firebase writes');
    }
    if (status == MaintainiacModuleSuiteStatus.executable &&
        !command.startsWith('flutter test ')) {
      failures.add('$id executable suite needs focused flutter test command');
    }
    if (status != MaintainiacModuleSuiteStatus.executable &&
        command.isNotEmpty) {
      failures.add('$id non-executable suite should not advertise a command');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'module': module.name,
      'label': label,
      'owner': owner,
      'status': status.name,
      'priority': priority.name,
      'behaviors': behaviors,
      if (command.isNotEmpty) 'command': command,
      'liveServicesAllowed': liveServicesAllowed,
      'firebaseWritesAllowed': firebaseWritesAllowed,
      'tags': tags.toList()..sort(),
    };
  }
}

class MaintainiacModuleSuiteMatrix {
  const MaintainiacModuleSuiteMatrix(this.suites);

  factory MaintainiacModuleSuiteMatrix.releaseOnePlan() {
    return const MaintainiacModuleSuiteMatrix([
      MaintainiacModuleSuiteContract(
        id: 'suite_inventory_parser',
        module: MaintainiacQaModule.inventory,
        label: 'Inventory parser and catalog QA',
        owner: 'maintainiac-qa',
        status: MaintainiacModuleSuiteStatus.executable,
        priority: MaintainiacQaCasePriority.releaseBlocker,
        command:
            'flutter test test/work_supply_parser_generated_fixture_runner_test.dart',
        behaviors: [
          'Parser candidates stay review-only until user confirmation.',
          'Catalog fixtures preserve merchant, locale, and trade context.',
          'Dangerous words produce ranked candidates or review states.',
        ],
        tags: {'inventory', 'parser', 'catalog'},
      ),
      MaintainiacModuleSuiteContract(
        id: 'suite_expenses_core',
        module: MaintainiacQaModule.expenses,
        label: 'Expense ledger and parser QA',
        owner: 'maintainiac-qa',
        status: MaintainiacModuleSuiteStatus.executable,
        priority: MaintainiacQaCasePriority.releaseBlocker,
        command: 'flutter test test/maintainiac_financial_ledger_test.dart',
        behaviors: [
          'Expense totals balance in integer cents.',
          'Parser suggestions remain suggestions until confirmation.',
          'Confirmed expenses write locally before mirror sync.',
        ],
        tags: {'expenses', 'ledger', 'parser'},
      ),
      MaintainiacModuleSuiteContract(
        id: 'suite_jobs',
        module: MaintainiacQaModule.jobs,
        label: 'Jobs source and material attachment QA',
        owner: 'maintainiac-qa',
        status: MaintainiacModuleSuiteStatus.executable,
        priority: MaintainiacQaCasePriority.core,
        command: 'flutter test test/maintainiac_job_contract_test.dart',
        behaviors: [
          'Jobs read confirmed estimates and inventory movements.',
          'Job material changes are audited and local-first.',
          'Derived job summaries do not mutate source records.',
        ],
        tags: {'jobs', 'source-of-truth', 'materials'},
      ),
      MaintainiacModuleSuiteContract(
        id: 'suite_estimates_invoices',
        module: MaintainiacQaModule.estimates,
        label: 'Estimate and invoice pricing QA',
        owner: 'maintainiac-qa',
        status: MaintainiacModuleSuiteStatus.executable,
        priority: MaintainiacQaCasePriority.releaseBlocker,
        command: 'flutter test test/maintainiac_pricing_contract_test.dart',
        behaviors: [
          'Pricing uses integer cents for taxes, discounts, and markups.',
          'Estimate/invoice outputs do not mutate inventory or expenses.',
          'Trade sections can summarize subtotals and grand totals.',
        ],
        tags: {'estimates', 'invoices', 'pricing'},
      ),
      MaintainiacModuleSuiteContract(
        id: 'suite_calendar',
        module: MaintainiacQaModule.calendar,
        label: 'Calendar edits and recap QA',
        owner: 'maintainiac-qa',
        status: MaintainiacModuleSuiteStatus.executable,
        priority: MaintainiacQaCasePriority.core,
        command: 'flutter test test/maintainiac_schedule_contract_test.dart',
        behaviors: [
          'Calendar edits create audit entries.',
          'Recaps read source records without mutating them.',
          'Reminder scheduling is deterministic and permission-aware.',
        ],
        tags: {'calendar', 'recap', 'reminders'},
      ),
      MaintainiacModuleSuiteContract(
        id: 'suite_maintenance',
        module: MaintainiacQaModule.maintenance,
        label: 'Maintenance record QA',
        owner: 'maintainiac-qa',
        status: MaintainiacModuleSuiteStatus.executable,
        priority: MaintainiacQaCasePriority.core,
        command: 'flutter test test/maintainiac_schedule_contract_test.dart',
        behaviors: [
          'Maintenance entries are local-first source records.',
          'Maintenance reminders are derived output only.',
          'Vehicle scoping prevents cross-vehicle bleed.',
        ],
        tags: {'maintenance', 'vehicles', 'reminders'},
      ),
      MaintainiacModuleSuiteContract(
        id: 'suite_fleet_employees',
        module: MaintainiacQaModule.fleet,
        label: 'Fleet company employee QA',
        owner: 'maintainiac-qa',
        status: MaintainiacModuleSuiteStatus.executable,
        priority: MaintainiacQaCasePriority.releaseBlocker,
        command: 'flutter test test/maintainiac_scope_policy_test.dart',
        behaviors: [
          'Company, employee, vehicle, and permission scoping is enforced.',
          'Exports and sync payloads contain only owned records.',
          'Admin permission does not bypass account isolation.',
        ],
        tags: {'fleet', 'employees', 'permissions'},
      ),
      MaintainiacModuleSuiteContract(
        id: 'suite_exports_privacy',
        module: MaintainiacQaModule.exports,
        label: 'Exports privacy QA',
        owner: 'maintainiac-qa',
        status: MaintainiacModuleSuiteStatus.executable,
        priority: MaintainiacQaCasePriority.releaseBlocker,
        command: 'flutter test test/maintainiac_export_privacy_test.dart',
        behaviors: [
          'Exports include only active-account records.',
          'Private keys and raw receipt text are rejected or sanitized.',
          'Export artifacts stay redacted and in approved paths.',
        ],
        tags: {'exports', 'privacy', 'redaction'},
      ),
      MaintainiacModuleSuiteContract(
        id: 'suite_payments',
        module: MaintainiacQaModule.payments,
        label: 'Payments record QA',
        owner: 'maintainiac-qa',
        status: MaintainiacModuleSuiteStatus.executable,
        priority: MaintainiacQaCasePriority.standard,
        command: 'flutter test test/maintainiac_payment_contract_test.dart',
        behaviors: [
          'Payments never store card numbers.',
          'Payment records link to invoices without mutating source totals.',
          'Refunds and adjustments are deterministic ledger entries.',
        ],
        tags: {'payments', 'privacy', 'money'},
      ),
    ]);
  }

  final List<MaintainiacModuleSuiteContract> suites;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    if (suites.isEmpty) failures.add('module suite matrix is empty');
    for (final suite in suites) {
      if (!ids.add(suite.id)) {
        failures.add('duplicate module suite id ${suite.id}');
      }
      failures.addAll(suite.validate());
    }
    for (final requiredModule in {
      MaintainiacQaModule.inventory,
      MaintainiacQaModule.expenses,
      MaintainiacQaModule.jobs,
      MaintainiacQaModule.estimates,
      MaintainiacQaModule.calendar,
      MaintainiacQaModule.maintenance,
      MaintainiacQaModule.fleet,
      MaintainiacQaModule.exports,
      MaintainiacQaModule.payments,
    }) {
      if (!suites.any((suite) => suite.module == requiredModule)) {
        failures.add('module suite matrix missing ${requiredModule.name}');
      }
    }
    return failures;
  }

  List<String> executableCommands() {
    return [
      for (final suite in suites)
        if (suite.status == MaintainiacModuleSuiteStatus.executable)
          suite.command,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'suiteCount': suites.length,
      'executableCount': executableCommands().length,
      'commands': executableCommands(),
      'suites': [for (final suite in suites) suite.toJson()],
    };
  }
}
