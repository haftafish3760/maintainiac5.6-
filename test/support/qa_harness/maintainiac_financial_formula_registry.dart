enum MaintainiacMoneyRoundingPolicy {
  integerCentsOnly,
  allocateRemainderToLastLine,
  noRoundingAllowed,
}

class MaintainiacFinancialFormula {
  const MaintainiacFinancialFormula({
    required this.id,
    required this.module,
    required this.description,
    required this.inputs,
    required this.output,
    required this.roundingPolicy,
    required this.mutatesSourceRecords,
    required this.testCommand,
    required this.coveredScenarios,
  });

  final String id;
  final String module;
  final String description;
  final Set<String> inputs;
  final String output;
  final MaintainiacMoneyRoundingPolicy roundingPolicy;
  final bool mutatesSourceRecords;
  final String testCommand;
  final Set<String> coveredScenarios;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('formula missing id');
    if (module.trim().isEmpty) failures.add('$id missing module');
    if (description.trim().isEmpty) failures.add('$id missing description');
    if (inputs.isEmpty) failures.add('$id missing inputs');
    if (output.trim().isEmpty) failures.add('$id missing output');
    if (mutatesSourceRecords) {
      failures.add('$id financial formula must not mutate source records');
    }
    if (!testCommand.startsWith('flutter test ')) {
      failures.add('$id needs focused flutter test command');
    }
    if (!testCommand.contains('--plain-name')) {
      failures.add('$id should be individually runnable with --plain-name');
    }
    if (coveredScenarios.length < 2) {
      failures.add('$id needs explicit financial scenario coverage');
    }
    if (!coveredScenarios.contains('integer-cents')) {
      failures.add('$id must prove integer-cent handling');
    }
    if (roundingPolicy ==
            MaintainiacMoneyRoundingPolicy.allocateRemainderToLastLine &&
        !coveredScenarios.contains('remainder-allocation')) {
      failures.add('$id must prove remainder allocation');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'module': module,
      'description': description,
      'inputs': inputs.toList()..sort(),
      'output': output,
      'roundingPolicy': roundingPolicy.name,
      'mutatesSourceRecords': mutatesSourceRecords,
      'testCommand': testCommand,
      'coveredScenarios': coveredScenarios.toList()..sort(),
    };
  }
}

class MaintainiacFinancialFormulaRegistry {
  const MaintainiacFinancialFormulaRegistry(this.formulas);

  final List<MaintainiacFinancialFormula> formulas;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final modules = <String>{};
    for (final formula in formulas) {
      if (!ids.add(formula.id)) {
        failures.add('duplicate financial formula ${formula.id}');
      }
      modules.add(formula.module);
      failures.addAll(formula.validate());
    }
    final coverage = {
      for (final formula in formulas) ...formula.coveredScenarios,
    };
    for (final required in {
      'tax',
      'discount',
      'refund',
      'negative-adjustment',
      'remainder-allocation',
    }) {
      if (!coverage.contains(required)) {
        failures.add('financial formula registry missing coverage $required');
      }
    }
    for (final required in {
      'expenses',
      'inventory',
      'jobs',
      'estimates',
      'invoices',
      'payments',
    }) {
      if (!modules.contains(required)) {
        failures.add('financial formula registry missing module $required');
      }
    }
    return failures;
  }

  List<MaintainiacFinancialFormula> formulasFor(String module) {
    return [
      for (final formula in formulas)
        if (formula.module == module) formula,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'formulaCount': formulas.length,
      'modules': {for (final formula in formulas) formula.module}.toList()
        ..sort(),
      'formulas': [for (final formula in formulas) formula.toJson()],
    };
  }
}

const maintainiacFinancialFormulaRegistry = MaintainiacFinancialFormulaRegistry([
  MaintainiacFinancialFormula(
    id: 'expense_daily_total_cents',
    module: 'expenses',
    description: 'Daily expense total is the sum of confirmed line totals.',
    inputs: {'confirmedExpenseLineCents'},
    output: 'dailyExpenseTotalCents',
    roundingPolicy: MaintainiacMoneyRoundingPolicy.integerCentsOnly,
    mutatesSourceRecords: false,
    testCommand:
        'flutter test test/maintainiac_financial_ledger_test.dart --plain-name "financial ledger keeps deterministic expense totals"',
    coveredScenarios: {'integer-cents', 'tax', 'business-personal'},
  ),
  MaintainiacFinancialFormula(
    id: 'inventory_unit_loaded_cost',
    module: 'inventory',
    description:
        'Inventory loaded unit cost includes allocated tax and discounts in cents.',
    inputs: {'unitCostCents', 'quantity', 'taxCents', 'discountCents'},
    output: 'loadedUnitCostCents',
    roundingPolicy: MaintainiacMoneyRoundingPolicy.allocateRemainderToLastLine,
    mutatesSourceRecords: false,
    testCommand:
        'flutter test test/maintainiac_pricing_contract_test.dart --plain-name "pricing contract balances tax discount and markup lines"',
    coveredScenarios: {
      'integer-cents',
      'tax',
      'discount',
      'remainder-allocation',
    },
  ),
  MaintainiacFinancialFormula(
    id: 'job_material_total_cents',
    module: 'jobs',
    description: 'Job material total sums confirmed job material lines.',
    inputs: {'jobMaterialLineCostCents', 'quantity'},
    output: 'jobMaterialTotalCents',
    roundingPolicy: MaintainiacMoneyRoundingPolicy.integerCentsOnly,
    mutatesSourceRecords: false,
    testCommand:
        'flutter test test/maintainiac_job_contract_test.dart --plain-name "job contract accepts confirmed estimate and inventory material lines"',
    coveredScenarios: {'integer-cents', 'inventory-consumption'},
  ),
  MaintainiacFinancialFormula(
    id: 'estimate_trade_section_total',
    module: 'estimates',
    description:
        'Estimate trade section total sums read-only material and labor lines.',
    inputs: {'estimateLineCents', 'tradeSectionId'},
    output: 'estimateSectionTotalCents',
    roundingPolicy: MaintainiacMoneyRoundingPolicy.integerCentsOnly,
    mutatesSourceRecords: false,
    testCommand:
        'flutter test test/maintainiac_pricing_contract_test.dart --plain-name "pricing contract supports trade section rollups"',
    coveredScenarios: {'integer-cents', 'trade-section'},
  ),
  MaintainiacFinancialFormula(
    id: 'invoice_grand_total_cents',
    module: 'invoices',
    description:
        'Invoice grand total combines section subtotals, tax, discounts, and payments due.',
    inputs: {
      'sectionSubtotalCents',
      'taxCents',
      'discountCents',
      'paymentAppliedCents',
    },
    output: 'invoiceGrandTotalCents',
    roundingPolicy: MaintainiacMoneyRoundingPolicy.integerCentsOnly,
    mutatesSourceRecords: false,
    testCommand:
        'flutter test test/maintainiac_pricing_contract_test.dart --plain-name "pricing contract balances invoice grand totals"',
    coveredScenarios: {'integer-cents', 'tax', 'discount'},
  ),
  MaintainiacFinancialFormula(
    id: 'payment_balance_effect',
    module: 'payments',
    description:
        'Payment and refund records affect balance as deterministic ledger entries.',
    inputs: {'invoiceTotalCents', 'paymentCents', 'refundCents'},
    output: 'remainingBalanceCents',
    roundingPolicy: MaintainiacMoneyRoundingPolicy.noRoundingAllowed,
    mutatesSourceRecords: false,
    testCommand:
        'flutter test test/maintainiac_payment_contract_test.dart --plain-name "payment contract accepts payment and refund ledger effects"',
    coveredScenarios: {'integer-cents', 'refund', 'negative-adjustment'},
  ),
]);
