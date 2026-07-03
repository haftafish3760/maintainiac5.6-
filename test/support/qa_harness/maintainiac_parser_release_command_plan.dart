import 'maintainiac_expense_parser_consumer_contract.dart';
import 'maintainiac_inventory_parser_consumer_contract.dart';
import 'maintainiac_surgical_test_selector.dart';

enum MaintainiacParserCommandTier { surgical, smoke, focused, release }

class MaintainiacParserReleaseCommand {
  const MaintainiacParserReleaseCommand({
    required this.id,
    required this.tier,
    required this.command,
    required this.reason,
    required this.coveredFamilies,
  });

  final String id;
  final MaintainiacParserCommandTier tier;
  final String command;
  final String reason;
  final Set<String> coveredFamilies;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('parser command missing id');
    if (!command.startsWith('flutter test ')) {
      failures.add('$id must use focused flutter test command');
    }
    if (reason.trim().isEmpty) failures.add('$id missing reason');
    if (coveredFamilies.isEmpty) failures.add('$id missing covered families');
    final lower = command.toLowerCase();
    if (lower.contains('firebase') ||
        lower.contains('firestore') ||
        lower.contains('camera') ||
        lower.contains('mlkit') ||
        lower.contains('googlevision')) {
      failures.add('$id must stay offline and outside OCR/camera');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'tier': tier.name,
      'command': command,
      'reason': reason,
      'coveredFamilies': coveredFamilies.toList()..sort(),
    };
  }
}

class MaintainiacParserReleaseCommandPlan {
  const MaintainiacParserReleaseCommandPlan(this.commands);

  final List<MaintainiacParserReleaseCommand> commands;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final covered = <String>{};
    for (final command in commands) {
      if (!ids.add(command.id)) {
        failures.add('duplicate parser command ${command.id}');
      }
      covered.addAll(command.coveredFamilies);
      failures.addAll(command.validate());
    }
    if (!commands.any(
      (command) => command.tier == MaintainiacParserCommandTier.smoke,
    )) {
      failures.add('parser command plan missing smoke tier');
    }
    if (maintainiacSurgicalTestSelectorRegistry.selectors.isEmpty) {
      failures.add('parser command plan missing surgical selectors');
    }
    if (!commands.any(
      (command) => command.tier == MaintainiacParserCommandTier.focused,
    )) {
      failures.add('parser command plan missing focused tier');
    }
    if (!commands.any(
      (command) => command.tier == MaintainiacParserCommandTier.release,
    )) {
      failures.add('parser command plan missing release tier');
    }
    for (final familyId in [
      for (final family in maintainiacInventoryParserConsumerContract.families)
        family.id,
      for (final family in maintainiacExpenseParserConsumerContract.families)
        family.id,
    ]) {
      if (!covered.contains(familyId)) {
        failures.add('parser command plan misses family $familyId');
      }
    }
    return failures;
  }

  List<String> commandsFor(MaintainiacParserCommandTier tier) {
    if (tier == MaintainiacParserCommandTier.surgical) {
      return [
        for (final selector
            in maintainiacSurgicalTestSelectorRegistry.selectors)
          selector.command,
      ];
    }
    return [
      for (final command in commands)
        if (command.tier == tier) command.command,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'commandCount': commands.length,
      'surgicalSelectorCount':
          maintainiacSurgicalTestSelectorRegistry.selectors.length,
      'smokeCommands': commandsFor(MaintainiacParserCommandTier.smoke),
      'surgicalCommands': commandsFor(MaintainiacParserCommandTier.surgical),
      'focusedCommands': commandsFor(MaintainiacParserCommandTier.focused),
      'releaseCommands': commandsFor(MaintainiacParserCommandTier.release),
      'commands': [for (final command in commands) command.toJson()],
    };
  }
}

const maintainiacParserReleaseCommandPlan = MaintainiacParserReleaseCommandPlan([
  MaintainiacParserReleaseCommand(
    id: 'parser_consumer_gate_smoke',
    tier: MaintainiacParserCommandTier.smoke,
    command: 'flutter test test/maintainiac_parser_consumer_gate_test.dart',
    reason:
        'Fast proof that inventory and expense parser consumers stay wired.',
    coveredFamilies: {
      'catalog_schema_metadata',
      'parser_result_review',
      'generated_batch_runner',
      'draft_storage_lifecycle',
    },
  ),
  MaintainiacParserReleaseCommand(
    id: 'inventory_consumer_focused',
    tier: MaintainiacParserCommandTier.focused,
    command:
        'flutter test test/maintainiac_inventory_parser_consumer_test.dart',
    reason: 'Focused inventory parser consumer contract and file coverage.',
    coveredFamilies: {
      'catalog_schema_metadata',
      'alias_vendor_sku',
      'dangerous_ambiguity_context',
      'receipt_fixture_corpus',
      'security_privacy_attack_surface',
      'performance_scalability',
      'locale_spanish_release_one',
      'workflow_routing',
      'sync_authority',
      'financial_math',
      'pack_lifecycle_recovery',
      'generated_batch_runner',
    },
  ),
  MaintainiacParserReleaseCommand(
    id: 'expense_consumer_focused',
    tier: MaintainiacParserCommandTier.focused,
    command: 'flutter test test/maintainiac_expense_parser_consumer_test.dart',
    reason: 'Focused expense parser consumer contract and file coverage.',
    coveredFamilies: {
      'parser_result_review',
      'draft_storage_lifecycle',
      'ledger_financial_math',
      'category_classification',
      'privacy_redaction',
      'materials_bridge',
      'failure_diagnostics',
      'telemetry_boundary',
    },
  ),
  MaintainiacParserReleaseCommand(
    id: 'backbone_release_parser_consumers',
    tier: MaintainiacParserCommandTier.release,
    command: 'flutter test test/maintainiac_qa_backbone_test.dart',
    reason:
        'Release gate proves parser consumers are visible from the main QA backbone.',
    coveredFamilies: {
      'catalog_schema_metadata',
      'alias_vendor_sku',
      'dangerous_ambiguity_context',
      'receipt_fixture_corpus',
      'security_privacy_attack_surface',
      'performance_scalability',
      'locale_spanish_release_one',
      'workflow_routing',
      'sync_authority',
      'financial_math',
      'pack_lifecycle_recovery',
      'generated_batch_runner',
      'parser_result_review',
      'draft_storage_lifecycle',
      'ledger_financial_math',
      'category_classification',
      'privacy_redaction',
      'materials_bridge',
      'failure_diagnostics',
      'telemetry_boundary',
    },
  ),
]);
