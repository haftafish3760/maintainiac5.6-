part of 'maintainiac_firestore_documents.dart';

Map<String, Object?> _sanitizeCommandCenterOcrContract(
  Map<String, Object?> contract,
) {
  final findings = ExpenseExportSnapshot.commandCenterOcrContractFindingsFor(
    contract,
  );
  if (findings.isNotEmpty) {
    throw ArgumentError.value(
      findings,
      'commandCenterOcrContract',
      'Unsafe expense OCR Command Center contract.',
    );
  }
  return Map.unmodifiable({
    for (final key in ExpenseExportSnapshot.commandCenterOcrAllowedKeys)
      key: _sanitizeCommandCenterOcrValue(key, contract[key]),
  });
}

Object? _sanitizeCommandCenterOcrValue(String key, Object? value) {
  if (value == null || value is bool || value is int) return value;
  if (value is double) {
    return double.parse(value.toStringAsFixed(4));
  }
  if (value is String) {
    if (key == 'rangeStart' || key == 'rangeEnd') {
      return _safeIso(value);
    }
    if (key == 'ocrReadStatus' ||
        key == 'ocrReadSummary' ||
        key == 'ocrTopCheck' ||
        key == 'ocrTopPrimaryIssue' ||
        key == 'ocrTopPrimaryAction') {
      return _ExpenseTelemetryFirestoreRedactor.readableText(value);
    }
    return value;
  }
  if (value is Map) {
    return Map.unmodifiable({
      for (final entry in value.entries) '${entry.key}': entry.value,
    });
  }
  throw ArgumentError.value(
    value,
    key,
    'Unsupported expense OCR Command Center contract value.',
  );
}

List<String> _expenseTelemetrySummaryOcrContractFindingsFor(
  MaintainiacFirestoreDocumentDraft draft,
) {
  final findings = <String>[];
  final path = draft.path;
  final data = draft.data;
  if (!RegExp(r'^orgs/[^/]+/expenseTelemetrySummaries/[^/]+$').hasMatch(path)) {
    findings.add('invalid_path:$path');
  }
  if (data['uploadShape'] != 'single_summary_document') {
    findings.add('invalid_upload_shape:${data['uploadShape']}');
  }
  if (data['rawEventUploadCount'] != 0) {
    findings.add('raw_event_upload_count:${data['rawEventUploadCount']}');
  }
  for (final forbidden in _expenseTelemetrySummaryForbiddenOcrKeys) {
    if (data.containsKey(forbidden)) {
      findings.add('forbidden_top_level_key:$forbidden');
    }
  }
  final contract = data['commandCenterOcrContract'];
  if (contract == null) {
    return List.unmodifiable(findings);
  }
  if (contract is! Map) {
    findings.add('invalid_ocr_contract_shape');
    return List.unmodifiable(findings);
  }
  final typedContract = Map<String, Object?>.from(contract);
  findings.addAll(
    ExpenseExportSnapshot.commandCenterOcrContractFindingsFor(
      typedContract,
    ).map((finding) => 'ocr_contract:$finding'),
  );
  if (typedContract.containsKey('uploadShape')) {
    findings.add('ocr_contract_forbidden_upload_shape');
  }
  if (typedContract.containsKey('rawEventUploadCount')) {
    findings.add('ocr_contract_forbidden_raw_event_upload_count');
  }
  return List.unmodifiable(findings);
}

const _expenseTelemetrySummaryForbiddenOcrKeys = <String>{
  'merchantName',
  'merchantNames',
  'receiptImage',
  'receiptImagePath',
  'receiptImages',
  'receiptText',
  'rawOcrText',
  'importedReceiptText',
  'itemDescription',
  'itemDescriptions',
  'lineDescriptions',
  'proofPath',
  'proofPaths',
  'localFilePath',
  'localProofPath',
};
