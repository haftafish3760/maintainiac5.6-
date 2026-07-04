import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserRecipeCompletenessSuite extends QaSuite {
  const WorkSupplyParserRecipeCompletenessSuite()
    : super('inventory.recipe_completeness_contract');

  static const _requiredRecipeLists = {
    'englishPlumbingCoreRecipes',
    'spanishPlumbingCoreRecipes',
    'englishPlumbingStandardRecipes',
    'spanishPlumbingStandardRecipes',
    'englishElectricalCoreRecipes',
    'spanishElectricalCoreRecipes',
    'englishElectricalStandardRecipes',
    'spanishElectricalStandardRecipes',
    'englishHvacCoreRecipes',
    'spanishHvacCoreRecipes',
    'englishHvacStandardRecipes',
    'spanishHvacStandardRecipes',
  };

  static const _requiredRecipeSignals = {
    'clear_match',
    'ambiguous_review',
    'merchant_abbreviation',
    'dangerous_word',
    'spanish',
    'generated_batch',
    'photo_ocr_text_after_extraction',
    'uploaded_pdf_text_after_extraction',
    'emailed_receipt_text_after_extraction',
    'manual_pasted_receipt_text',
    'invoice_style_material_line_text',
    'quote_style_material_line_text',
    'packing_slip_material_list_text',
    'counter_sale_material_receipt_text',
    'generic_unknown_merchant_receipt_text',
    'local_regional_supplier_receipt_text',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _recipeSource();

    for (final listName in _requiredRecipeLists) {
      if (source.contains('const $listName = [')) continue;
      failures.add(
        _failure(
          id: 'missing_recipe_list:$listName',
          message: 'Release-one fixture recipe list is missing.',
          expected: listName,
          actual: 'not found',
        ),
      );
    }
    for (final signal in _requiredRecipeSignals) {
      if (source.contains(signal)) continue;
      failures.add(
        _failure(
          id: 'missing_recipe_signal:$signal',
          message: 'Fixture recipes are missing a required parser-risk signal.',
          expected: signal,
          actual: 'not found',
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _requiredRecipeLists.length + _requiredRecipeSignals.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'requiredRecipeLists': _requiredRecipeLists.toList()..sort(),
        'requiredRecipeSignals': _requiredRecipeSignals.toList()..sort(),
        'contract':
            'Residential Plumbing/Electrical/HVAC Core+Standard fixture recipes must exist in English and Spanish before batch generation.',
      },
    );
  }

  String _recipeSource() {
    final buffer = StringBuffer();
    for (final file in Directory('tool').listSync()) {
      if (file is File &&
          (file.path.contains('work_supply_parser_qa_fixture_recipes') ||
              file.path.contains('work_supply_parser_qa_generate_fixtures')) &&
          file.path.endsWith('.dart')) {
        buffer.writeln(file.readAsStringSync());
      }
    }
    return buffer.toString();
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.error,
      expected: expected,
      actual: actual,
      suggestedFix:
          'Add the missing release-one fixture recipe coverage before scaling generated parser batches.',
      metadata: const {'triageCategory': QaFailureTriage.fixture},
    );
  }
}
