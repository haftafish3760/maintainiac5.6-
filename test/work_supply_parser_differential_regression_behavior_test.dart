import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inventory parser differential regression behavior', () {
    test('reports every changed parser result with old and new evidence', () {
      final report = _buildDifferentialRegressionReport(
        oldResults: const [
          _ParserSnapshot(
            fixtureId: 'reg_hd_pvc_coupling',
            merchant: 'Home Depot',
            locale: 'en-US',
            trade: 'Plumbing',
            candidateId: 'PLUMBING-PVC-COUPLING',
            confidence: .91,
            reviewStatus: 'review-only',
            category: 'Fittings',
          ),
          _ParserSnapshot(
            fixtureId: 'reg_spanish_hvac_filter',
            merchant: 'Walmart',
            locale: 'es-US',
            trade: 'HVAC',
            candidateId: 'HVAC-FILTER-20X25X1',
            confidence: .88,
            reviewStatus: 'review-only',
            category: 'Filters',
          ),
        ],
        newResults: const [
          _ParserSnapshot(
            fixtureId: 'reg_hd_pvc_coupling',
            merchant: 'Home Depot',
            locale: 'en-US',
            trade: 'Plumbing',
            candidateId: 'ELECTRICAL-PVC-CONDUIT',
            confidence: .94,
            reviewStatus: 'auto-save',
            category: 'Conduit',
          ),
          _ParserSnapshot(
            fixtureId: 'reg_spanish_hvac_filter',
            merchant: 'Walmart',
            locale: 'es-US',
            trade: 'HVAC',
            candidateId: 'HVAC-FILTER-20X25X1',
            confidence: .78,
            reviewStatus: 'review-only',
            category: 'Filters',
          ),
        ],
      );

      expect(report.changedResults, hasLength(2));
      final blocking = report.changedResults
          .where((change) => change.blockingRegression)
          .firstWhere((change) => change.fixtureId == 'reg_hd_pvc_coupling');
      expect(blocking.fixtureId, 'reg_hd_pvc_coupling');
      expect(blocking.oldCandidateId, 'PLUMBING-PVC-COUPLING');
      expect(blocking.newCandidateId, 'ELECTRICAL-PVC-CONDUIT');
      expect(blocking.oldReviewStatus, 'review-only');
      expect(blocking.newReviewStatus, 'auto-save');
      expect(blocking.oldCategory, 'Fittings');
      expect(blocking.newCategory, 'Conduit');
      expect(blocking.changeReason, contains('candidate'));
      expect(blocking.changeReason, contains('review status'));
      expect(blocking.approvedChange, isFalse);
    });

    test('allows expected improvements only when approval note is present', () {
      final report = _buildDifferentialRegressionReport(
        oldResults: const [
          _ParserSnapshot(
            fixtureId: 'reg_lowes_pex_elbow',
            merchant: 'Lowe',
            locale: 'en-US',
            trade: 'Plumbing',
            candidateId: 'UNKNOWN',
            confidence: .20,
            reviewStatus: 'unknown',
            category: 'unknown',
          ),
        ],
        newResults: const [
          _ParserSnapshot(
            fixtureId: 'reg_lowes_pex_elbow',
            merchant: 'Lowe',
            locale: 'en-US',
            trade: 'Plumbing',
            candidateId: 'PLUMBING-PEX-ELBOW',
            confidence: .89,
            reviewStatus: 'review-only',
            category: 'Fittings',
            approvedChangeNote: 'Added PEX crimp elbow alias.',
          ),
        ],
      );

      expect(report.changedResults, hasLength(1));
      expect(report.changedResults.single.approvedChange, isTrue);
      expect(report.changedResults.single.blockingRegression, isFalse);
      expect(report.changedResults.single.changeReason, contains('approved'));
    });

    test('groups changed results by trade merchant and locale', () {
      final report = _buildDifferentialRegressionReport(
        oldResults: const [
          _ParserSnapshot(
            fixtureId: 'reg_ferg_no_hub',
            merchant: 'Ferguson',
            locale: 'en-US',
            trade: 'Plumbing',
            candidateId: 'PLUMBING-NO-HUB',
            confidence: .86,
            reviewStatus: 'review-only',
            category: 'DWV',
          ),
        ],
        newResults: const [
          _ParserSnapshot(
            fixtureId: 'reg_ferg_no_hub',
            merchant: 'Ferguson',
            locale: 'en-US',
            trade: 'Plumbing',
            candidateId: 'PLUMBING-GENERIC-COUPLING',
            confidence: .83,
            reviewStatus: 'review-only',
            category: 'Fittings',
          ),
        ],
      );

      expect(report.byTrade, {'Plumbing': 1});
      expect(report.byMerchant, {'Ferguson': 1});
      expect(report.byLocale, {'en-US': 1});
      expect(report.localOnly, isTrue);
      expect(report.liveFirebaseWrites, isFalse);
      expect(report.surgicalRerunTargets, ['reg_ferg_no_hub']);
    });
  });
}

_DifferentialReport _buildDifferentialRegressionReport({
  required List<_ParserSnapshot> oldResults,
  required List<_ParserSnapshot> newResults,
}) {
  final oldById = {for (final result in oldResults) result.fixtureId: result};
  final changes = <_ParserChange>[];
  for (final current in newResults) {
    final previous = oldById[current.fixtureId];
    if (previous == null) continue;
    final reasons = <String>[];
    if (previous.candidateId != current.candidateId) {
      reasons.add('candidate changed');
    }
    if ((previous.confidence - current.confidence).abs() >= .05) {
      reasons.add('confidence changed');
    }
    if (previous.reviewStatus != current.reviewStatus) {
      reasons.add('review status changed');
    }
    if (previous.category != current.category) {
      reasons.add('category changed');
    }
    if (reasons.isEmpty) continue;
    final approved = current.approvedChangeNote.trim().isNotEmpty;
    changes.add(
      _ParserChange(
        fixtureId: current.fixtureId,
        trade: current.trade,
        merchant: current.merchant,
        locale: current.locale,
        oldCandidateId: previous.candidateId,
        newCandidateId: current.candidateId,
        oldConfidence: previous.confidence,
        newConfidence: current.confidence,
        oldReviewStatus: previous.reviewStatus,
        newReviewStatus: current.reviewStatus,
        oldCategory: previous.category,
        newCategory: current.category,
        changeReason:
            '${reasons.join(', ')}${approved ? '; approved: ${current.approvedChangeNote}' : ''}',
        approvedChange: approved,
      ),
    );
  }
  return _DifferentialReport(changedResults: changes);
}

class _ParserSnapshot {
  const _ParserSnapshot({
    required this.fixtureId,
    required this.merchant,
    required this.locale,
    required this.trade,
    required this.candidateId,
    required this.confidence,
    required this.reviewStatus,
    required this.category,
    this.approvedChangeNote = '',
  });

  final String fixtureId;
  final String merchant;
  final String locale;
  final String trade;
  final String candidateId;
  final double confidence;
  final String reviewStatus;
  final String category;
  final String approvedChangeNote;
}

class _ParserChange {
  const _ParserChange({
    required this.fixtureId,
    required this.trade,
    required this.merchant,
    required this.locale,
    required this.oldCandidateId,
    required this.newCandidateId,
    required this.oldConfidence,
    required this.newConfidence,
    required this.oldReviewStatus,
    required this.newReviewStatus,
    required this.oldCategory,
    required this.newCategory,
    required this.changeReason,
    required this.approvedChange,
  });

  final String fixtureId;
  final String trade;
  final String merchant;
  final String locale;
  final String oldCandidateId;
  final String newCandidateId;
  final double oldConfidence;
  final double newConfidence;
  final String oldReviewStatus;
  final String newReviewStatus;
  final String oldCategory;
  final String newCategory;
  final String changeReason;
  final bool approvedChange;

  bool get blockingRegression {
    if (approvedChange) return false;
    return oldCandidateId != newCandidateId ||
        oldReviewStatus != newReviewStatus ||
        oldCategory != newCategory ||
        newConfidence < oldConfidence - .05;
  }
}

class _DifferentialReport {
  const _DifferentialReport({required this.changedResults});

  final List<_ParserChange> changedResults;

  bool get localOnly => true;
  bool get liveFirebaseWrites => false;

  Map<String, int> get byTrade => _countBy((change) => change.trade);
  Map<String, int> get byMerchant => _countBy((change) => change.merchant);
  Map<String, int> get byLocale => _countBy((change) => change.locale);

  List<String> get surgicalRerunTargets => [
    for (final change in changedResults) change.fixtureId,
  ];

  Map<String, int> _countBy(String Function(_ParserChange change) keyFor) {
    final counts = <String, int>{};
    for (final change in changedResults) {
      counts.update(keyFor(change), (count) => count + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}
