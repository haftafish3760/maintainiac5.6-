part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrParserHandoffProofMaps on ReceiptOcrParserHandoff {
  Map<String, String> get customerProofDefaultVisibilityByLineId {
    final mapped = <String, String>{};
    for (final draft in lineDrafts) {
      mapped.putIfAbsent(
        draft.stableLineId,
        () => draft.customerProofDefaultVisibility,
      );
    }
    return Map<String, String>.unmodifiable(mapped);
  }

  List<String> get customerProofReviewLineIds {
    return _uniqueLineDraftIds(
      lineDrafts.where(
        (draft) =>
            draft.customerProofDefaultVisibility == 'review_for_customer_proof',
      ),
    );
  }

  List<String> get customerProofRedactByDefaultLineIds {
    return _uniqueLineDraftIds(
      lineDrafts.where(
        (draft) => draft.customerProofDefaultVisibility == 'redact_by_default',
      ),
    );
  }

  List<String> get customerProofNeedsManualDecisionLineIds {
    return _uniqueLineDraftIds(
      lineDrafts.where(
        (draft) =>
            draft.customerProofDefaultVisibility ==
            'review_before_customer_share',
      ),
    );
  }

  Map<String, int> get customerProofVisibilityCounts {
    final counts = <String, int>{};
    for (final draft in lineDraftsById.values) {
      final visibility = draft.customerProofDefaultVisibility;
      counts[visibility] = (counts[visibility] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  String get clientProofRedactionStatus {
    if (lines.isEmpty) return 'no_receipt_lines';
    if (customerProofNeedsManualDecisionLineIds.isNotEmpty) {
      return 'needs_client_redaction_review';
    }
    if (customerProofRedactByDefaultLineIds.isNotEmpty) {
      return 'redaction_defaults_present';
    }
    return 'ready_for_client_proof';
  }

  Map<String, int> get clientProofVisibilityCounts {
    const keyMap = {
      'review_for_customer_proof': 'review_for_client_proof',
      'redact_by_default': 'redact_by_default',
      'review_before_customer_share': 'review_before_client_share',
    };
    final counts = <String, int>{};
    for (final entry in customerProofVisibilityCounts.entries) {
      final key = keyMap[entry.key] ?? entry.key;
      counts[key] = (counts[key] ?? 0) + entry.value;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, Object?> get privacySafeClientProofTelemetryContract {
    return Map.unmodifiable({
      'schema': 'receipt_client_proof_redaction_summary_v1',
      'privacyScope': 'summary_only_no_receipt_content',
      'clientProofRedactionStatus': clientProofRedactionStatus,
      'clientProofVisibilityCounts': clientProofVisibilityCounts,
      'lineCount': lines.length,
      'sourceSectionCount': lineCountsBySourceSection.length,
      'redactByDefaultLineCount': customerProofRedactByDefaultLineIds.length,
      'reviewLineCount': customerProofReviewLineIds.length,
      'manualDecisionLineCount': customerProofNeedsManualDecisionLineIds.length,
    });
  }

  Map<String, Object?> get privacySafeCustomerProofContract {
    return Map.unmodifiable({
      'schema': 'receipt_customer_proof_redaction_v1',
      'privacyScope': 'summary_only_no_receipt_content',
      'lineCount': lines.length,
      'orderedLineIds': stableLineIds,
      'lineNumberByLineId': lineNumberByLineId,
      'proofLineReferenceLabelByLineId': proofLineReferenceLabelByLineId,
      'customerProofDefaultVisibilityByLineId':
          customerProofDefaultVisibilityByLineId,
      'customerProofReviewLineIds': customerProofReviewLineIds,
      'customerProofRedactByDefaultLineIds':
          customerProofRedactByDefaultLineIds,
      'customerProofNeedsManualDecisionLineIds':
          customerProofNeedsManualDecisionLineIds,
      'customerProofVisibilityCounts': customerProofVisibilityCounts,
      'clientProofTelemetryContract': privacySafeClientProofTelemetryContract,
      'lineCountsBySourceSection': lineCountsBySourceSection,
      'itemLineCountsBySourceSection': itemLineCountsBySourceSection,
      'primaryFieldLineIds': primaryFieldLineIds,
    });
  }
}

List<String> _uniqueLineDraftIds(Iterable<ReceiptOcrParserLineDraft> drafts) {
  final seen = <String>{};
  return List<String>.unmodifiable([
    for (final draft in drafts)
      if (seen.add(draft.stableLineId)) draft.stableLineId,
  ]);
}
