part of 'expense_calendar.dart';

class _ReceiptOcrReviewPanel extends StatelessWidget {
  const _ReceiptOcrReviewPanel({required this.review});

  final ExpenseReceiptOcrReview review;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(review.severity);
    final chips = [
      if (review.attachmentsRead > 0) '${review.attachmentsRead} read',
      if (review.attachmentsSkipped > 0)
        '${review.attachmentsSkipped} proof only',
      if (review.parserLineCount > 0)
        '${review.parserLineCount} receipt ${review.parserLineCount == 1 ? 'line' : 'lines'} ready',
      if (review.warningCount > 0)
        '${review.warningCount} OCR ${review.warningCount == 1 ? 'warning' : 'warnings'}',
    ];
    final warning = review.primaryWarningLabel;
    final primaryIssue = review.commandCenterPrimaryIssue;
    final primaryAction = review.commandCenterPrimaryAction;
    final recoveryAction = _recoveryActionLabel(review.recoveryAction);
    final recoveryTarget = _recoveryTargetLabel(review.recoveryTarget);
    final showRecovery = recoveryAction.isNotEmpty || recoveryTarget.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .72)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_statusIcon(review.severity), color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Receipt read review',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Text(
                _statusLabel(review.severity),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (warning.isNotEmpty) warning,
              if (primaryIssue.isNotEmpty) primaryIssue,
              if (primaryAction.isNotEmpty) primaryAction,
              _statusDetail(review.severity),
            ].where((part) => part.trim().isNotEmpty).join('. '),
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: 0,
            ),
          ),
          if (showRecovery) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: color.withValues(alpha: .24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (recoveryAction.isNotEmpty)
                    _ReceiptOcrReviewDetailLine(
                      label: 'Recovery',
                      value: recoveryAction,
                      color: color,
                    ),
                  if (recoveryTarget.isNotEmpty) ...[
                    if (recoveryAction.isNotEmpty) const SizedBox(height: 5),
                    _ReceiptOcrReviewDetailLine(
                      label: 'Check area',
                      value: recoveryTarget,
                      color: color,
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final chip in chips)
                  _ReceiptOcrReviewChip(label: chip, color: color),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Color _statusColor(String severity) {
    return switch (severity) {
      'good' => const Color(0xFF8EF6A4),
      'blocked' => const Color(0xFFFF8FA3),
      'partial' || 'review' => const Color(0xFFFFD166),
      _ => const Color(0xFF34A9E8),
    };
  }

  static IconData _statusIcon(String severity) {
    return switch (severity) {
      'good' => Icons.verified_rounded,
      'blocked' => Icons.error_outline_rounded,
      'partial' => Icons.warning_amber_rounded,
      'review' => Icons.manage_search_rounded,
      _ => Icons.document_scanner_rounded,
    };
  }

  static String _statusLabel(String severity) {
    return switch (severity) {
      'good' => 'Good',
      'blocked' => 'Blocked',
      'partial' => 'Partial',
      'review' => 'Review',
      _ => 'Saved',
    };
  }

  static String _statusDetail(String severity) {
    return switch (severity) {
      'good' => 'The saved receipt read did not need extra review.',
      'blocked' =>
        'This receipt was saved, but Receipt Assist could not finish.',
      'partial' => 'Part of the receipt was saved as proof only.',
      'review' =>
        'The receipt was readable, but the app flagged it for review.',
      _ => 'Receipt read details were saved with this record.',
    };
  }

  static String _recoveryActionLabel(String action) {
    return switch (action.trim()) {
      'add_missing_section' => 'Add missing receipt section',
      'attach_proof' => 'Attach receipt proof',
      'attach_safe_pdf' => 'Attach a safe PDF or photo',
      'choose_clearest_source' => 'Choose the clearest receipt source',
      'manual_entry' || 'manual_receipt_entry' => 'Continue by hand',
      'paste_cleaner_text' => 'Paste cleaner receipt text',
      'replace_pdf_or_add_photo' => 'Replace PDF or add a photo',
      'retake_or_review_photo' => 'Retake or review photo',
      'retake_photo' => 'Retake photo',
      'retake_photo_or_add_section' => 'Retake photo or add section',
      'review_overlap' => 'Check overlap',
      'review_receipt_manually' => 'Review receipt by hand',
      'review_saved_proof' => 'Review saved proof',
      'scan_receipt_with_photos' => 'Scan receipt with photos',
      'use_smaller_pdf_or_photos' => 'Use a smaller PDF or photos',
      _ => '',
    };
  }

  static String _recoveryTargetLabel(String target) {
    return switch (target.trim()) {
      'receipt_attachment' => 'Receipt attachment',
      'receipt_overlap' => 'Long receipt overlap',
      'receipt_sections' => 'Receipt sections',
      'receipt_pdf' => 'Receipt PDF',
      'receipt_photo' => 'Receipt photo',
      'receipt_review' => 'Receipt review',
      'receipt_sources' => 'Receipt sources',
      'receipt_text' => 'Receipt text',
      _ => '',
    };
  }
}

class _ReceiptOcrReviewDetailLine extends StatelessWidget {
  const _ReceiptOcrReviewDetailLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFFE8F0F2),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptOcrReviewChip extends StatelessWidget {
  const _ReceiptOcrReviewChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: .42)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
