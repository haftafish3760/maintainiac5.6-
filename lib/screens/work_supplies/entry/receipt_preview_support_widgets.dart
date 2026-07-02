part of 'work_supply_add_items_screen.dart';

class _ReceiptLineReviewDetail extends StatelessWidget {
  const _ReceiptLineReviewDetail({required this.line});

  final ReceiptLineDraft line;

  @override
  Widget build(BuildContext context) {
    final reviewColor = switch (line.assistedReviewLabel) {
      'Good' => const Color(0xFF7EE0A1),
      'Poor' => const Color(0xFFFF8A8A),
      _ => const Color(0xFFFFD166),
    };
    final statusColor = line.requiresInventoryConfirmation
        ? const Color(0xFFFFD166)
        : switch (line.reviewState) {
            ReceiptLineReviewState.corrected => const Color(0xFFFFD166),
            ReceiptLineReviewState.confirmed => const Color(0xFF7EE0A1),
            ReceiptLineReviewState.needsReview => const Color(0xFFFF8A8A),
            _ => const Color(0xFFA9DFFF),
          };
    final terms = line.catalogMatchedTerms.take(4).toList(growable: false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF10161A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF46545C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _ReceiptPillBadge(
                label: 'Review: ${line.assistedReviewLabel}',
                color: reviewColor,
              ),
              _ReceiptPillBadge(
                label: line.reviewStatusLabel,
                color: statusColor,
              ),
              if (line.catalogMatchLabel.isNotEmpty)
                _ReceiptPillBadge(
                  label: line.catalogMatchLabel,
                  color: const Color(0xFFA9DFFF),
                ),
              if (line.hasCorrectionAudit)
                _ReceiptPillBadge(
                  label: line.reviewActionLabel,
                  color: line.wasChangedFromParsedGuess
                      ? const Color(0xFFFFD166)
                      : const Color(0xFF7EE0A1),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            line.receiptReviewSummary,
            style: const TextStyle(
              color: Color(0xFFD6DEE2),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          if (line.assistedReviewDetail.trim().isNotEmpty &&
              line.assistedReviewDetail.trim() !=
                  line.receiptReviewSummary.trim()) ...[
            const SizedBox(height: 4),
            Text(
              line.assistedReviewDetail,
              style: const TextStyle(
                color: Color(0xFFB8C4C9),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
          if (terms.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Matched: ${terms.join(', ')}',
              style: const TextStyle(
                color: Color(0xFFB8C4C9),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
          if (line.rawReceiptText.trim().isNotEmpty &&
              line.rawReceiptText.trim() != line.displayDescription.trim()) ...[
            const SizedBox(height: 4),
            Text(
              'Receipt text: ${line.rawReceiptText.trim()}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF9EA9AE),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
          if (line.wasChangedFromParsedGuess) ...[
            const SizedBox(height: 4),
            Text(
              'Original guess: ${line.originalParsedDescription.trim()}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFD166),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReceiptPreviewBreakdown extends StatelessWidget {
  const _ReceiptPreviewBreakdown({
    required this.inventoryCount,
    required this.businessOnlyCount,
    required this.personalCount,
    required this.splitCount,
    required this.confirmNeededCount,
  });

  final int inventoryCount;
  final int businessOnlyCount;
  final int personalCount;
  final int splitCount;
  final int confirmNeededCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _ReceiptCountPill(
          label: 'Inventory',
          value: inventoryCount,
          color: const Color(0xFF63B3E6),
        ),
        _ReceiptCountPill(
          label: 'Business only',
          value: businessOnlyCount,
          color: const Color(0xFFFFC46B),
        ),
        _ReceiptCountPill(
          label: 'Personal',
          value: personalCount,
          color: const Color(0xFFE0A7FF),
        ),
        _ReceiptCountPill(
          label: 'Split',
          value: splitCount,
          color: const Color(0xFFFFD166),
        ),
        if (confirmNeededCount > 0)
          _ReceiptCountPill(
            label: 'Confirm',
            value: confirmNeededCount,
            color: const Color(0xFFFF8A8A),
          ),
      ],
    );
  }
}

class _ReceiptCountPill extends StatelessWidget {
  const _ReceiptCountPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF151811),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFFE8ECEE),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReceiptLaneBadge extends StatelessWidget {
  const _ReceiptLaneBadge({required this.line});

  final ReceiptLineDraft line;

  @override
  Widget build(BuildContext context) {
    return _ReceiptPillBadge(
      label: line.receiptLaneLabel,
      color: _receiptLaneColor(line),
    );
  }
}

class _ReceiptUseBadge extends StatelessWidget {
  const _ReceiptUseBadge({required this.line});

  final ReceiptLineDraft line;

  @override
  Widget build(BuildContext context) {
    return _ReceiptPillBadge(
      label: line.businessUseLabel,
      color: _businessUseColor(line),
    );
  }
}

class _ReceiptPillBadge extends StatelessWidget {
  const _ReceiptPillBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF07100A),
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Color _receiptLaneColor(ReceiptLineDraft line) {
  if (line.isInventory) return const Color(0xFF63B3E6);
  if (line.isPersonalUse) return const Color(0xFFE0A7FF);
  if (line.isSplitUse) return const Color(0xFFFFD166);
  return const Color(0xFFFFC46B);
}

Color _businessUseColor(ReceiptLineDraft line) {
  if (line.isPersonalUse) return const Color(0xFFE0A7FF);
  if (line.isSplitUse) return const Color(0xFFFFD166);
  return const Color(0xFF63B3E6);
}

class _MiniReceiptStat extends StatelessWidget {
  const _MiniReceiptStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8F9A9F),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ReceiptPreviewTotalRow extends StatelessWidget {
  const _ReceiptPreviewTotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasized
                    ? const Color(0xFFE8ECEE)
                    : const Color(0xFFC7D0D4),
                fontSize: emphasized ? 14 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: emphasized
                  ? const Color(0xFFA9DFFF)
                  : const Color(0xFFE8ECEE),
              fontSize: emphasized ? 15 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
