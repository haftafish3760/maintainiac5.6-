class GeneratedParserFixture {
  const GeneratedParserFixture({
    required this.id,
    required this.rawLine,
    required this.caseType,
    this.receiptItemLines = const [],
    this.expectedTrade = '',
    this.expectedNameContains = '',
    this.expectedPackTier = '',
    this.tradeScope,
    this.localePackId = '',
    this.expectUnknown = false,
    this.maxConfidence = 1,
    this.minimumConfidence = 0,
  });

  final String id;
  final String rawLine;
  final String caseType;
  final List<String> receiptItemLines;
  final String expectedTrade;
  final String expectedNameContains;
  final String expectedPackTier;
  final String? tradeScope;
  final String localePackId;
  final bool expectUnknown;
  final double maxConfidence;
  final double minimumConfidence;

  List<String> get parserLines {
    final lines = receiptItemLines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isNotEmpty) return lines;
    return rawLine.trim().isEmpty ? const [] : [rawLine.trim()];
  }

  static GeneratedParserFixture fromJson(Map<String, Object?> json) {
    return GeneratedParserFixture(
      id: json['id'] as String? ?? 'generated_fixture_without_id',
      rawLine: json['rawLine'] as String? ?? '',
      caseType: json['caseType'] as String? ?? '',
      receiptItemLines: [
        for (final line in (json['receiptItemLines'] as List? ?? const []))
          if (line != null) line.toString(),
      ],
      expectedTrade: json['expectedTrade'] as String? ?? '',
      expectedNameContains: json['expectedNameContains'] as String? ?? '',
      expectedPackTier: json['expectedPackTier'] as String? ?? '',
      tradeScope: json['tradeScope'] as String?,
      localePackId: json['localePackId'] as String? ?? '',
      expectUnknown: json['expectUnknown'] as bool? ?? false,
      maxConfidence: (json['maxConfidence'] as num?)?.toDouble() ?? 1,
      minimumConfidence: (json['minimumConfidence'] as num?)?.toDouble() ?? 0,
    );
  }
}
