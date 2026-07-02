part of 'receipt_qa_runner.dart';

void _addBusinessReviewIssues({
  required _ReceiptQaFixture fixture,
  required ExpenseReceiptParseResult parsed,
  required List<String> issues,
}) {
  if (fixture.expectedBusinessTotal != null &&
      !_nearMoney(parsed.businessTotal, fixture.expectedBusinessTotal!)) {
    issues.add('production_parser_business_total_mismatch');
  }
  if (fixture.expectedPersonalTotal != null &&
      !_nearMoney(parsed.personalTotal, fixture.expectedPersonalTotal!)) {
    issues.add('production_parser_personal_total_mismatch');
  }
  if (fixture.expectedReviewLineCount != null &&
      parsed.diagnostics.reviewLineCount != fixture.expectedReviewLineCount) {
    issues.add('production_parser_review_line_count_mismatch');
  }
  if (fixture.expectedDownstreamReadinessStatus != null &&
      parsed.diagnostics.parserDownstreamReadinessStatus !=
          fixture.expectedDownstreamReadinessStatus) {
    issues.add(
      'production_parser_downstream_readiness_status_mismatch'
      '(expected=${fixture.expectedDownstreamReadinessStatus}, '
      'actual=${parsed.diagnostics.parserDownstreamReadinessStatus}, '
      'lines=${_lineReviewDebugSummary(parsed.lines)})',
    );
  }
  if (fixture.expectedDownstreamReadinessSummary != null &&
      parsed.diagnostics.downstreamReadinessSummaryLabel !=
          fixture.expectedDownstreamReadinessSummary) {
    issues.add(
      'production_parser_downstream_readiness_summary_mismatch'
      '(expected=${fixture.expectedDownstreamReadinessSummary}, '
      'actual=${parsed.diagnostics.downstreamReadinessSummaryLabel})',
    );
  }
  if (!_readinessCountsMatch(
    parsed.diagnostics.parserDownstreamReadinessCounts,
    fixture.expectedDownstreamReadinessCounts,
  )) {
    issues.add('production_parser_downstream_readiness_counts_mismatch');
  }
  if (!_readinessCountsMatch(
    parsed.diagnostics.parserTaskCounts,
    fixture.expectedParserTaskCounts,
  )) {
    issues.add('production_parser_task_counts_mismatch');
  }
}

void _addBusinessReviewChecks({
  required _ReceiptQaFixture fixture,
  required ExpenseReceiptParseResult parsed,
  required List<_ReceiptQaCheck> checks,
}) {
  void addCheck(String dimension, String name, bool passed) {
    checks.add(
      _ReceiptQaCheck(dimension: dimension, name: name, passed: passed),
    );
  }

  if (fixture.expectedBusinessTotal != null) {
    addCheck(
      'business_personal',
      'business_total_matched',
      _nearMoney(parsed.businessTotal, fixture.expectedBusinessTotal!),
    );
  }
  if (fixture.expectedPersonalTotal != null) {
    addCheck(
      'business_personal',
      'personal_total_matched',
      _nearMoney(parsed.personalTotal, fixture.expectedPersonalTotal!),
    );
  }
  if (fixture.expectedReviewLineCount != null) {
    addCheck(
      'privacy_admin',
      'review_line_count_matched',
      parsed.diagnostics.reviewLineCount == fixture.expectedReviewLineCount,
    );
  }
  if (fixture.expectedDownstreamReadinessStatus != null) {
    addCheck(
      'privacy_admin',
      'downstream_readiness_status_matched',
      parsed.diagnostics.parserDownstreamReadinessStatus ==
          fixture.expectedDownstreamReadinessStatus,
    );
  }
  if (fixture.expectedDownstreamReadinessSummary != null) {
    addCheck(
      'privacy_admin',
      'downstream_readiness_summary_matched',
      parsed.diagnostics.downstreamReadinessSummaryLabel ==
          fixture.expectedDownstreamReadinessSummary,
    );
  }
  if (fixture.expectedDownstreamReadinessCounts.isNotEmpty) {
    addCheck(
      'privacy_admin',
      'downstream_readiness_counts_matched',
      _readinessCountsMatch(
        parsed.diagnostics.parserDownstreamReadinessCounts,
        fixture.expectedDownstreamReadinessCounts,
      ),
    );
  }
  if (fixture.expectedParserTaskCounts.isNotEmpty) {
    addCheck(
      'parser',
      'parser_task_counts_matched',
      _readinessCountsMatch(
        parsed.diagnostics.parserTaskCounts,
        fixture.expectedParserTaskCounts,
      ),
    );
  }
}

bool _readinessCountsMatch(Map<String, int> actual, Map<String, int> expected) {
  for (final entry in expected.entries) {
    if ((actual[entry.key] ?? 0) != entry.value) return false;
  }
  return true;
}

String _lineReviewDebugSummary(List<ExpenseReceiptLineRecord> lines) {
  return lines
      .map((line) {
        final review = line.parserNeedsReview ? 'review' : 'ready';
        return '${line.category}/${line.use.name}/$review';
      })
      .join('|');
}
