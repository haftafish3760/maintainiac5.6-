part of 'receipt_layout_intelligence.dart';

class ReceiptLayoutAnalyzer {
  const ReceiptLayoutAnalyzer();

  ReceiptLayoutMap analyzeText(String sourceText) {
    return analyzeLines(
      sourceText
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false),
    );
  }

  ReceiptLayoutMap analyzeLines(List<String> sourceLines) {
    final cleanLines = sourceLines
        .map(_normalize)
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final output = <ReceiptLayoutLine>[];
    var footerStarted = false;
    for (var index = 0; index < cleanLines.length; index++) {
      final line = cleanLines[index];
      final lower = line.toLowerCase();
      final signals = _signalsFor(
        line: line,
        lower: lower,
        index: index,
        lineCount: cleanLines.length,
        footerAlreadyStarted: footerStarted,
      );
      if (signals.contains(ReceiptLayoutSignal.footerCandidate) ||
          signals.contains(ReceiptLayoutSignal.barcodeCandidate)) {
        footerStarted = true;
      }
      final zone = _zoneFor(
        index: index,
        lineCount: cleanLines.length,
        signals: signals,
        footerStarted: footerStarted,
      );
      output.add(
        ReceiptLayoutLine(
          lineNumber: output.length + 1,
          sourceIndex: index,
          text: line,
          zone: zone,
          signals: Set.unmodifiable(signals),
        ),
      );
    }
    final zoneCounts = <String, int>{};
    final signalCounts = <String, int>{};
    for (final line in output) {
      zoneCounts[line.zone.name] = (zoneCounts[line.zone.name] ?? 0) + 1;
      for (final signal in line.signals) {
        signalCounts[signal.name] = (signalCounts[signal.name] ?? 0) + 1;
      }
    }
    final status = _structureStatusFor(output);
    return ReceiptLayoutMap(
      lines: List.unmodifiable(output),
      zoneCounts: Map.unmodifiable(zoneCounts),
      signalCounts: Map.unmodifiable(signalCounts),
      structureStatus: status,
      structureSummary: _structureSummaryFor(output, status),
    );
  }

  String _normalize(String value) {
    return value
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'[|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Set<ReceiptLayoutSignal> _signalsFor({
    required String line,
    required String lower,
    required int index,
    required int lineCount,
    required bool footerAlreadyStarted,
  }) {
    final signals = <ReceiptLayoutSignal>{};
    final topBand = index <= (lineCount * .22).ceil();
    final lowerBand = index >= (lineCount * .55).floor();

    if (_datePattern.hasMatch(line)) {
      signals.add(ReceiptLayoutSignal.dateCandidate);
    }
    if (_timePattern.hasMatch(line)) {
      signals.add(ReceiptLayoutSignal.timeCandidate);
    }
    if (_moneyPattern.hasMatch(line)) {
      signals.add(ReceiptLayoutSignal.priceCandidate);
    }
    if (_addressPattern.hasMatch(line) || _phonePattern.hasMatch(line)) {
      signals.add(ReceiptLayoutSignal.addressCandidate);
      signals.add(ReceiptLayoutSignal.personalInfoCandidate);
    }
    if (_transactionPattern.hasMatch(lower)) {
      signals.add(ReceiptLayoutSignal.transactionCandidate);
      signals.add(ReceiptLayoutSignal.personalInfoCandidate);
    }
    if (_subtotalPattern.hasMatch(lower)) {
      signals.add(ReceiptLayoutSignal.subtotalCandidate);
    }
    if (_taxPattern.hasMatch(lower)) {
      signals.add(ReceiptLayoutSignal.taxCandidate);
    }
    if (_totalPattern.hasMatch(lower) && !_subtotalPattern.hasMatch(lower)) {
      signals.add(ReceiptLayoutSignal.totalCandidate);
    }
    if (_paymentPattern.hasMatch(lower)) {
      signals.add(ReceiptLayoutSignal.paymentCandidate);
      signals.add(ReceiptLayoutSignal.personalInfoCandidate);
    }
    if (_barcodePattern.hasMatch(lower)) {
      signals.add(ReceiptLayoutSignal.barcodeCandidate);
    }
    if (_footerPattern.hasMatch(lower) || footerAlreadyStarted) {
      signals.add(ReceiptLayoutSignal.footerCandidate);
    }

    final merchantCandidate =
        topBand &&
        !signals.contains(ReceiptLayoutSignal.priceCandidate) &&
        !signals.contains(ReceiptLayoutSignal.dateCandidate) &&
        !signals.contains(ReceiptLayoutSignal.timeCandidate) &&
        !signals.contains(ReceiptLayoutSignal.addressCandidate) &&
        !signals.contains(ReceiptLayoutSignal.transactionCandidate) &&
        !_administrativeHeaderPattern.hasMatch(lower) &&
        _merchantTextPattern.hasMatch(line);
    if (merchantCandidate) signals.add(ReceiptLayoutSignal.merchantCandidate);

    final itemCandidate =
        signals.contains(ReceiptLayoutSignal.priceCandidate) &&
        !signals.contains(ReceiptLayoutSignal.subtotalCandidate) &&
        !signals.contains(ReceiptLayoutSignal.taxCandidate) &&
        !signals.contains(ReceiptLayoutSignal.totalCandidate) &&
        !signals.contains(ReceiptLayoutSignal.paymentCandidate) &&
        !signals.contains(ReceiptLayoutSignal.transactionCandidate) &&
        !signals.contains(ReceiptLayoutSignal.barcodeCandidate) &&
        !signals.contains(ReceiptLayoutSignal.footerCandidate) &&
        !signals.contains(ReceiptLayoutSignal.addressCandidate) &&
        (!topBand || _looksSpecificEnoughForItem(line)) &&
        (!lowerBand || _looksSpecificEnoughForItem(line));
    if (itemCandidate) signals.add(ReceiptLayoutSignal.itemCandidate);

    return signals;
  }

  ReceiptLayoutZone _zoneFor({
    required int index,
    required int lineCount,
    required Set<ReceiptLayoutSignal> signals,
    required bool footerStarted,
  }) {
    if (signals.contains(ReceiptLayoutSignal.footerCandidate) ||
        signals.contains(ReceiptLayoutSignal.barcodeCandidate) ||
        footerStarted && index >= (lineCount * .62).floor()) {
      return ReceiptLayoutZone.footer;
    }
    if (signals.contains(ReceiptLayoutSignal.paymentCandidate)) {
      return ReceiptLayoutZone.payment;
    }
    if (signals.contains(ReceiptLayoutSignal.subtotalCandidate) ||
        signals.contains(ReceiptLayoutSignal.taxCandidate) ||
        signals.contains(ReceiptLayoutSignal.totalCandidate)) {
      return ReceiptLayoutZone.totals;
    }
    if (signals.contains(ReceiptLayoutSignal.itemCandidate)) {
      return ReceiptLayoutZone.itemBody;
    }
    if (signals.contains(ReceiptLayoutSignal.transactionCandidate) ||
        signals.contains(ReceiptLayoutSignal.dateCandidate) ||
        signals.contains(ReceiptLayoutSignal.timeCandidate)) {
      return ReceiptLayoutZone.transaction;
    }
    if (signals.contains(ReceiptLayoutSignal.merchantCandidate) ||
        signals.contains(ReceiptLayoutSignal.addressCandidate) ||
        index <= (lineCount * .25).ceil()) {
      return ReceiptLayoutZone.header;
    }
    return ReceiptLayoutZone.unknown;
  }

  bool _looksSpecificEnoughForItem(String line) {
    final withoutMoney = line
        .replaceAll(_moneyPattern, ' ')
        .replaceAll(RegExp(r'[^a-zA-Z0-9#\- ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final alphaCount = RegExp(r'[A-Za-z]').allMatches(withoutMoney).length;
    return alphaCount >= 3;
  }

  String _structureStatusFor(List<ReceiptLayoutLine> lines) {
    if (lines.isEmpty) return 'no_text';
    final hasMerchant = lines.any((line) => line.likelyMerchantName);
    final hasItems = lines.any((line) => line.likelyItemLine);
    final hasTotal = lines.any((line) => line.likelyTotalLine);
    final hasTax = lines.any((line) => line.likelyTaxLine);
    final hasPayment = lines.any((line) => line.likelyPaymentLine);
    if (hasMerchant && hasItems && hasTotal && hasTax) {
      return 'receipt_structure_ready';
    }
    if (hasMerchant && hasItems && hasTotal) {
      return 'receipt_structure_ready_tax_optional';
    }
    if (hasMerchant && hasItems) return 'receipt_items_need_total_review';
    if (hasMerchant && hasTotal) return 'total_only';
    if (hasItems && hasTotal) return 'unknown_merchant_items_ready';
    if (hasMerchant) return 'header_only';
    if (hasPayment || hasTotal) return 'total_only';
    return 'no_receipt_structure';
  }

  String _structureSummaryFor(List<ReceiptLayoutLine> lines, String status) {
    final merchant = lines.where((line) => line.likelyMerchantName).length;
    final items = lines.where((line) => line.likelyItemLine).length;
    final totals = lines.where((line) => line.likelyTotalLine).length;
    final tax = lines.where((line) => line.likelyTaxLine).length;
    final payment = lines.where((line) => line.likelyPaymentLine).length;
    return 'status=$status;merchant=$merchant;items=$items;totals=$totals;tax=$tax;payment=$payment';
  }
}
