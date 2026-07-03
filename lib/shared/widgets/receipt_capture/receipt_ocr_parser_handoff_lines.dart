part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrParserHandoffLineMaps on ReceiptOcrParserHandoff {
  List<String> get stableLineIds =>
      List.unmodifiable(lines.map((line) => line.stableLineId));
  List<String> get parserReadyItemLineIds => List.unmodifiable(
    _uniqueStableLineIds(itemLines.where((line) => !line.needsReview)),
  );
  List<String> get reviewItemLineIds => List.unmodifiable(
    _uniqueStableLineIds(itemLines.where((line) => line.needsReview)),
  );
  List<String> get separatorlessMoneyInferenceLineIds => List.unmodifiable(
    _uniqueStableLineIds(
      lines.where((line) => line.hasSeparatorlessMoneyInference),
    ),
  );
  List<String> get splitCentsMoneyInferenceLineIds => List.unmodifiable(
    _uniqueStableLineIds(
      lines.where((line) => line.hasSplitCentsMoneyInference),
    ),
  );
  List<String> get addressContactMetadataLineIds => List.unmodifiable(
    _uniqueStableLineIds(
      metadataLines.where(
        (line) => line.hasTrait('address_or_contact_metadata'),
      ),
    ),
  );
  List<String> get weakHeaderCandidateLineIds => List.unmodifiable(
    _uniqueStableLineIds(
      lines.where((line) => line.hasTrait('weak_header_candidate')),
    ),
  );
  List<String> get knownMerchantHeaderCandidateLineIds => List.unmodifiable(
    _uniqueStableLineIds(
      lines.where((line) => line.hasTrait('known_merchant_header_candidate')),
    ),
  );
  List<String> get unknownMerchantHeaderCandidateLineIds => List.unmodifiable(
    _uniqueStableLineIds(
      lines.where((line) => line.hasTrait('unknown_merchant_header_candidate')),
    ),
  );
  List<String> get timeCandidateLineIds => List.unmodifiable(
    _uniqueStableLineIds(lines.where((line) => line.hasTrait('time_present'))),
  );
  List<String> get inventoryPrepLineIds => List.unmodifiable(
    _uniqueStableLineIds(
      itemLines.where((line) => line.isInventoryPrepCandidate),
    ),
  );
  List<String> get materialCandidateLineIds => List.unmodifiable(
    _uniqueStableLineIds(itemLines.where((line) => line.isMaterialCandidate)),
  );
  List<String> get fuelCandidateLineIds => List.unmodifiable(
    _uniqueStableLineIds(itemLines.where((line) => line.isFuelCandidate)),
  );
  List<String> get fuelReadyLineIds => List.unmodifiable(
    _uniqueStableLineIds(
      itemLines.where((line) => line.isFuelCandidate && !line.needsReview),
    ),
  );
  bool get hasFuelContext => lines.any(
    (line) => line.isFuelCandidate || _looksLikeFuelExpenseLine(line.text),
  );
  List<String> get fuelQuantitySignalLineIds => List.unmodifiable(
    _uniqueStableLineIds(
      lines.where(
        (line) =>
            (line.isFuelCandidate && line.hasFuelQuantitySignal) ||
            (hasFuelContext && _looksLikeFuelReceiptQuantitySignal(line.text)),
      ),
    ),
  );
  List<String> get fuelUnitPriceSignalLineIds => List.unmodifiable(
    _uniqueStableLineIds(
      lines.where(
        (line) =>
            (line.isFuelCandidate && line.hasFuelUnitPriceSignal) ||
            (hasFuelContext && _looksLikeFuelReceiptUnitPriceSignal(line.text)),
      ),
    ),
  );
  List<String> get fuelDetailReadyLineIds {
    if (fuelReadyLineIds.isEmpty ||
        fuelQuantitySignalLineIds.isEmpty ||
        fuelUnitPriceSignalLineIds.isEmpty) {
      return const [];
    }
    return List<String>.unmodifiable({
      ...fuelReadyLineIds,
      ...fuelQuantitySignalLineIds,
      ...fuelUnitPriceSignalLineIds,
    });
  }

  List<String> get vehicleSupplyCandidateLineIds => List.unmodifiable(
    _uniqueStableLineIds(
      itemLines.where((line) => line.isVehicleSupplyCandidate),
    ),
  );
  Map<String, String> get primaryFieldLineIds {
    final result = <String, String>{};
    final primaryVendor = primaryVendorLine;
    final primaryDate = primaryDateLine;
    final primarySubtotal = primarySubtotalLine;
    final primaryTax = primaryTaxLine;
    final primaryTotal = primaryTotalLine;
    if (primaryVendor != null) result['vendor'] = primaryVendor.stableLineId;
    if (primaryDate != null) result['date'] = primaryDate.stableLineId;
    if (primarySubtotal != null) {
      result['subtotal'] = primarySubtotal.stableLineId;
    }
    if (primaryTax != null) result['tax'] = primaryTax.stableLineId;
    if (primaryTotal != null) result['total'] = primaryTotal.stableLineId;
    return Map.unmodifiable(result);
  }

  Map<String, List<String>> get lineIdsByRole {
    final ids = <String, List<String>>{};
    for (final line in lines) {
      ids.putIfAbsent(line.roleLabel, () => <String>[]).add(line.stableLineId);
      if (line.isLikelySummary) {
        ids.putIfAbsent('summary', () => <String>[]).add(line.stableLineId);
      } else if (line.isLikelyMetadata) {
        ids.putIfAbsent('metadata', () => <String>[]).add(line.stableLineId);
      }
    }
    final result = <String, List<String>>{
      for (final entry in ids.entries)
        entry.key: List<String>.unmodifiable(entry.value),
    };
    return Map<String, List<String>>.unmodifiable(result);
  }

  Map<String, String> get roleByLineId {
    final mapped = <String, String>{};
    for (final line in lines) {
      mapped.putIfAbsent(line.stableLineId, () => line.roleLabel);
    }
    return Map<String, String>.unmodifiable(mapped);
  }

  Map<String, String> get parserBucketByLineId {
    final mapped = <String, String>{};
    for (final line in lines) {
      mapped.putIfAbsent(line.stableLineId, () => line.parserBucketId);
    }
    return Map<String, String>.unmodifiable(mapped);
  }

  Map<String, String> get expenseFamilyByLineId {
    final mapped = <String, String>{};
    for (final line in lines) {
      mapped.putIfAbsent(
        line.stableLineId,
        () => _receiptExpenseFamilyToken(line.expenseFamily),
      );
    }
    return Map<String, String>.unmodifiable(mapped);
  }

  Map<String, String> get parserHintByLineId {
    final mapped = <String, String>{};
    for (final line in lines) {
      mapped.putIfAbsent(line.stableLineId, () => line.parserHint);
    }
    return Map<String, String>.unmodifiable(mapped);
  }

  List<ReceiptOcrParserLineDraft> get lineDrafts {
    return List<ReceiptOcrParserLineDraft>.unmodifiable(
      lines.map(ReceiptOcrParserLineDraft.fromSignal),
    );
  }

  List<ReceiptOcrParserLineDraft> get itemLineDrafts {
    return List<ReceiptOcrParserLineDraft>.unmodifiable(
      itemLines.map(ReceiptOcrParserLineDraft.fromSignal),
    );
  }

  List<ReceiptOcrParserLineDraft> get parserReadyItemLineDrafts {
    return List<ReceiptOcrParserLineDraft>.unmodifiable(
      itemLines
          .where((line) => !line.needsReview)
          .map(ReceiptOcrParserLineDraft.fromSignal),
    );
  }

  List<ReceiptOcrParserLineDraft> get reviewItemLineDrafts {
    return List<ReceiptOcrParserLineDraft>.unmodifiable(
      itemLines
          .where((line) => line.needsReview)
          .map(ReceiptOcrParserLineDraft.fromSignal),
    );
  }

  Map<String, int> get lineNumberByLineId {
    final mapped = <String, int>{};
    for (final draft in lineDrafts) {
      mapped.putIfAbsent(draft.stableLineId, () => draft.lineNumber);
    }
    return Map<String, int>.unmodifiable(mapped);
  }

  Map<String, String> get proofLineReferenceLabelByLineId {
    final mapped = <String, String>{};
    for (final draft in lineDrafts) {
      mapped.putIfAbsent(
        draft.stableLineId,
        () => draft.proofLineReferenceLabel,
      );
    }
    return Map<String, String>.unmodifiable(mapped);
  }

  Map<String, ReceiptOcrParserLineDraft> get lineDraftsById {
    final mapped = <String, ReceiptOcrParserLineDraft>{};
    for (final draft in lineDrafts) {
      mapped.putIfAbsent(draft.stableLineId, () => draft);
    }
    return Map<String, ReceiptOcrParserLineDraft>.unmodifiable(mapped);
  }

  Map<String, double> get itemAmountsByLineId {
    final mapped = <String, double>{};
    for (final draft in itemLineDrafts) {
      final amount = draft.amount;
      if (amount != null) {
        mapped.putIfAbsent(draft.stableLineId, () => amount);
      }
    }
    return Map<String, double>.unmodifiable(mapped);
  }

  Map<String, String> get itemTextByLineId {
    final mapped = <String, String>{};
    for (final draft in itemLineDrafts) {
      mapped.putIfAbsent(draft.stableLineId, () => draft.text);
    }
    return Map<String, String>.unmodifiable(mapped);
  }

  List<Map<String, Object?>> get localReviewLineMaps {
    return List<Map<String, Object?>>.unmodifiable(
      lineDrafts.map((draft) => draft.toLocalReviewMap()),
    );
  }

  List<Map<String, Object?>> get privacySafeLineSummaryMaps {
    return List<Map<String, Object?>>.unmodifiable(
      lineDrafts.map((draft) => draft.toPrivacySafeSummaryMap()),
    );
  }
}

List<String> _uniqueStableLineIds(Iterable<ReceiptOcrParserLineSignal> lines) {
  final seen = <String>{};
  return [
    for (final line in lines)
      if (seen.add(line.stableLineId)) line.stableLineId,
  ];
}
