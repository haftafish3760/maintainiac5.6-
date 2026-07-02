part of 'expense_screen_telemetry.dart';

final RegExp _knownReceiptMerchantPattern = RegExp(
  r"\b(?:lowe\s*s|lowe'?s|walmart|target|home depot|costco|"
  r"sam\s*s club|sam'?s club|shell|exxon|mobil|chevron|marathon|sheetz|"
  r"wawa|speedway|circle k|bp|sunoco|pilot|flying j|love\s*s|love'?s|"
  r"casey\s*s|casey'?s|kwik trip|kum\s*(?:and|&)?\s*go|quicktrip|qt|"
  r"racetrac|raceway|royal farms|murphy usa|valero|phillips 66|citgo|"
  r"sinclair|mapco|getgo|thorntons|travelcenters of america|petro|"
  r"jiffy lube|valvoline|take 5|midas|pep boys|firestone|discount tire|"
  r"les schwab|goodyear|ntb|autozone|advance auto|oreilly|o'?reilly|"
  r"napa|carquest|tractor supply|harbor freight|menards|ace hardware|"
  r"true value|rural king|fleet farm|blain\s*s farm fleet|"
  r"blain'?s farm fleet)\b",
  caseSensitive: false,
);

final RegExp _knownReceiptLocationPattern = RegExp(
  r'\b(?:austin|atlanta|baltimore|charlotte|chicago|columbus|dallas|'
  r'denver|detroit|houston|indianapolis|jacksonville|knoxville|'
  r'las vegas|los angeles|louisville|memphis|miami|nashville|new york|'
  r'orlando|philadelphia|phoenix|raleigh|richmond|san antonio|'
  r'san diego|san francisco|seattle|tampa|washington)\b',
  caseSensitive: false,
);

final RegExp _privateReceiptIdentifierPattern = RegExp(
  r'\b(?:auth(?:code)?|approval|barcode|card|customer|client|employee|driver|email|invoice|member|name|note|notes|order|phone|sale|store|terminal|transaction|trans|user)\s+[a-z0-9]+\b',
  caseSensitive: false,
);

final RegExp _privateReceiptNotePattern = RegExp(
  r'\b(?:user|customer|client|employee|driver)?\s*(?:note|notes|name)\s+(?:[a-z0-9]+\s+){0,3}[a-z0-9]+\b',
  caseSensitive: false,
);

String _fallbackWorkflowStepFor(String event) {
  return switch (event) {
    'validationError' => ExpenseWorkflowStep.lineReview.name,
    'saveFailure' => ExpenseWorkflowStep.saveExpense.name,
    'imageAttachFailure' => ExpenseWorkflowStep.receiptAttachment.name,
    'ocrFailed' => ExpenseWorkflowStep.receiptOcr.name,
    'parserFailed' => ExpenseWorkflowStep.receiptParser.name,
    'parserNeedsReview' => ExpenseWorkflowStep.receiptParser.name,
    'cloudBackupFailure' => ExpenseWorkflowStep.cloudBackup.name,
    'syncFailed' => ExpenseWorkflowStep.sync.name,
    'exportBlocked' => ExpenseWorkflowStep.export.name,
    'exportFailed' => ExpenseWorkflowStep.export.name,
    'addExpenseAbandoned' => ExpenseWorkflowStep.lineReview.name,
    _ => ExpenseWorkflowStep.screenLoad.name,
  };
}

String _fallbackFailedAtFor(String event) {
  return switch (event) {
    'validationError' => 'before_save_validation',
    'saveFailure' => 'expense_save',
    'imageAttachFailure' => 'receipt_attachment_save',
    'ocrFailed' => 'receipt_ocr',
    'parserFailed' => 'receipt_parser',
    'parserNeedsReview' => 'receipt_parser_review',
    'cloudBackupFailure' => 'cloud_backup',
    'syncFailed' => 'hosted_sync',
    'exportBlocked' => 'before_export_file_write',
    'exportFailed' => 'expense_export',
    'addExpenseAbandoned' => 'before_expense_save',
    _ => 'unknown_step',
  };
}

String _stringValue(Object? value) => value is String ? value : '';

bool _boolValue(Object? value) => value is bool && value;

int _intValue(Object? value) => value is int ? value : 0;

Map<String, Object?> _metadataValue(Object? value) {
  if (value is Map) return Map<String, Object?>.from(value);
  return const {};
}
