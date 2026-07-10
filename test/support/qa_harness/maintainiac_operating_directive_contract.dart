class MaintainiacOperatingDirectiveClause {
  const MaintainiacOperatingDirectiveClause({
    required this.id,
    required this.requiredText,
    required this.riskFamily,
  });

  final String id;
  final String requiredText;
  final String riskFamily;

  List<String> validateAgainst(String documentText) {
    final failures = <String>[];
    if (id.trim().isEmpty) {
      failures.add('operating directive clause missing id');
    }
    if (requiredText.trim().isEmpty) failures.add('$id missing required text');
    if (riskFamily.trim().isEmpty) failures.add('$id missing risk family');
    if (!documentText.toLowerCase().contains(requiredText.toLowerCase())) {
      failures.add('$id missing directive text "$requiredText"');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {'id': id, 'requiredText': requiredText, 'riskFamily': riskFamily};
  }
}

class MaintainiacOperatingDirectiveContract {
  const MaintainiacOperatingDirectiveContract(this.clauses);

  final List<MaintainiacOperatingDirectiveClause> clauses;

  List<String> validateDocument(String documentText) {
    final failures = <String>[];
    final ids = <String>{};
    if (clauses.isEmpty) failures.add('operating directive has no clauses');
    for (final clause in clauses) {
      if (!ids.add(clause.id)) {
        failures.add('duplicate operating directive clause ${clause.id}');
      }
      failures.addAll(clause.validateAgainst(documentText));
    }
    for (final requiredRisk in {
      'quality-gate',
      'regression',
      'source-of-truth',
      'privacy',
      'review-safety',
      'modularity',
    }) {
      if (!clauses.any((clause) => clause.riskFamily == requiredRisk)) {
        failures.add('operating directive missing $requiredRisk clause');
      }
    }
    return failures;
  }

  List<String> validateClauseRegistry() {
    return validateDocument(
      clauses.map((clause) => clause.requiredText).join('\n'),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'clauseCount': clauses.length,
      'riskFamilies': ({
        for (final clause in clauses) clause.riskFamily,
      }.toList()..sort()),
      'clauses': [for (final clause in clauses) clause.toJson()],
    };
  }
}

const maintainiacOperatingDirectiveContract =
    MaintainiacOperatingDirectiveContract([
      MaintainiacOperatingDirectiveClause(
        id: 'no_build_on_failing_gate',
        requiredText: 'Do not build on a failing analyzer',
        riskFamily: 'quality-gate',
      ),
      MaintainiacOperatingDirectiveClause(
        id: 'bug_fix_requires_regression',
        requiredText: 'Every confirmed bug fix must include a regression test',
        riskFamily: 'regression',
      ),
      MaintainiacOperatingDirectiveClause(
        id: 'hive_local_source_of_truth',
        requiredText: 'Hive/local storage is the immediate source of truth',
        riskFamily: 'source-of-truth',
      ),
      MaintainiacOperatingDirectiveClause(
        id: 'firestore_mirror_only',
        requiredText: 'Firestore/cloud sync is a mirror',
        riskFamily: 'source-of-truth',
      ),
      MaintainiacOperatingDirectiveClause(
        id: 'suggestions_need_confirmation',
        requiredText: 'OCR/parser output is suggestion data',
        riskFamily: 'review-safety',
      ),
      MaintainiacOperatingDirectiveClause(
        id: 'camera_ocr_lane_boundary',
        requiredText: 'camera/OCR',
        riskFamily: 'module-boundary',
      ),
      MaintainiacOperatingDirectiveClause(
        id: 'confirmed_financial_not_overwritten',
        requiredText: 'Never overwrite user-confirmed financial data silently',
        riskFamily: 'review-safety',
      ),
      MaintainiacOperatingDirectiveClause(
        id: 'forbidden_private_data',
        requiredText: 'Never store VINs, license plates, passenger data',
        riskFamily: 'privacy',
      ),
      MaintainiacOperatingDirectiveClause(
        id: 'modular_file_rule',
        requiredText: 'Keep files modular',
        riskFamily: 'modularity',
      ),
    ]);
