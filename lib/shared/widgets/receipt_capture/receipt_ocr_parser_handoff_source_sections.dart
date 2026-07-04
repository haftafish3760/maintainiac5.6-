part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrParserHandoffSourceSectionMaps on ReceiptOcrParserHandoff {
  Map<String, List<String>> get lineIdsBySourceSection {
    final result = <String, List<String>>{};
    for (final line in lines) {
      final key = _sourceSectionKey(line.sourceLocation);
      result.putIfAbsent(key, () => <String>[]).add(line.stableLineId);
    }
    return Map.unmodifiable({
      for (final entry in result.entries)
        entry.key: List<String>.unmodifiable(entry.value),
    });
  }

  Map<String, int> get lineCountsBySourceSection {
    return Map.unmodifiable({
      for (final entry in lineIdsBySourceSection.entries)
        entry.key: entry.value.length,
    });
  }

  List<int> get sourceSectionNumbersInOrder {
    final sections = <int>[];
    for (final line in lines) {
      final section = line.sourceLocation?.safeSectionNumber;
      if (section == null) continue;
      if (sections.isEmpty || sections.last != section) {
        sections.add(section);
      }
    }
    return List<int>.unmodifiable(sections);
  }

  List<int> get uniqueSourceSectionNumbers {
    final sections = sourceSectionNumbersInOrder.toSet().toList()..sort();
    return List<int>.unmodifiable(sections);
  }

  int get sourceSectionCount => uniqueSourceSectionNumbers.length;

  bool get hasPartialSourceSectionLocations {
    if (lines.isEmpty) return false;
    final withLocation = lines
        .where((line) => line.sourceLocation != null)
        .length;
    return withLocation > 0 && withLocation < lines.length;
  }

  bool get hasOutOfOrderSourceSections {
    var previous = 0;
    for (final section in sourceSectionNumbersInOrder) {
      if (previous > 0 && section < previous) return true;
      previous = section;
    }
    return false;
  }

  bool get hasMissingSourceSectionGap {
    final sections = uniqueSourceSectionNumbers;
    if (sections.length <= 1) return false;
    for (var index = 1; index < sections.length; index++) {
      if (sections[index] - sections[index - 1] > 1) return true;
    }
    return false;
  }

  String get sourceSectionContinuityStatus {
    if (lines.isEmpty) return 'no_text';
    if (sourceSectionCount == 0) return 'no_source_sections';
    if (hasPartialSourceSectionLocations) return 'partial_source_sections';
    if (hasOutOfOrderSourceSections) return 'out_of_order_sections';
    if (uniqueSourceSectionNumbers.first > 1) return 'missing_first_section';
    if (hasMissingSourceSectionGap) return 'missing_section_gap';
    if (sourceSectionCount == 1) return 'single_section';
    return 'continuous_sections';
  }

  bool get needsSourceSectionContinuityReview {
    return switch (sourceSectionContinuityStatus) {
      'partial_source_sections' ||
      'out_of_order_sections' ||
      'missing_first_section' ||
      'missing_section_gap' => true,
      _ => false,
    };
  }

  Map<String, int> get itemLineCountsBySourceSection {
    final counts = <String, int>{};
    for (final line in itemLines) {
      final key = _sourceSectionKey(line.sourceLocation);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, List<String>> get parserReadyLineIdsBySourceSection {
    return _lineIdsBySourceSectionFor(
      lines.where((line) => line.isParserReadyField),
    );
  }

  Map<String, List<String>> get parserReviewLineIdsBySourceSection {
    return _lineIdsBySourceSectionFor(
      lines.where((line) => line.isParserReviewField),
    );
  }

  Map<String, List<String>> _lineIdsBySourceSectionFor(
    Iterable<ReceiptOcrParserLineSignal> source,
  ) {
    final result = <String, List<String>>{};
    for (final line in source) {
      final key = _sourceSectionKey(line.sourceLocation);
      result.putIfAbsent(key, () => <String>[]).add(line.stableLineId);
    }
    return Map.unmodifiable({
      for (final entry in result.entries)
        entry.key: List<String>.unmodifiable(entry.value),
    });
  }

  String _sourceSectionKey(ReceiptOcrParserLineLocation? location) {
    final section = location?.safeSectionNumber;
    return section == null ? 'section_unknown' : 'section_$section';
  }
}
