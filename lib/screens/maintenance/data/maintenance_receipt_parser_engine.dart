part of 'maintenance_receipt_parser.dart';

MaintenanceReceiptParserResult parseMaintenanceReceipt(
  MaintenanceReceiptParserInput input,
) {
  final sourceWasTruncated =
      input.sourceText.length > _maxSourceCharacters ||
      '\n'.allMatches(input.sourceText).length + 1 > _maxSourceRows;
  final rows = _sourceRows(input.sourceText);
  final lower = rows.map((row) => row.comparisonText).join(' ');
  final hasMaintenanceRetailMerchant = _maintenanceRetailMerchant.hasMatch(
    lower,
  );
  final hasPurchaseSignals =
      hasMaintenanceRetailMerchant || _purchaseSignal.hasMatch(lower);
  final hasServiceSignals = _serviceSignal.hasMatch(lower);
  final hasStrongServiceSignals = _strongServiceSignal.hasMatch(lower);
  final kind = switch ((hasPurchaseSignals, hasServiceSignals)) {
    (true, true) => MaintenanceReceiptKind.mixed,
    (true, false) => MaintenanceReceiptKind.partsPurchase,
    (false, true) => MaintenanceReceiptKind.serviceInvoice,
    _ => MaintenanceReceiptKind.unknown,
  };
  final merchantName = _merchantName(rows);
  final dateRead = _receiptDate(rows, input.locale, input.referenceDate);
  final receiptDate = dateRead.date;
  final dueDateRead = _nextDueDate(rows, input.locale);
  final dueDate = dueDateRead.date;
  final distanceComparison = lower.replaceAll(',', '');
  final hasServiceKilometers = rows.any(
    (row) =>
        _serviceOdometerKilometersPattern.hasMatch(
          row.comparisonText.replaceAll(',', ''),
        ) &&
        !_dueOdometerKilometersPattern.hasMatch(
          row.comparisonText.replaceAll(',', ''),
        ),
  );
  final hasDueKilometers = _dueOdometerKilometersPattern.hasMatch(
    distanceComparison,
  );
  final hasIntervalKilometers = _intervalKilometersPattern.hasMatch(
    distanceComparison,
  );
  final serviceOdometerIn = _readingFor(lower, _serviceOdometerInPattern);
  final serviceOdometerOut = _readingFor(lower, _serviceOdometerOutPattern);
  final serviceOdometer = hasServiceKilometers
      ? null
      : _serviceOdometerFor(lower);
  final dueOdometer = hasDueKilometers
      ? null
      : _readingFor(lower, _dueOdometerPattern);
  final explicitInterval = _readingFor(lower, _intervalMilesPattern);
  final inferredInterval =
      serviceOdometer != null &&
          dueOdometer != null &&
          dueOdometer > serviceOdometer &&
          dueOdometer - serviceOdometer >= 500 &&
          dueOdometer - serviceOdometer <= 100000
      ? dueOdometer - serviceOdometer
      : null;
  final intervalMiles = explicitInterval ?? inferredInterval;
  final explicitIntervalMonths = _readingFor(lower, _intervalMonthsPattern);
  final inferredIntervalMonths = _wholeMonthInterval(receiptDate, dueDate);
  final intervalMonths = explicitIntervalMonths ?? inferredIntervalMonths;
  final documentIsNonCompleted =
      _estimateOrQuoteSignal.hasMatch(lower) &&
      !_explicitCompletionSignal.hasMatch(lower);
  final canUseServiceAliases =
      hasServiceSignals &&
      (!hasMaintenanceRetailMerchant || hasStrongServiceSignals);
  final matchingRowsByItem = {
    for (final definition in _itemDefinitions)
      definition.itemName: _matchingRowsForDefinition(
        rows,
        definition,
        includeServiceAliases: canUseServiceAliases,
      ),
  };
  final matchedItemNames = matchingRowsByItem.entries
      .where((entry) => entry.value.isNotEmpty)
      .map((entry) => entry.key)
      .toSet();
  final hasItemScopedReturnOrExchange = matchingRowsByItem.values
      .expand((matchingRows) => matchingRows)
      .any((row) => _isReturnOrExchangeText(row.comparisonText));
  final hasUnscopedNotCompletedSignal = rows.any(
    (row) =>
        _notCompletedLine.hasMatch(row.comparisonText) &&
        !_notCompletedSectionHeading.hasMatch(row.comparisonText) &&
        !_itemDefinitions.any(
          (definition) => _definitionMatchesText(
            definition,
            row.comparisonText,
            includeServiceAliases: canUseServiceAliases,
          ),
        ),
  );
  final hasUnscopedReturnOrExchangeSignal = rows.any(
    (row) =>
        _isReturnOrExchangeText(row.comparisonText) &&
        (!hasItemScopedReturnOrExchange ||
            _standaloneReturnHeading.hasMatch(row.comparisonText)) &&
        !_itemDefinitions.any(
          (definition) => _definitionMatchesText(
            definition,
            row.comparisonText,
            includeServiceAliases: canUseServiceAliases,
          ),
        ),
  );
  final candidates = <MaintenanceReceiptCandidate>[];

  for (final definition in _itemDefinitions) {
    final matchingRows = matchingRowsByItem[definition.itemName]!;
    if (matchingRows.isEmpty) continue;
    final detailText = _detailTextFor(definition, rows, matchingRows);
    final detailA = definition.detailA(detailText);
    final detailB = definition.detailB(detailText);

    final itemNotCompleted =
        hasUnscopedNotCompletedSignal ||
        matchingRows.any((row) => _rowFollowsNotCompletedSection(rows, row)) ||
        matchingRows.any(
          (row) => _notCompletedLine.hasMatch(row.comparisonText),
        );
    final returnOrExchange =
        hasUnscopedReturnOrExchangeSignal ||
        matchingRows.any((row) => _isReturnOrExchangeText(row.comparisonText));
    final itemSpecificSchedule = rows.any((row) {
      final rowText = row.comparisonText;
      return _definitionMatchesText(
            definition,
            rowText,
            includeServiceAliases: canUseServiceAliases,
          ) &&
          (_dueOdometerPattern.hasMatch(rowText) ||
              _intervalMilesPattern.hasMatch(rowText) ||
              _intervalMonthsPattern.hasMatch(rowText) ||
              _nextDueDateSignal.hasMatch(rowText));
    });
    final acceptsGenericSchedule =
        matchedItemNames.length == 1 || definition.itemName == 'Engine Oil';
    final scheduleApplies = itemSpecificSchedule || acceptsGenericSchedule;
    final itemServiceIndicated =
        hasServiceSignals &&
        (!hasMaintenanceRetailMerchant || hasStrongServiceSignals) &&
        !documentIsNonCompleted &&
        !itemNotCompleted &&
        !returnOrExchange &&
        (definition.servicePattern.hasMatch(lower) ||
            matchingRows.any((row) => _rowFollowsCompletedSection(rows, row)) ||
            matchingRows.any(
              (row) =>
                  _performedOnLine.hasMatch(row.comparisonText) &&
                  !_notCompletedLine.hasMatch(row.comparisonText),
            ));
    final productPurchased =
        hasPurchaseSignals &&
        !returnOrExchange &&
        (matchingRows.any(
              (row) =>
                  _pricedLine.hasMatch(row.comparisonText) ||
                  _purchaseLineSignal.hasMatch(row.comparisonText),
            ) ||
            (hasMaintenanceRetailMerchant &&
                _transactionCompletionSignal.hasMatch(lower)));
    final action =
        itemNotCompleted || returnOrExchange || documentIsNonCompleted
        ? MaintenanceReceiptAction.manualReview
        : itemServiceIndicated
        ? MaintenanceReceiptAction.reviewCompletedService
        : productPurchased
        ? MaintenanceReceiptAction.reviewTrackingSetup
        : MaintenanceReceiptAction.manualReview;
    var confidence = .52;
    if (matchingRows.length > 1) confidence += .08;
    if (itemServiceIndicated) confidence += .20;
    if (productPurchased) confidence += .12;
    if (serviceOdometer != null && itemServiceIndicated) confidence += .05;
    if (receiptDate != null) confidence += .03;
    if (detailA != null) confidence += .04;
    if (detailB != null) confidence += .04;

    candidates.add(
      MaintenanceReceiptCandidate(
        itemName: definition.itemName,
        action: action,
        confidence: confidence.clamp(0, .96).toDouble(),
        evidence: List.unmodifiable([
          for (final row in matchingRows.take(4))
            MaintenanceReceiptEvidence(
              code: itemServiceIndicated
                  ? 'service_language'
                  : productPurchased
                  ? 'purchased_product'
                  : 'maintenance_term',
              lineNumber: row.lineNumber,
              safeSnippet: _safeSnippet(row.text),
            ),
        ]),
        detailA: detailA,
        detailB: detailB,
        serviceDate: itemServiceIndicated ? receiptDate : null,
        serviceOdometer: itemServiceIndicated ? serviceOdometer : null,
        dueOdometer: itemServiceIndicated && scheduleApplies
            ? dueOdometer
            : null,
        intervalMiles: itemServiceIndicated && scheduleApplies
            ? intervalMiles
            : null,
        intervalMonths: itemServiceIndicated && scheduleApplies
            ? intervalMonths
            : null,
        productPurchased: productPurchased,
        completedServiceIndicated: itemServiceIndicated,
        returnOrExchangeIndicated: returnOrExchange,
        notCompletedIndicated: itemNotCompleted || documentIsNonCompleted,
      ),
    );
  }

  candidates.sort((a, b) {
    final confidence = b.confidence.compareTo(a.confidence);
    return confidence != 0 ? confidence : a.itemName.compareTo(b.itemName);
  });

  final warnings = <String>[
    if (rows.isEmpty) 'No readable receipt text was supplied.',
    if (sourceWasTruncated)
      'Receipt text exceeded local parser limits and was truncated; review the source manually.',
    if (input.activeVehicleId.trim().isEmpty)
      'Select a vehicle before applying maintenance suggestions.',
    if (dateRead.ambiguousNumeric)
      'Ambiguous numeric receipt date was interpreted using ${input.locale.trim()}; confirm the date.',
    if (dateRead.unsupportedLocale)
      'The receipt date locale is unsupported; enter the service date manually.',
    if (dateRead.futureDateRejected)
      'A future receipt date was ignored; confirm or enter the service date manually.',
    if (dueDateRead.ambiguousNumeric)
      'An ambiguous next-service date was interpreted using ${input.locale.trim()}; confirm the time interval.',
    if (dueDateRead.unsupportedLocale)
      'The next-service date locale is unsupported; enter the time interval manually.',
    if (receiptDate != null && dueDate != null && !dueDate.isAfter(receiptDate))
      'The next-service date is not after the receipt service date.',
    if (receiptDate != null &&
        dueDate != null &&
        dueDate.isAfter(receiptDate) &&
        inferredIntervalMonths == null &&
        explicitIntervalMonths == null)
      'The next-service date is not a whole-month interval; confirm the time interval.',
    if (kind == MaintenanceReceiptKind.partsPurchase && candidates.isNotEmpty)
      'A parts purchase does not prove that any part or fluid was installed.',
    if (kind == MaintenanceReceiptKind.mixed)
      'This receipt contains both purchase and service signals; review each item.',
    if (documentIsNonCompleted)
      'Estimate or quote language was found without proof that the work was completed.',
    if (candidates.any((candidate) => candidate.notCompletedIndicated))
      'Recommended, declined, or deferred work must not be logged as completed service.',
    if (candidates.any((candidate) => candidate.returnOrExchangeIndicated))
      'Returned or exchanged products require manual review before maintenance setup.',
    if (serviceOdometer != null &&
        input.currentOdometer != null &&
        serviceOdometer > input.currentOdometer!)
      'The receipt odometer is above the selected vehicle current odometer.',
    if (serviceOdometerIn != null &&
        !hasServiceKilometers &&
        serviceOdometerOut != null &&
        serviceOdometerOut < serviceOdometerIn)
      'The receipt mileage out is below mileage in; confirm the service odometer.',
    if (hasServiceKilometers || hasDueKilometers || hasIntervalKilometers)
      'Receipt distance evidence is in kilometers, but maintenance currently stores miles; enter converted values manually.',
    if (serviceOdometer != null &&
        dueOdometer != null &&
        dueOdometer <= serviceOdometer)
      'The next-due odometer is not above the service odometer.',
    if (candidates.isNotEmpty &&
        candidates.every(
          (candidate) =>
              candidate.action == MaintenanceReceiptAction.manualReview,
        ))
      'Maintenance terms were found without enough evidence to choose setup or service history.',
  ];

  final reviewStatus = candidates.isEmpty
      ? MaintenanceReceiptReviewStatus.noMaintenanceEvidence
      : warnings.any(
          (warning) =>
              warning.contains('above the selected') ||
              warning.contains('mileage out is below') ||
              warning.contains('distance evidence is in kilometers') ||
              warning.contains('not above') ||
              warning.contains('Estimate or quote') ||
              warning.contains('Recommended, declined') ||
              warning.contains('Returned or exchanged') ||
              warning.contains('Ambiguous numeric') ||
              warning.contains('date locale is unsupported') ||
              warning.contains('future receipt date') ||
              warning.contains('next-service date') ||
              warning.contains('exceeded local parser limits') ||
              warning.contains('without enough evidence'),
        )
      ? MaintenanceReceiptReviewStatus.needsDetails
      : MaintenanceReceiptReviewStatus.readyForReview;

  return MaintenanceReceiptParserResult(
    kind: kind,
    reviewStatus: reviewStatus,
    merchantName: merchantName,
    receiptDate: receiptDate,
    candidates: List.unmodifiable(candidates),
    warnings: List.unmodifiable(warnings),
    activeVehicleId: input.activeVehicleId.trim(),
    activeVehicleName: input.activeVehicleName.trim(),
    sourceFingerprintSha256: _sourceFingerprint(input.sourceText),
  );
}

List<_SourceRow> _matchingRowsForDefinition(
  List<_SourceRow> rows,
  _ItemDefinition definition, {
  required bool includeServiceAliases,
}) {
  final direct = rows
      .where(
        (row) => _definitionMatchesText(
          definition,
          row.comparisonText,
          includeServiceAliases: includeServiceAliases,
        ),
      )
      .toList(growable: false);
  if (direct.isNotEmpty) return direct;

  List<_SourceRow>? bestWindow;
  var bestDetailScore = -1;
  for (var windowSize = 2; windowSize <= 3; windowSize++) {
    for (var index = 0; index + windowSize <= rows.length; index++) {
      final window = rows.sublist(index, index + windowSize);
      final joined = window.map((row) => row.comparisonText).join(' ');
      if (_definitionMatchesText(
        definition,
        joined,
        includeServiceAliases: includeServiceAliases,
      )) {
        final detailScore =
            (definition.detailA(joined) == null ? 0 : 1) +
            (definition.detailB(joined) == null ? 0 : 1);
        if (bestWindow == null || detailScore > bestDetailScore) {
          bestWindow = window;
          bestDetailScore = detailScore;
        }
      }
    }
  }
  return bestWindow == null ? const [] : List.unmodifiable(bestWindow);
}

bool _definitionMatchesText(
  _ItemDefinition definition,
  String text, {
  required bool includeServiceAliases,
}) {
  return definition.pattern.hasMatch(text) ||
      (includeServiceAliases && definition.servicePattern.hasMatch(text));
}

String _detailTextFor(
  _ItemDefinition definition,
  List<_SourceRow> rows,
  List<_SourceRow> matchingRows,
) {
  final localText = matchingRows.map((row) => row.comparisonText).join(' ');
  if (definition.itemName != 'Engine Oil' ||
      definition.detailA(localText) != null) {
    return localText;
  }

  final firstIndex = rows.indexOf(matchingRows.first);
  if (firstIndex <= 0) return localText;
  final precedingText = rows[firstIndex - 1].comparisonText;
  return _oilType(precedingText) == null
      ? localText
      : '$precedingText $localText';
}

bool _isReturnOrExchangeText(String text) {
  return _returnOrExchangeLine.hasMatch(text) &&
      !_coreAdjustmentLine.hasMatch(text) &&
      !_transactionPolicyLine.hasMatch(text);
}

bool _rowFollowsNotCompletedSection(
  List<_SourceRow> rows,
  _SourceRow matchingRow,
) {
  final rowIndex = rows.indexOf(matchingRow);
  for (var index = rowIndex - 1; index >= 0; index--) {
    final text = rows[index].comparisonText;
    if (_notCompletedSectionHeading.hasMatch(text)) return true;
    if (_completedSectionHeading.hasMatch(text)) return false;
  }
  return false;
}

bool _rowFollowsCompletedSection(
  List<_SourceRow> rows,
  _SourceRow matchingRow,
) {
  final rowIndex = rows.indexOf(matchingRow);
  for (var index = rowIndex - 1; index >= 0; index--) {
    final text = rows[index].comparisonText;
    if (_notCompletedSectionHeading.hasMatch(text)) return false;
    if (_completedSectionHeading.hasMatch(text)) return true;
  }
  return false;
}
