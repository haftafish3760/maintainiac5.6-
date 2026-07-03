enum MaintainiacSurgicalTestScope { singleBehavior, moduleSmoke, releaseGate }

class MaintainiacSurgicalTestSelector {
  const MaintainiacSurgicalTestSelector({
    required this.id,
    required this.scope,
    required this.file,
    required this.plainName,
    required this.reason,
    required this.tags,
  });

  final String id;
  final MaintainiacSurgicalTestScope scope;
  final String file;
  final String plainName;
  final String reason;
  final Set<String> tags;

  String get command => 'flutter test $file --plain-name "$plainName"';

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) {
      failures.add('surgical selector missing id');
    }
    if (!file.startsWith('test/') || !file.endsWith('.dart')) {
      failures.add('$id must target one Dart test file');
    }
    if (scope != MaintainiacSurgicalTestScope.singleBehavior) {
      failures.add('$id must be an individual single-behavior selector');
    }
    if (plainName.trim().isEmpty) {
      failures.add('$id missing plain-name selector');
    }
    if (reason.trim().isEmpty) {
      failures.add('$id missing reason');
    }
    if (tags.length < 2) {
      failures.add('$id needs searchable tags');
    }
    final lower = command.toLowerCase();
    final mentionsFirestore = lower.contains('firestore');
    final allowedMirrorContract =
        lower.contains('firestore mirror') ||
        _isOfflineFirestoreContractCommand(lower);
    final mentionsBlockedProvider =
        lower.contains('camera') ||
        lower.contains('ocr') ||
        lower.contains('mlkit') ||
        lower.contains('googlevision');
    if ((mentionsBlockedProvider && !allowedMirrorContract) ||
        lower.contains('firebase') ||
        (mentionsFirestore && !allowedMirrorContract)) {
      failures.add(
        '$id selector must stay offline and outside OCR/camera/live Firebase',
      );
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'scope': scope.name,
      'file': file,
      'plainName': plainName,
      'command': command,
      'reason': reason,
      'tags': tags.toList()..sort(),
    };
  }
}

bool _isOfflineFirestoreContractCommand(String lowerCommand) {
  return lowerCommand.contains('maintainiac_firestore_schema_test.dart') ||
      lowerCommand.contains('maintainiac_firestore_upload_queue_test.dart') ||
      lowerCommand.contains('maintainiac_firestore_documents_test.dart') ||
      lowerCommand.contains('maintainiac_hosted_cache_test.dart');
}

class MaintainiacSurgicalTestSelectorRegistry {
  const MaintainiacSurgicalTestSelectorRegistry(this.selectors);

  final List<MaintainiacSurgicalTestSelector> selectors;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final commandSet = <String>{};
    final tags = <String>{};
    for (final selector in selectors) {
      if (!ids.add(selector.id)) {
        failures.add('duplicate surgical selector ${selector.id}');
      }
      if (!commandSet.add(selector.command)) {
        failures.add('duplicate surgical command ${selector.command}');
      }
      tags.addAll(selector.tags);
      failures.addAll(selector.validate());
    }
    if (!selectors.any(
      (selector) =>
          selector.scope == MaintainiacSurgicalTestScope.singleBehavior,
    )) {
      failures.add('surgical registry missing single-behavior selectors');
    }
    for (final required in {
      'inventory',
      'expenses',
      'parser-consumer',
      'privacy',
      'source-of-truth',
      'regression',
    }) {
      if (!tags.contains(required)) {
        failures.add('surgical registry missing tag $required');
      }
    }
    return failures;
  }

  List<String> commandsForTag(String tag) {
    return [
      for (final selector in selectors)
        if (selector.tags.contains(tag)) selector.command,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'selectorCount': selectors.length,
      'singleBehaviorCount': selectors
          .where(
            (selector) =>
                selector.scope == MaintainiacSurgicalTestScope.singleBehavior,
          )
          .length,
      'selectors': [for (final selector in selectors) selector.toJson()],
    };
  }
}

const maintainiacSurgicalTestSelectorRegistry = MaintainiacSurgicalTestSelectorRegistry([
  MaintainiacSurgicalTestSelector(
    id: 'inventory_consumer_family_labels',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_inventory_parser_consumer_test.dart',
    plainName: 'inventory parser consumer labels broad release-one QA families',
    reason:
        'Run only the inventory parser consumer breadth contract after family edits.',
    tags: {'inventory', 'parser-consumer', 'release-one'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'inventory_consumer_file_refs',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_inventory_parser_consumer_test.dart',
    plainName: 'inventory parser consumer references existing QA support files',
    reason:
        'Run only the inventory parser file-reference check after moving QA files.',
    tags: {'inventory', 'parser-consumer', 'source-of-truth'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'inventory_consumer_focused_offline',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_inventory_parser_consumer_test.dart',
    plainName: 'inventory parser consumer keeps commands focused and offline',
    reason:
        'Run only the inventory parser command safety check after command edits.',
    tags: {'inventory', 'parser-consumer', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'inventory_consumer_fake_narrow',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_inventory_parser_consumer_test.dart',
    plainName: 'inventory parser consumer rejects fake narrow coverage',
    reason:
        'Run only the inventory parser negative coverage check after readiness edits.',
    tags: {'inventory', 'parser-consumer', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'expense_consumer_family_labels',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_expense_parser_consumer_test.dart',
    plainName: 'expense parser consumer labels broad release-one QA families',
    reason:
        'Run only the expense parser consumer breadth contract after family edits.',
    tags: {'expenses', 'parser-consumer', 'release-one'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'expense_consumer_file_refs',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_expense_parser_consumer_test.dart',
    plainName: 'expense parser consumer references existing QA files',
    reason:
        'Run only the expense parser file-reference check after moving QA files.',
    tags: {'expenses', 'parser-consumer', 'source-of-truth'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'expense_consumer_focused_no_camera',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_expense_parser_consumer_test.dart',
    plainName:
        'expense parser consumer keeps commands focused and provider-free',
    reason:
        'Run only the expense parser command boundary check after command edits.',
    tags: {'expenses', 'parser-consumer', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'expense_consumer_unsafe_readiness',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_expense_parser_consumer_test.dart',
    plainName: 'expense parser consumer rejects unsafe fake readiness',
    reason:
        'Run only the expense parser negative safety contract after policy edits.',
    tags: {'expenses', 'parser-consumer', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'auth_policy_hosted_login_providers',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_auth_policy_test.dart',
    plainName: 'hosted account login allows only Google and Apple providers',
    reason: 'Run only the hosted-login provider allowlist check.',
    tags: {'auth', 'security', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'auth_policy_small_provider_set',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_auth_policy_test.dart',
    plainName: 'allowed provider set remains intentionally small',
    reason: 'Run only the auth provider-set drift guard.',
    tags: {'auth', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'export_privacy_accepts_owned_records',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_export_privacy_test.dart',
    plainName: 'export privacy probe accepts owned non-private records',
    reason: 'Run only the owned safe export privacy check.',
    tags: {'exports', 'privacy', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'export_privacy_catches_cross_account',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_export_privacy_test.dart',
    plainName: 'export privacy probe catches cross-account and private fields',
    reason: 'Run only the cross-account/private-field export guard.',
    tags: {'exports', 'privacy', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'export_privacy_sanitizes_private_fields',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_export_privacy_test.dart',
    plainName: 'export privacy probe sanitizes private fields before writing',
    reason: 'Run only the export redaction/sanitization check.',
    tags: {'exports', 'privacy', 'security', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'export_privacy_matrix_blocks_leaks',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_export_privacy_test.dart',
    plainName: 'export privacy matrix blocks cross-account and identity leaks',
    reason: 'Run only the export privacy matrix leak guard.',
    tags: {'exports', 'privacy', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'export_privacy_matrix_rejects_gaps',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_export_privacy_test.dart',
    plainName: 'export privacy matrix rejects incomplete case coverage',
    reason: 'Run only the export privacy coverage-gap guard.',
    tags: {'exports', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scope_policy_owner_vehicle_permission',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_scope_policy_test.dart',
    plainName:
        'scope policy allows account owner with assigned vehicle permission',
    reason: 'Run only the owner/vehicle permission allow check.',
    tags: {'security', 'profiles', 'vehicles', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scope_policy_denies_cross_account_vehicle',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_scope_policy_test.dart',
    plainName:
        'scope policy denies cross-account and unassigned vehicle access',
    reason: 'Run only the cross-account/unassigned vehicle denial check.',
    tags: {'security', 'profiles', 'vehicles', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scope_policy_employee_permission_match',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_scope_policy_test.dart',
    plainName: 'scope policy requires company employee and permission match',
    reason: 'Run only the company employee permission match check.',
    tags: {'security', 'employees', 'fleet', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scope_policy_matrix_denials',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_scope_policy_test.dart',
    plainName:
        'scope policy matrix covers fleet company employee and vehicle denials',
    reason: 'Run only the fleet/company/employee denial matrix.',
    tags: {'security', 'employees', 'fleet', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scope_policy_matrix_rejects_missing_reasons',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_scope_policy_test.dart',
    plainName: 'scope policy matrix rejects missing denial explanations',
    reason: 'Run only the denial-explanation coverage guard.',
    tags: {'security', 'employees', 'fleet', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'sensitive_field_registry_covers_forbidden',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_sensitive_field_registry_test.dart',
    plainName: 'sensitive field registry covers privacy forbidden data classes',
    reason: 'Run only the forbidden sensitive data class coverage check.',
    tags: {'privacy', 'security', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'sensitive_field_registry_rejects_bad_classes',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_sensitive_field_registry_test.dart',
    plainName:
        'sensitive field registry rejects duplicates and missing classes',
    reason: 'Run only the sensitive field registry negative guard.',
    tags: {'privacy', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'source_boundary_catches_live_services',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_source_boundary_test.dart',
    plainName: 'source boundary scanner catches forbidden live-service code',
    reason: 'Run only the forbidden live-service boundary scan.',
    tags: {'security', 'source-boundary', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'source_boundary_allows_emulators',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_source_boundary_test.dart',
    plainName: 'source boundary scanner honors allowed emulator paths',
    reason: 'Run only the emulator allowlist boundary scan.',
    tags: {'security', 'source-boundary', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'source_boundary_skips_build_folders',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_source_boundary_test.dart',
    plainName: 'source boundary scanner skips generated build folders',
    reason: 'Run only the generated build-folder skip boundary scan.',
    tags: {'security', 'source-boundary', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_consumer_gate_combined',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_consumer_gate_test.dart',
    plainName:
        'parser consumer gate validates inventory and expense consumers together',
    reason:
        'Run only the combined parser consumer gate after inventory or expense consumer changes.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_consumer_gate_rejects_unsafe',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_consumer_gate_test.dart',
    plainName: 'parser consumer gate rejects unsafe or narrow consumers',
    reason:
        'Run only the parser consumer gate negative safety check after policy edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_candidate_preserves_review_evidence',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_candidate_contract_test.dart',
    plainName:
        'parser candidate contract preserves review-only inventory evidence',
    reason: 'Run only the parser candidate review-evidence contract.',
    tags: {'inventory', 'parser-consumer', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_candidate_allows_user_confirmation',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_candidate_contract_test.dart',
    plainName:
        'parser candidate contract allows confirmed only after user action',
    reason: 'Run only the parser candidate user-confirmation contract.',
    tags: {'inventory', 'parser-consumer', 'source-of-truth', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_candidate_rejects_autosave',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_candidate_contract_test.dart',
    plainName:
        'parser candidate contract rejects autosave and false confirmation',
    reason: 'Run only the parser candidate autosave rejection guard.',
    tags: {'inventory', 'parser-consumer', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'correction_learning_reviewable_proposals',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_correction_learning_contract_test.dart',
    plainName:
        'correction learning contract creates reviewable parser proposals',
    reason: 'Run only the reviewable correction proposal contract.',
    tags: {'parser-consumer', 'corrections', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'correction_learning_regression_metadata',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_correction_learning_contract_test.dart',
    plainName: 'correction learning contract requires regression metadata',
    reason: 'Run only the correction learning regression metadata guard.',
    tags: {'parser-consumer', 'corrections', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'correction_learning_blocks_silent_mutation',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_correction_learning_contract_test.dart',
    plainName: 'correction learning contract blocks silent pack mutation',
    reason: 'Run only the silent pack mutation rejection guard.',
    tags: {'parser-consumer', 'corrections', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'derived_output_read_only',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_derived_output_contract_test.dart',
    plainName: 'derived output contract keeps reports and invoices read-only',
    reason: 'Run only the derived output read-only contract.',
    tags: {'source-of-truth', 'derived-output', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'derived_output_rejects_mutation_ambiguity',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_derived_output_contract_test.dart',
    plainName: 'derived output contract rejects source mutation ambiguity',
    reason: 'Run only the derived output mutation ambiguity guard.',
    tags: {'source-of-truth', 'derived-output', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'device_capability_full_local_high_end',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_device_capability_test.dart',
    plainName:
        'device capability probe allows full local packs on high-end devices',
    reason: 'Run only the high-end full local pack capability check.',
    tags: {'device', 'inventory', 'performance', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'device_capability_low_storage_fallback',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_device_capability_test.dart',
    plainName:
        'device capability probe falls back for low-storage older phones',
    reason: 'Run only the low-storage older-device fallback check.',
    tags: {'device', 'inventory', 'performance', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'device_capability_blocks_unsafe_cloud',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_device_capability_test.dart',
    plainName:
        'device capability probe blocks unsafe or offline cloud-only cases',
    reason: 'Run only the unsafe/offline cloud-only capability guard.',
    tags: {'device', 'inventory', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'device_delivery_matrix_modes',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_device_capability_test.dart',
    plainName:
        'device delivery matrix covers local compact cloud and blocked modes',
    reason: 'Run only the device delivery mode matrix.',
    tags: {'device', 'inventory', 'performance', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'device_delivery_matrix_rejects_unsafe',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_device_capability_test.dart',
    plainName:
        'device delivery matrix rejects unsafe cloud and App Check cases',
    reason: 'Run only the device delivery unsafe cloud/App Check guard.',
    tags: {'device', 'inventory', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'job_contract_confirmed_estimate_materials',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_job_contract_test.dart',
    plainName:
        'job contract accepts confirmed estimate and inventory material lines',
    reason: 'Run only the confirmed estimate/material job contract.',
    tags: {'jobs', 'inventory', 'estimates', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'job_contract_receipt_backed_time_material',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_job_contract_test.dart',
    plainName: 'job contract accepts receipt-backed time and material job',
    reason: 'Run only the receipt-backed time and material job contract.',
    tags: {'jobs', 'inventory', 'expenses', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'job_contract_rejects_unsafe_summary',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_job_contract_test.dart',
    plainName: 'job contract rejects unsafe material and summary behavior',
    reason: 'Run only the unsafe job material/summary guard.',
    tags: {'jobs', 'inventory', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'pricing_contract_balances_lines',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_pricing_contract_test.dart',
    plainName:
        'pricing contract balances estimate and invoice line totals in cents',
    reason: 'Run only the estimate/invoice line total pricing contract.',
    tags: {'pricing', 'financial', 'estimates', 'invoices', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'pricing_contract_allocates_tax_remainders',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_pricing_contract_test.dart',
    plainName:
        'pricing contract allocates tax remainders deterministically per unit',
    reason: 'Run only the deterministic tax remainder allocation check.',
    tags: {'pricing', 'financial', 'tax', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'pricing_contract_rejects_unsafe_money',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_pricing_contract_test.dart',
    plainName: 'pricing contract rejects unsafe money and source mutation',
    reason: 'Run only the unsafe pricing money/source mutation guard.',
    tags: {'pricing', 'financial', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'fixture_governance_release_families',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_fixture_governance_gate_test.dart',
    plainName: 'fixture governance gate covers release fixture families',
    reason: 'Run only the fixture governance release-family check.',
    tags: {'fixtures', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'fixture_governance_rejects_weak_rules',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_fixture_governance_gate_test.dart',
    plainName: 'fixture governance gate rejects private or weak fixture rules',
    reason: 'Run only the private/weak fixture governance guard.',
    tags: {'fixtures', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_fixture_manifest_roles',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_fixture_manifest_test.dart',
    plainName:
        'parser fixture manifest separates golden holdout regression and malformed roles',
    reason: 'Run only the parser fixture role separation contract.',
    tags: {'fixtures', 'parser-consumer', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_fixture_manifest_rejects_gaps',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_fixture_manifest_test.dart',
    plainName: 'parser fixture manifest rejects unsafe fixture governance gaps',
    reason: 'Run only the parser fixture governance-gap guard.',
    tags: {'fixtures', 'parser-consumer', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'regression_registry_permanent_bug_fixtures',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_regression_registry_test.dart',
    plainName: 'regression registry records permanent bug fixtures by area',
    reason: 'Run only the permanent regression bug fixture registry check.',
    tags: {'regression', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'regression_registry_rejects_incomplete',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_regression_registry_test.dart',
    plainName:
        'regression registry rejects non-permanent or incomplete bug records',
    reason: 'Run only the incomplete/non-permanent regression guard.',
    tags: {'regression', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'failure_taxonomy_classifies_families',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_failure_taxonomy_test.dart',
    plainName: 'failure taxonomy classifies common QA failure families',
    reason: 'Run only the common QA failure family classification check.',
    tags: {'failure-taxonomy', 'quality-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'failure_taxonomy_summarizes_buckets',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_failure_taxonomy_test.dart',
    plainName: 'failure taxonomy summarizes failure buckets',
    reason: 'Run only the QA failure bucket summary check.',
    tags: {'failure-taxonomy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'performance_budget_labels_budgets',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_performance_budget_registry_test.dart',
    plainName: 'performance budget registry labels harness performance budgets',
    reason: 'Run only the performance budget labeling check.',
    tags: {'performance', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'performance_budget_rejects_missing',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_performance_budget_registry_test.dart',
    plainName: 'performance budget registry rejects missing or broad budgets',
    reason: 'Run only the missing/broad performance budget guard.',
    tags: {'performance', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'performance_budget_rejects_broad_flutter',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_performance_budget_registry_test.dart',
    plainName: 'performance budget registry rejects broad Flutter measurements',
    reason: 'Run only the broad Flutter performance measurement guard.',
    tags: {'performance', 'tooling', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'release_gate_plan_exposes_core_plan',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_release_gate_plan_test.dart',
    plainName:
        'release gate plan exposes release blocker and core command plan',
    reason: 'Run only the release blocker/core command plan check.',
    tags: {'release-gate', 'quality-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'release_gate_plan_rejects_missing_priority',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_release_gate_plan_test.dart',
    plainName: 'release gate plan rejects missing name or priorities',
    reason: 'Run only the release gate plan name/priority guard.',
    tags: {'release-gate', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'release_gate_plan_requires_blocker_commands',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_release_gate_plan_test.dart',
    plainName: 'release gate plan requires commands for release blockers',
    reason: 'Run only the release blocker command coverage guard.',
    tags: {'release-gate', 'quality-gate', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'release_gate_plan_requires_surgical_core',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_release_gate_plan_test.dart',
    plainName: 'release gate plan requires surgical commands for core checks',
    reason: 'Run only the core-check surgical command guard.',
    tags: {'release-gate', 'tooling', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'module_boundary_labels_safe_lanes',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_module_boundary_gate_test.dart',
    plainName: 'module boundary gate labels safe QA lanes',
    reason: 'Run only the module boundary safe-lane label check.',
    tags: {'module-boundary', 'quality-gate', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'module_boundary_rejects_weak_lanes',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_module_boundary_gate_test.dart',
    plainName: 'module boundary gate rejects weak or missing lanes',
    reason: 'Run only the weak/missing module boundary lane guard.',
    tags: {'module-boundary', 'quality-gate', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'module_suite_labels_release_one',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_module_suite_contract_test.dart',
    plainName: 'module suite matrix labels release-one module QA coverage',
    reason: 'Run only the release-one module suite coverage check.',
    tags: {'module-suite', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'module_suite_executable_release_one',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_module_suite_contract_test.dart',
    plainName:
        'module suite matrix now makes release-one module suites executable',
    reason: 'Run only the executable release-one module suite check.',
    tags: {'module-suite', 'tooling', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'module_suite_rejects_unsafe_unlabeled',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_module_suite_contract_test.dart',
    plainName: 'module suite matrix rejects unsafe or unlabeled suites',
    reason: 'Run only the unsafe/unlabeled module suite guard.',
    tags: {'module-suite', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'schedule_contract_accepts_audited_records',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_schedule_contract_test.dart',
    plainName:
        'schedule contract accepts audited jobs and maintenance reminders',
    reason: 'Run only the audited job/maintenance schedule contract.',
    tags: {'calendar', 'jobs', 'maintenance', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'schedule_contract_denied_notifications',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_schedule_contract_test.dart',
    plainName: 'schedule contract respects denied notification permission',
    reason: 'Run only the denied notification permission schedule check.',
    tags: {'calendar', 'notifications', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'schedule_contract_rejects_unsafe_records',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_schedule_contract_test.dart',
    plainName: 'schedule contract rejects unsafe calendar and reminder records',
    reason: 'Run only the unsafe calendar/reminder record guard.',
    tags: {'calendar', 'notifications', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'restart_lifecycle_offline_partial_sync',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_restart_lifecycle_gate_test.dart',
    plainName:
        'restart lifecycle gate covers offline and partial-sync recovery',
    reason: 'Run only the offline/partial-sync restart recovery check.',
    tags: {'restart', 'sync', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'restart_lifecycle_rejects_unsafe',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_restart_lifecycle_gate_test.dart',
    plainName: 'restart lifecycle gate rejects unsafe recovery scenarios',
    reason: 'Run only the unsafe restart recovery guard.',
    tags: {'restart', 'sync', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_case_registry_labels_evidence',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_case_registry_test.dart',
    plainName: 'QA case registry labels behavior evidence and priority',
    reason: 'Run only the QA case behavior evidence/priority check.',
    tags: {'qa-registry', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_case_registry_rejects_duplicate_unlabeled',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_case_registry_test.dart',
    plainName: 'QA case registry rejects duplicate and unlabeled cases',
    reason: 'Run only the duplicate/unlabeled QA case guard.',
    tags: {'qa-registry', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_telemetry_privacy_covers_surfaces',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_telemetry_privacy_gate_test.dart',
    plainName: 'QA telemetry privacy gate covers report and admin surfaces',
    reason: 'Run only the telemetry privacy report/admin surface check.',
    tags: {'telemetry', 'privacy', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_telemetry_privacy_rejects_missing_redaction',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_telemetry_privacy_gate_test.dart',
    plainName:
        'QA telemetry privacy gate rejects missing redaction and overlap',
    reason: 'Run only the telemetry missing-redaction/overlap guard.',
    tags: {'telemetry', 'privacy', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_execution_manifest_labels_checks',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_execution_manifest_test.dart',
    plainName: 'QA execution manifest labels every runnable release-one check',
    reason: 'Run only the runnable release-one execution manifest label check.',
    tags: {'qa-execution', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_execution_manifest_separates_gates',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_execution_manifest_test.dart',
    plainName:
        'QA execution manifest separates focused checks from release gates',
    reason: 'Run only the focused-vs-release-gate separation check.',
    tags: {'qa-execution', 'tooling', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_execution_manifest_dedupes_surgical',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_execution_manifest_test.dart',
    plainName: 'QA execution manifest provides deduped surgical command plans',
    reason: 'Run only the deduped surgical command plan check.',
    tags: {'qa-execution', 'tooling', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_execution_manifest_rejects_unsafe',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_execution_manifest_test.dart',
    plainName: 'QA execution manifest rejects unlabeled or live-service checks',
    reason: 'Run only the unlabeled/live-service execution manifest guard.',
    tags: {'qa-execution', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_fingerprint_stable_order_line_endings',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_fingerprint_test.dart',
    plainName: 'QA fingerprint is stable across file order and line endings',
    reason: 'Run only the stable QA fingerprint normalization check.',
    tags: {'qa-fingerprint', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_fingerprint_changes_on_fixture_content',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_fingerprint_test.dart',
    plainName: 'QA fingerprint changes when fixture content changes',
    reason: 'Run only the QA fingerprint content-change check.',
    tags: {'qa-fingerprint', 'fixtures', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_fingerprint_rejects_weak_evidence',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_fingerprint_test.dart',
    plainName: 'QA fingerprint rejects unlabeled and unnormalized evidence',
    reason: 'Run only the unlabeled/unnormalized fingerprint evidence guard.',
    tags: {'qa-fingerprint', 'fixtures', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_run_ledger_skips_clean_focused',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_run_ledger_test.dart',
    plainName: 'QA run ledger skips only unchanged clean focused commands',
    reason: 'Run only the clean focused command skip check.',
    tags: {'qa-run-ledger', 'tooling', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_run_ledger_failed_commands_actionable',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_run_ledger_test.dart',
    plainName:
        'QA run ledger keeps failed commands actionable before new feature work',
    reason: 'Run only the failed-command actionable evidence check.',
    tags: {'qa-run-ledger', 'quality-gate', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_run_ledger_rejects_weak_evidence',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_run_ledger_test.dart',
    plainName: 'QA run ledger rejects weak or misleading run evidence',
    reason: 'Run only the weak/misleading run evidence guard.',
    tags: {'qa-run-ledger', 'quality-gate', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_readiness_tracks_gaps',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_readiness_test.dart',
    plainName:
        'QA readiness ledger tracks completed backbone and remaining gaps',
    reason: 'Run only the readiness completed/gap tracking check.',
    tags: {'qa-readiness', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_readiness_evidence_files_exist',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_readiness_test.dart',
    plainName: 'QA readiness ledger dart evidence references existing files',
    reason: 'Run only the readiness evidence file existence check.',
    tags: {'qa-readiness', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_readiness_rejects_fake_ready',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_readiness_test.dart',
    plainName: 'QA readiness ledger rejects fake ready claims without evidence',
    reason: 'Run only the fake-ready readiness evidence guard.',
    tags: {'qa-readiness', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_readiness_rejects_weak_evidence',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_readiness_test.dart',
    plainName:
        'QA readiness ledger rejects duplicate blank or placeholder evidence',
    reason: 'Run only the readiness evidence strength and traceability guard.',
    tags: {'qa-readiness', 'regression', 'evidence'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_checkpoint_pushes_milestones',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_checkpoint_policy_test.dart',
    plainName: 'QA checkpoint policy pushes at milestones with local changes',
    reason: 'Run only the milestone checkpoint push policy check.',
    tags: {'qa-checkpoint', 'git', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_checkpoint_pushes_after_thirty',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_checkpoint_policy_test.dart',
    plainName:
        'QA checkpoint policy pushes after thirty minutes of changed work',
    reason: 'Run only the thirty-minute checkpoint push policy check.',
    tags: {'qa-checkpoint', 'git', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_checkpoint_skips_empty_fresh',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_checkpoint_policy_test.dart',
    plainName: 'QA checkpoint policy does not push empty or too-fresh batches',
    reason: 'Run only the empty/too-fresh checkpoint guard.',
    tags: {'qa-checkpoint', 'git', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_checkpoint_prioritizes_failures',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_checkpoint_policy_test.dart',
    plainName: 'QA checkpoint policy prioritizes failing gate evidence',
    reason: 'Run only the failing-gate checkpoint priority check.',
    tags: {'qa-checkpoint', 'quality-gate', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_cases_tool_release_blockers',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_cases_tool_test.dart',
    plainName: 'QA cases tool prints labeled release blockers',
    reason: 'Run only the QA cases release-blocker CLI check.',
    tags: {'qa-cases-tool', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_cases_tool_json_automation',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_cases_tool_test.dart',
    plainName: 'QA cases tool prints JSON for automation',
    reason: 'Run only the QA cases JSON automation CLI check.',
    tags: {'qa-cases-tool', 'tooling', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_cases_tool_rejects_unknown_priority',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_cases_tool_test.dart',
    plainName: 'QA cases tool rejects unknown priority',
    reason: 'Run only the QA cases unknown-priority guard.',
    tags: {'qa-cases-tool', 'tooling', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_schema_catalog_paths',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_schema_test.dart',
    plainName: 'Firestore schema exposes hosted catalog collection paths',
    reason: 'Run only the hosted catalog Firestore path schema check.',
    tags: {'firestore', 'schema', 'inventory', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_schema_command_center_paths',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_schema_test.dart',
    plainName:
        'Firestore schema exposes privacy-safe command center collections',
    reason: 'Run only the privacy-safe Command Center schema check.',
    tags: {'firestore', 'schema', 'privacy', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_schema_storage_chunk_prefix',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_schema_test.dart',
    plainName: 'Storage schema matches work supply catalog chunk prefix',
    reason: 'Run only the Storage chunk prefix schema check.',
    tags: {'storage', 'inventory', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_schema_docs_manifest_chunks',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_schema_test.dart',
    plainName:
        'Firestore docs describe manifest plus Storage chunks, not item docs',
    reason: 'Run only the docs contract for manifests/chunks vs item docs.',
    tags: {'firestore', 'docs', 'cost-quota', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_upload_queue_disabled',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_upload_queue_test.dart',
    plainName: 'queues safe documents but does not upload while disabled',
    reason: 'Run only the disabled Firestore upload queue check.',
    tags: {'firestore', 'sync', 'cost-quota', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_upload_queue_enabled_batches',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_upload_queue_test.dart',
    plainName: 'uploads enabled batches and marks records uploaded',
    reason: 'Run only the enabled batch upload queue check.',
    tags: {'firestore', 'sync', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_upload_queue_replaces_pending',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_upload_queue_test.dart',
    plainName: 'replaces pending documents for the same path',
    reason: 'Run only the pending-document replacement check.',
    tags: {'firestore', 'sync', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_upload_queue_retry_metadata',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_upload_queue_test.dart',
    plainName: 'retains failed writes with retry metadata',
    reason: 'Run only the failed-write retry metadata check.',
    tags: {'firestore', 'sync', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_upload_queue_max_batch',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_upload_queue_test.dart',
    plainName: 'enforces max batch size even when caller asks for more',
    reason: 'Run only the upload queue max batch size guard.',
    tags: {'firestore', 'cost-quota', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_upload_queue_rejects_unsafe',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_upload_queue_test.dart',
    plainName:
        'rejects unsafe paths, sensitive fields, and per-item catalog reads',
    reason: 'Run only the unsafe Firestore draft rejection guard.',
    tags: {'firestore', 'security', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_upload_queue_private_expense_backup_scope',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_upload_queue_test.dart',
    plainName:
        'allows private expense backup fields only under org expense records',
    reason: 'Run only the private expense backup scope check.',
    tags: {'firestore', 'expenses', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'hosted_cache_catalog_manifest_ttl',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_hosted_cache_test.dart',
    plainName: 'caches hosted catalog manifests with long TTL and sha256',
    reason: 'Run only the hosted catalog cache TTL/fingerprint check.',
    tags: {'hosted-cache', 'inventory', 'performance', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'hosted_cache_stale_usable_refresh',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_hosted_cache_test.dart',
    plainName: 'returns stale records as usable while signaling refresh needed',
    reason: 'Run only the stale usable cache refresh check.',
    tags: {'hosted-cache', 'sync', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'hosted_cache_strict_stale_miss',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_hosted_cache_test.dart',
    plainName: 'can treat stale records as misses for strict reads',
    reason: 'Run only the strict stale-as-miss hosted cache check.',
    tags: {'hosted-cache', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'hosted_cache_version_mismatch',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_hosted_cache_test.dart',
    plainName: 'version mismatch forces a cache miss',
    reason: 'Run only the hosted cache version mismatch check.',
    tags: {'hosted-cache', 'inventory', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'hosted_cache_rejects_private_bad_shape',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_hosted_cache_test.dart',
    plainName:
        'rejects private org data, receipt fields, and bad catalog shape',
    reason: 'Run only the hosted cache private/bad-shape rejection guard.',
    tags: {'hosted-cache', 'privacy', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'hosted_cache_clears_expired',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_hosted_cache_test.dart',
    plainName: 'clears expired records and keeps fresh records',
    reason: 'Run only the hosted cache expiration cleanup check.',
    tags: {'hosted-cache', 'performance', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'hosted_cache_sha_stable',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_hosted_cache_test.dart',
    plainName: 'sha256 fingerprint is stable regardless of map key order',
    reason: 'Run only the hosted cache stable SHA fingerprint check.',
    tags: {'hosted-cache', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_catalog_manifest_no_items',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName:
        'builds hosted catalog pack and manifest documents without item docs',
    reason: 'Run only the hosted catalog document shape contract.',
    tags: {'firestore', 'inventory', 'cost-quota', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_catalog_health_safe',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName: 'builds privacy-safe catalog health document',
    reason: 'Run only the catalog health privacy-safe document check.',
    tags: {'firestore', 'inventory', 'privacy', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_receipt_diagnostic_health',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName: 'builds receipt diagnostic and parser health documents safely',
    reason: 'Run only the receipt diagnostic/parser health safety contract.',
    tags: {'firestore', 'privacy', 'parser-consumer', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_expense_summary_no_raw_events',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName: 'builds expense telemetry summary without raw event upload',
    reason: 'Run only the expense telemetry summary upload-shape check.',
    tags: {'firestore', 'expenses', 'privacy', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_expense_summary_ocr_contract',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName: 'embeds privacy-safe OCR contract in expense telemetry summary',
    reason: 'Run only the privacy-safe expense summary OCR contract check.',
    tags: {'firestore', 'expenses', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_scheduler_trace_metrics',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName: 'keeps scheduler trace metrics in expense telemetry summary',
    reason: 'Run only the scheduler trace metric summary contract.',
    tags: {'firestore', 'expenses', 'sync', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_parser_ocr_failure_metrics',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName:
        'keeps parser and OCR failure metrics in expense telemetry summary',
    reason: 'Run only the parser/failure metric summary contract.',
    tags: {'firestore', 'expenses', 'parser-consumer', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_command_center_fields',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName:
        'keeps every Command Center telemetry field in Firestore summary',
    reason: 'Run only the Command Center summary field parity check.',
    tags: {'firestore', 'expenses', 'quality-gate', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_schema_helper_scoped',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName:
        'expense telemetry schema helper stays scoped to Command Center map',
    reason: 'Run only the telemetry schema helper scope check.',
    tags: {'firestore', 'expenses', 'schema', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_metadata_outside_local_schema',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName:
        'Firestore summary metadata stays outside local telemetry schema',
    reason: 'Run only the summary metadata/local schema separation check.',
    tags: {'firestore', 'expenses', 'schema', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_caps_failure_drilldowns',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName: 'caps expense telemetry failure drill-downs for Firestore',
    reason: 'Run only the failure drill-down cap check.',
    tags: {'firestore', 'expenses', 'performance', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_failure_drilldown_schema',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName: 'keeps failure drill-down object schemas stable for Firestore',
    reason: 'Run only the failure drill-down object schema contract.',
    tags: {'firestore', 'expenses', 'schema', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_scrubs_private_receipt_hints',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName: 'scrubs private receipt hints from failure drill-down text',
    reason: 'Run only the failure drill-down private receipt redaction check.',
    tags: {'firestore', 'expenses', 'privacy', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_stress_scrubs_private_hints',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName: 'stress scrubs fuel auto barcode and currency failure hints',
    reason: 'Run only the private hint redaction stress check.',
    tags: {'firestore', 'expenses', 'privacy', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_redaction_scope',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName: 'keeps redaction scoped to failure detail fields',
    reason: 'Run only the redaction boundary/scope check.',
    tags: {'firestore', 'expenses', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_redaction_helper_alignment',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName: 'keeps Firestore redaction helper fields aligned with contract',
    reason: 'Run only the redaction helper contract alignment check.',
    tags: {'firestore', 'expenses', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_rejects_invalid_scalars',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName:
        'rejects invalid expense telemetry scalar values before Firestore',
    reason: 'Run only the invalid telemetry scalar rejection check.',
    tags: {'firestore', 'expenses', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_sanitizes_maps_labels',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName: 'sanitizes expense telemetry maps and drill-down labels',
    reason: 'Run only the telemetry map and drill-down label sanitizer check.',
    tags: {'firestore', 'expenses', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_rejects_unsafe_ocr_contract',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName: 'rejects unsafe OCR contract before Firestore queueing',
    reason: 'Run only the unsafe summary contract rejection check.',
    tags: {'firestore', 'expenses', 'privacy', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_detects_unsafe_summary_drift',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName: 'detects unsafe OCR Firestore summary document drift',
    reason: 'Run only the unsafe summary document drift detector.',
    tags: {'firestore', 'expenses', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'firestore_docs_shared_correction_hashes',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_firestore_documents_test.dart',
    plainName:
        'builds shared correction candidate with hashes, not receipt text',
    reason: 'Run only the shared correction candidate hash/privacy check.',
    tags: {'firestore', 'corrections', 'privacy', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_backbone_tool_writes_redacted_artifacts',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_backbone_tool_test.dart',
    plainName: 'Maintainiac QA backbone tool writes redacted report artifacts',
    reason: 'Run only the QA backbone tool artifact/redaction check.',
    tags: {'qa-backbone', 'artifact-policy', 'privacy', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_regression_bindings',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_regression_binding_test.dart',
    plainName:
        'parser regression bindings cover required consumer risk families',
    reason:
        'Run only parser regression binding coverage after bug fixture changes.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_regression_rejects_bad_bindings',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_regression_binding_test.dart',
    plainName:
        'parser regression bindings reject duplicate or unowned regressions',
    reason:
        'Run only the parser regression negative contract after registry edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_release_command_covers_families',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_release_command_plan_test.dart',
    plainName:
        'parser release command plan covers every parser consumer family',
    reason:
        'Run only the command-plan coverage check after release command edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_release_command_rejects_unsafe',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_release_command_plan_test.dart',
    plainName:
        'parser release command plan rejects unsafe commands and missing tiers',
    reason:
        'Run only the command-plan negative check after command policy edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_selector_registry_commands',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_test_selector_test.dart',
    plainName:
        'surgical selector registry exposes individual plain-name commands',
    reason:
        'Run only the selector registry positive check after adding selectors.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_selector_registry_rejects_bad',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_test_selector_test.dart',
    plainName: 'surgical selector registry rejects broad or unsafe selectors',
    reason:
        'Run only the selector registry negative check after selector policy edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_selector_coverage_required',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_selector_coverage_test.dart',
    plainName:
        'surgical selector coverage requires selectors for every focused behavior',
    reason: 'Run only the selector coverage positive requirement check.',
    tags: {'parser-consumer', 'tooling', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_selector_coverage_rejects_missing',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_selector_coverage_test.dart',
    plainName: 'surgical selector coverage rejects missing behavior selectors',
    reason: 'Run only the selector coverage missing-behavior negative check.',
    tags: {'parser-consumer', 'tooling', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_selector_coverage_rejects_unlisted',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_selector_coverage_test.dart',
    plainName: 'surgical selector coverage rejects unlisted selector targets',
    reason: 'Run only the selector coverage unlisted-target negative check.',
    tags: {'parser-consumer', 'tooling', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_selector_rejects_broad_batch_scope',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_selector_coverage_test.dart',
    plainName: 'surgical selector registry rejects broad batch selector scopes',
    reason: 'Run only the selector registry batch-scope rejection check.',
    tags: {'parser-consumer', 'tooling', 'regression', 'surgical'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_selector_all_commands_individual',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_selector_coverage_test.dart',
    plainName:
        'surgical selector registry commands are all individually runnable',
    reason: 'Run only the command-level individual selector enforcement check.',
    tags: {'parser-consumer', 'tooling', 'regression', 'surgical'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_selector_coverage_ignores_fixture_strings',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_selector_coverage_test.dart',
    plainName:
        'surgical selector coverage ignores fixture strings that look like tests',
    reason: 'Run only the embedded fixture-string scanner regression check.',
    tags: {'parser-consumer', 'tooling', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_selector_coverage_all_declarations',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_selector_coverage_test.dart',
    plainName:
        'surgical selector coverage lists every test in registered files',
    reason: 'Run only the selector coverage declaration-audit check.',
    tags: {'parser-consumer', 'tooling', 'regression', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'individual_manifest_metadata',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_individual_test_manifest_test.dart',
    plainName: 'individual test manifest exposes surgical command metadata',
    reason:
        'Run only the individual manifest metadata check after manifest edits.',
    tags: {'parser-consumer', 'tooling', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'individual_manifest_mirrors_selectors',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_individual_test_manifest_test.dart',
    plainName:
        'individual test manifest mirrors surgical selector commands exactly',
    reason:
        'Run only the manifest/selector exact-match check after command metadata edits.',
    tags: {'parser-consumer', 'tooling', 'regression', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'individual_manifest_reporting_metadata',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_individual_test_manifest_test.dart',
    plainName:
        'individual test manifest entries keep stable reporting metadata',
    reason: 'Run only the individual test manifest reporting metadata guard.',
    tags: {'parser-consumer', 'tooling', 'regression', 'evidence'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'individual_manifest_rejects_unsafe',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_individual_test_manifest_test.dart',
    plainName:
        'individual test manifest rejects unsafe or non-surgical commands',
    reason: 'Run only the individual manifest negative safety check.',
    tags: {'parser-consumer', 'tooling', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_rerun_router_maps_changes',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_rerun_router_test.dart',
    plainName:
        'surgical rerun router maps changed files to individual commands',
    reason:
        'Run only the rerun-router positive mapping check after router rule edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'source-of-truth'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_rerun_router_rejects_bad',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_rerun_router_test.dart',
    plainName: 'surgical rerun router rejects unknown selector references',
    reason:
        'Run only the rerun-router negative reference check after router policy edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_rerun_router_payment_granularity',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_rerun_router_test.dart',
    plainName: 'surgical rerun router maps payment and granularity changes',
    reason:
        'Run only the payment/granularity rerun mapping check after router edits.',
    tags: {'payments', 'parser-consumer', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_rerun_router_test_file_mapping',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_rerun_router_test.dart',
    plainName:
        'surgical rerun router maps changed test files to their selectors',
    reason: 'Run only the changed-test-file routing regression check.',
    tags: {'parser-consumer', 'tooling', 'regression', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_rerun_router_dedupes_overlaps',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_rerun_router_test.dart',
    plainName: 'surgical rerun router dedupes overlapping changed paths',
    reason: 'Run only the rerun-router overlap dedupe check.',
    tags: {'parser-consumer', 'tooling', 'regression', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_rerun_router_outputs_single_behavior',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_rerun_router_test.dart',
    plainName: 'surgical rerun router outputs only single behavior commands',
    reason: 'Run only the rerun-router surgical command output guard.',
    tags: {'parser-consumer', 'tooling', 'regression', 'surgical'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_granularity_individual',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_granularity_contract_test.dart',
    plainName:
        'surgical granularity contract keeps tests individually runnable',
    reason:
        'Run only the surgical granularity positive guard after selector policy edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_granularity_rejects_batch',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_granularity_contract_test.dart',
    plainName: 'surgical granularity contract rejects broad batch selectors',
    reason:
        'Run only the surgical granularity negative guard after selector policy edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_granularity_real_declarations',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_granularity_contract_test.dart',
    plainName: 'surgical selectors point at real individual test declarations',
    reason:
        'Run only the real-test-declaration audit after selector or test renames.',
    tags: {'parser-consumer', 'release-gate', 'regression', 'tooling'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'payment_ledger_balance_policy',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_payment_contract_test.dart',
    plainName:
        'payment ledger policy proves invoice balance without source mutation',
    reason:
        'Run only the payment ledger balance policy after payment contract edits.',
    tags: {'payments', 'financial', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'payment_ledger_rejects_cross_account',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_payment_contract_test.dart',
    plainName: 'payment ledger policy rejects cross-account and overpay risks',
    reason:
        'Run only the payment ledger negative safety check after payment contract edits.',
    tags: {'payments', 'financial', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'payment_contract_balances_adjustments',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_payment_contract_test.dart',
    plainName: 'payment contract balances payments refunds and adjustments',
    reason: 'Run only the payment/refund/adjustment balance contract.',
    tags: {'payments', 'financial', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'payment_contract_positive_ledger_math',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_payment_contract_test.dart',
    plainName:
        'payment contract allows audited positive payment and refund ledger math',
    reason: 'Run only the positive audited payment ledger math check.',
    tags: {'payments', 'financial', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'payment_contract_rejects_sensitive_source_mutation',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_payment_contract_test.dart',
    plainName: 'payment contract rejects sensitive or source-mutating records',
    reason:
        'Run only the payment sensitive-data/source-mutation negative check.',
    tags: {'payments', 'financial', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'financial_ledger_expense_totals',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_financial_ledger_test.dart',
    plainName: 'financial ledger probe totals expenses deterministically',
    reason: 'Run only the expense-total ledger math check after ledger edits.',
    tags: {'financial', 'expenses', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'financial_ledger_inventory_consumption',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_financial_ledger_test.dart',
    plainName: 'financial ledger probe models inventory consumption cost',
    reason: 'Run only the inventory consumption cost check after ledger edits.',
    tags: {'financial', 'inventory', 'jobs', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'financial_ledger_rejects_unsafe_money',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_financial_ledger_test.dart',
    plainName: 'financial ledger probe rejects unsafe money lines',
    reason: 'Run only the unsafe money-line guard after ledger edits.',
    tags: {'financial', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'financial_formula_registry_labels',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_financial_formula_registry_test.dart',
    plainName: 'financial formula registry labels deterministic money formulas',
    reason:
        'Run only the deterministic formula registry check after formula edits.',
    tags: {'financial', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'financial_formula_registry_rejects_unsafe',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_financial_formula_registry_test.dart',
    plainName: 'financial formula registry rejects mutable or broad formulas',
    reason:
        'Run only the mutable/broad formula rejection check after formula edits.',
    tags: {'financial', 'source-of-truth', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'operating_directive_matches_docs',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_operating_directive_contract_test.dart',
    plainName: 'operating directive contract matches production docs',
    reason:
        'Run only the operating directive doc contract after directive edits.',
    tags: {'docs', 'quality-gate', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'operating_directive_rejects_missing_rules',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_operating_directive_contract_test.dart',
    plainName: 'operating directive contract rejects missing production rules',
    reason:
        'Run only the operating directive negative rule check after directive edits.',
    tags: {'docs', 'quality-gate', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'quality_gate_release_dimensions',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_quality_gates_test.dart',
    plainName: 'quality gate matrix covers release required QA dimensions',
    reason:
        'Run only the quality-gate release dimension check after gate edits.',
    tags: {'quality-gate', 'release-gate', 'regression', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'quality_gate_rejects_partial',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_quality_gates_test.dart',
    plainName: 'quality gate matrix rejects partial release dimensions',
    reason: 'Run only the quality-gate negative check after gate edits.',
    tags: {'quality-gate', 'release-gate', 'regression', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'release_gate_tool_commands',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_release_gate_tool_test.dart',
    plainName: 'release gate tool emits surgical command plan',
    reason: 'Run only the release gate command output check after tool edits.',
    tags: {'release-gate', 'tooling', 'command-plan'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'release_gate_tool_json',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_release_gate_tool_test.dart',
    plainName: 'release gate tool emits JSON evidence',
    reason: 'Run only the release gate JSON evidence check after tool edits.',
    tags: {'release-gate', 'tooling', 'evidence'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'individual_command_tool_by_id',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_individual_qa_command_tool_test.dart',
    plainName: 'individual QA command tool returns one exact command by id',
    reason: 'Run only the command-tool id lookup check.',
    tags: {'tooling', 'parser-consumer', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'individual_command_tool_by_risk',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_individual_qa_command_tool_test.dart',
    plainName: 'individual QA command tool lists focused commands by risk',
    reason: 'Run only the command-tool risk lookup check.',
    tags: {'tooling', 'parser-consumer', 'financial'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'individual_command_tool_changed_files',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_individual_qa_command_tool_test.dart',
    plainName:
        'individual QA command tool resolves changed files to focused commands',
    reason: 'Run only the command-tool changed-file lookup check.',
    tags: {'tooling', 'parser-consumer', 'regression', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'individual_command_tool_all_selector_files',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_individual_qa_command_tool_test.dart',
    plainName: 'individual QA command tool resolves every selector test file',
    reason: 'Run only the command-tool all-selector-file lookup check.',
    tags: {'tooling', 'parser-consumer', 'regression', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'individual_command_tool_changed_file_all_selectors',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_individual_qa_command_tool_test.dart',
    plainName:
        'individual QA command tool returns all selectors for a changed file',
    reason: 'Run only the command-tool changed-file completeness lookup check.',
    tags: {'tooling', 'parser-consumer', 'regression', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'individual_command_tool_all_selector_ids',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_individual_qa_command_tool_test.dart',
    plainName:
        'individual QA command tool resolves every selector id exactly once',
    reason: 'Run only the command-tool all-selector-id exact lookup check.',
    tags: {'tooling', 'parser-consumer', 'regression', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'individual_command_tool_changed_unique_surgical',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_individual_qa_command_tool_test.dart',
    plainName:
        'individual QA command tool changed output is unique and surgical',
    reason:
        'Run only the changed-file command dedupe and surgical-output guard.',
    tags: {'tooling', 'parser-consumer', 'regression', 'surgical'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'individual_command_tool_rejects_unknown',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_individual_qa_command_tool_test.dart',
    plainName: 'individual QA command tool rejects unknown selectors',
    reason: 'Run only the command-tool unknown-selector negative check.',
    tags: {'tooling', 'parser-consumer', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'release_evidence_required_proof',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_release_evidence_bundle_test.dart',
    plainName: 'release evidence bundle records required milestone proof',
    reason:
        'Run only the release evidence positive proof check after evidence edits.',
    tags: {'release-gate', 'tooling', 'evidence'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'release_evidence_rejects_bad_proof',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_release_evidence_bundle_test.dart',
    plainName: 'release evidence bundle rejects broad or missing proof',
    reason:
        'Run only the release evidence negative proof check after evidence edits.',
    tags: {'release-gate', 'tooling', 'regression', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'source_audit_line_caps',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_source_audit_policy_test.dart',
    plainName: 'source audit policy separates production and QA line caps',
    reason: 'Run only the source-audit line-cap policy after audit edits.',
    tags: {'source-audit', 'quality-gate', 'modularity', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'source_audit_debt_ledger',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_source_audit_policy_test.dart',
    plainName:
        'source audit debt ledger tracks current oversized production files',
    reason:
        'Run only the source-audit debt scan after line-count debt changes.',
    tags: {'source-audit', 'quality-gate', 'modularity', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'source_audit_rejects_unsafe_limits',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_source_audit_policy_test.dart',
    plainName: 'source audit policy rejects unsafe or incomplete limits',
    reason: 'Run only the source-audit unsafe-limit negative check.',
    tags: {'source-audit', 'quality-gate', 'modularity', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'audit_trail_ordered_complete',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_audit_trail_test.dart',
    plainName: 'audit trail probe validates ordered complete audit events',
    reason:
        'Run only the audit event ordering check after audit support edits.',
    tags: {'audit', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'audit_trail_user_confirmation',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_audit_trail_test.dart',
    plainName:
        'audit trail probe proves user confirmation outranks suggestions',
    reason:
        'Run only the user-confirmation audit check after parser/review audit edits.',
    tags: {'audit', 'review-safety', 'source-of-truth', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'audit_trail_rejects_bad_events',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_audit_trail_test.dart',
    plainName:
        'audit trail probe rejects duplicate incomplete or unordered events',
    reason:
        'Run only the audit negative contract after audit validation edits.',
    tags: {'audit', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_assertions_accept_safe_behavior',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_assertions_test.dart',
    plainName: 'shared QA assertions accept safe source truth behavior',
    reason:
        'Run only the positive shared assertion contract after assertion edits.',
    tags: {'assertions', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_assertions_reject_unsafe_behavior',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_assertions_test.dart',
    plainName: 'shared QA assertions reject source truth and privacy failures',
    reason:
        'Run only the negative shared assertion contract after assertion edits.',
    tags: {'assertions', 'security', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_artifact_policy_accepts_redacted',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_artifact_policy_test.dart',
    plainName:
        'QA artifact policy accepts redacted reports fixtures and regressions',
    reason: 'Run only the positive QA artifact policy check.',
    tags: {'artifact-policy', 'privacy', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_artifact_policy_rejects_private_raw',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_artifact_policy_test.dart',
    plainName:
        'QA artifact policy rejects private receipt and unredacted evidence',
    reason: 'Run only the private/raw artifact negative check.',
    tags: {'artifact-policy', 'privacy', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_artifact_policy_rejects_wrong_drives',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_artifact_policy_test.dart',
    plainName:
        'QA artifact policy rejects Google Drive OneDrive and F drive paths',
    reason: 'Run only the wrong-drive artifact path negative check.',
    tags: {'artifact-policy', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'mutation_guard_allows_derived_only',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_mutation_guard_test.dart',
    plainName: 'mutation guard allows derived output collections only',
    reason: 'Run only the derived-output positive mutation guard check.',
    tags: {'mutation-guard', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'mutation_guard_blocks_source_mutation',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_mutation_guard_test.dart',
    plainName:
        'mutation guard blocks recaps exports and notifications mutating sources',
    reason: 'Run only the derived-output source-mutation negative check.',
    tags: {'mutation-guard', 'source-of-truth', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'mutation_guard_scoped_source_ops',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_mutation_guard_test.dart',
    plainName: 'mutation guard allows only explicitly scoped source operations',
    reason: 'Run only the scoped source-operation mutation guard check.',
    tags: {'mutation-guard', 'source-of-truth', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'mutation_guard_matrix_side_effects',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_mutation_guard_test.dart',
    plainName: 'mutation guard matrix captures clean and failing side effects',
    reason: 'Run only the mutation guard matrix coverage check.',
    tags: {'mutation-guard', 'source-of-truth', 'regression', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'mutation_guard_matrix_rejects_mismatch',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_mutation_guard_test.dart',
    plainName: 'mutation guard matrix rejects mismatched expectations',
    reason: 'Run only the mutation guard matrix negative expectation check.',
    tags: {'mutation-guard', 'source-of-truth', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'local_first_accepts_hive_before_mirror',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_local_first_contract_test.dart',
    plainName: 'local-first contract accepts Hive before Firestore mirror',
    reason: 'Run only the local-first positive Hive-before-mirror check.',
    tags: {'local-first', 'source-of-truth', 'sync', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'local_first_rejects_mirror_first',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_local_first_contract_test.dart',
    plainName: 'local-first contract rejects mirror writes before local truth',
    reason: 'Run only the mirror-before-local negative check.',
    tags: {'local-first', 'source-of-truth', 'sync', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'local_first_rejects_unsafe_writes',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_local_first_contract_test.dart',
    plainName: 'local-first contract rejects unsafe derived and mirror writes',
    reason: 'Run only the unsafe derived/mirror local-first negative check.',
    tags: {'local-first', 'source-of-truth', 'sync', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'source_truth_gate_protects_roles',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_source_truth_gate_test.dart',
    plainName: 'source truth gate protects local truth and derived outputs',
    reason: 'Run only the source-truth positive role coverage check.',
    tags: {'source-of-truth', 'sync', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'source_truth_gate_rejects_mutations',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_source_truth_gate_test.dart',
    plainName:
        'source truth gate rejects mirror suggestion and derived mutations',
    reason: 'Run only the source-truth mutation negative check.',
    tags: {'source-of-truth', 'sync', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'sync_lifecycle_local_dirty_before_mirror',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_sync_lifecycle_test.dart',
    plainName: 'sync lifecycle writes local dirty record before mirror success',
    reason: 'Run only the sync lifecycle local-dirty-before-mirror check.',
    tags: {'sync', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'sync_lifecycle_failed_retry_queue',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_sync_lifecycle_test.dart',
    plainName: 'sync lifecycle keeps failed records queued for retry',
    reason: 'Run only the sync lifecycle failed-retry queue check.',
    tags: {'sync', 'source-of-truth', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'sync_lifecycle_rejects_unknown_transition',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_sync_lifecycle_test.dart',
    plainName: 'sync lifecycle rejects unknown record transitions',
    reason: 'Run only the sync lifecycle unknown-transition negative check.',
    tags: {'sync', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'sync_transport_covers_paths',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_sync_transport_policy_test.dart',
    plainName:
        'sync transport policy covers manual scheduled and automatic paths',
    reason: 'Run only the sync transport positive policy coverage check.',
    tags: {'sync', 'cost-quota', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'sync_transport_rejects_unsafe_networks',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_sync_transport_policy_test.dart',
    plainName: 'sync transport policy rejects unsafe network expectations',
    reason: 'Run only the sync transport unsafe-network negative check.',
    tags: {'sync', 'cost-quota', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'sync_conflict_allows_safe_merge',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_sync_conflict_contract_test.dart',
    plainName: 'sync conflict contract allows different-field safe merge',
    reason: 'Run only the safe different-field merge conflict check.',
    tags: {'sync', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'sync_conflict_protects_confirmed_financial',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_sync_conflict_contract_test.dart',
    plainName: 'sync conflict contract protects confirmed financial local data',
    reason: 'Run only the confirmed financial local-wins conflict check.',
    tags: {'sync', 'financial', 'source-of-truth', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'sync_conflict_requires_review_audit',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_sync_conflict_contract_test.dart',
    plainName:
        'sync conflict contract requires review audit for ambiguous conflicts',
    reason: 'Run only the ambiguous conflict review/audit check.',
    tags: {'sync', 'audit', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'sync_conflict_rejects_unsafe_remote',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_sync_conflict_contract_test.dart',
    plainName:
        'sync conflict contract rejects unsafe remote wins and source mutation',
    reason: 'Run only the unsafe remote-wins/source-mutation conflict guard.',
    tags: {'sync', 'security', 'source-of-truth', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_environment_local_truth',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_environment_test.dart',
    plainName: 'QA environment fakes preserve local truth and mirror copies',
    reason:
        'Run only the fake local/mirror store check after environment edits.',
    tags: {'environment', 'source-of-truth', 'sync', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_environment_side_effect_fakes',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_environment_test.dart',
    plainName:
        'QA environment exposes permissions device and side-effect fakes',
    reason:
        'Run only the fake permissions/device/side-effect check after environment edits.',
    tags: {'environment', 'security', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_builders_record_families',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_environment_test.dart',
    plainName: 'QA builders create every shared record family',
    reason: 'Run only the shared builder family check after builder edits.',
    tags: {'builders', 'environment', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_fixtures_accept_reviewed',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_fixtures_test.dart',
    plainName: 'fixture catalog accepts reviewed behavior fixtures',
    reason: 'Run only the positive fixture catalog check after fixture edits.',
    tags: {'fixtures', 'regression', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_fixtures_reject_weak',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_fixtures_test.dart',
    plainName: 'fixture catalog rejects duplicate or unreviewed weak evidence',
    reason: 'Run only the negative fixture catalog check after fixture edits.',
    tags: {'fixtures', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scenario_runner_sync',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_scenario_runners_test.dart',
    plainName: 'sync scenario runner proves local-first mirror behavior',
    reason: 'Run only the sync scenario runner after scenario edits.',
    tags: {'scenario-runner', 'sync', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scenario_runner_security',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_scenario_runners_test.dart',
    plainName: 'security scenario runner proves privacy and scope behavior',
    reason: 'Run only the security scenario runner after scenario edits.',
    tags: {'scenario-runner', 'security', 'privacy', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scenario_runner_financial',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_scenario_runners_test.dart',
    plainName: 'financial scenario runner proves deterministic money behavior',
    reason: 'Run only the financial scenario runner after scenario edits.',
    tags: {'scenario-runner', 'financial', 'regression', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scenario_runner_performance',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_scenario_runners_test.dart',
    plainName: 'performance scenario runner proves large-data budgets',
    reason: 'Run only the performance scenario runner after scenario edits.',
    tags: {'scenario-runner', 'performance', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scenario_runner_accessibility_localization',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_scenario_runners_test.dart',
    plainName:
        'accessibility localization runner proves release UI language gates',
    reason:
        'Run only the accessibility/localization scenario runner after gate edits.',
    tags: {'scenario-runner', 'accessibility', 'localization', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scenario_runner_cost_quota',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_scenario_runners_test.dart',
    plainName: 'cost quota runner proves cloud usage stays budgeted and opt-in',
    reason: 'Run only the cost/quota scenario runner after cloud policy edits.',
    tags: {'scenario-runner', 'cost-quota', 'security', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'main_backbone_parser_visibility',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_backbone_test.dart',
    plainName: 'main Maintainiac QA backbone covers whole app modules',
    reason:
        'Run only the main backbone visibility check when shared QA wiring changes.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'main_backbone_builders_visibility',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_backbone_test.dart',
    plainName:
        'shared builders cover app records without module-specific fakes',
    reason: 'Run only the shared-builder backbone visibility check.',
    tags: {'builders', 'environment', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'main_backbone_assertions_visibility',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_backbone_test.dart',
    plainName: 'shared assertions enforce source-of-truth and privacy rules',
    reason: 'Run only the shared-assertions backbone visibility check.',
    tags: {'assertions', 'source-of-truth', 'privacy', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'main_backbone_fixture_regression_visibility',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_backbone_test.dart',
    plainName:
        'fixture catalog and regression registry reject weak QA evidence',
    reason: 'Run only the fixture/regression backbone visibility check.',
    tags: {'fixtures', 'regression', 'security', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'main_backbone_quality_gate_visibility',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_backbone_test.dart',
    plainName:
        'quality gate matrix covers release-one sync security money and load',
    reason: 'Run only the quality-gate backbone visibility check.',
    tags: {'quality-gate', 'sync', 'security', 'performance'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'main_backbone_scenario_runner_visibility',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_backbone_test.dart',
    plainName: 'scenario runners execute release-one QA behavior contracts',
    reason: 'Run only the scenario-runner backbone visibility check.',
    tags: {'scenario-runner', 'financial', 'performance', 'release-gate'},
  ),
]);
