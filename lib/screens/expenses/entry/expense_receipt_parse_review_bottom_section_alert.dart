part of 'expense_receipt_entry_screen.dart';

extension _ReceiptParseReviewBottomSectionAlert
    on _ReceiptAppAssistedReviewIntroPanel {
  bool get _showBottomSectionAlert {
    return ocrDiagnostics?.receiptMayNeedBottomSection == true ||
        parseDiagnostics?.shouldSuggestLowerReceiptSection == true ||
        parseDiagnostics?.hasOcrSourceMissingBottomCoverageEvidence == true ||
        parseDiagnostics?.hasOcrSourceBottomOverlapGhostContinuation == true;
  }

  bool get _missingBottomEdgeAndTotals {
    return ocrDiagnostics?.receiptMissingBottomEdgeAndTotals == true ||
        parseDiagnostics?.hasOcrSourceMissingBottomCoverageEvidence == true;
  }

  bool get _bottomContinuationFromGhost {
    final ocrGhostSliceAlignmentStatus =
        ocrDiagnostics?.ocrSourceGhostSliceAlignmentStatus ?? 'not_requested';
    return parseDiagnostics?.hasOcrSourceBottomOverlapGhostContinuation ==
            true ||
        ocrGhostSliceAlignmentStatus != 'not_requested';
  }

  String get _bottomSectionAlertTitle {
    if (_bottomContinuationFromGhost) {
      return parseDiagnostics?.ocrSourceContinuationReviewLabel ??
          'Bottom continuation uses top ghost slice';
    }
    if (_missingBottomEdgeAndTotals) {
      return 'Bottom edge and totals may be missing';
    }
    if (parseDiagnostics?.shouldSuggestLowerReceiptSection == true) {
      return parseDiagnostics?.lowerReceiptSectionReviewLabel ??
          'Totals may be lower down';
    }
    return 'Bottom section may be missing';
  }

  String get _bottomSectionAlertMessage {
    if (_bottomContinuationFromGhost) {
      return parseDiagnostics?.ocrSourceContinuationReviewInstruction ??
          ocrDiagnostics?.ocrSourceGhostSliceReviewInstruction ??
          'Add the next receipt section and line up 3-5 repeated readable lines in the top ghost slice.';
    }
    if (_missingBottomEdgeAndTotals) {
      return _joinReceiptReviewSentences([
        parseDiagnostics?.ocrSourceCoverageReviewInstruction ??
            'OCR found receipt text, but the bottom edge and subtotal/total lines were not found together. Add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice before saving.',
        parseDiagnostics?.ocrSourceSectionReviewInstruction,
      ]);
    }
    if (parseDiagnostics?.shouldSuggestLowerReceiptSection == true) {
      return _joinReceiptReviewSentences([
        parseDiagnostics?.lowerReceiptSectionReviewInstruction,
        parseDiagnostics?.ocrSourceSectionReviewInstruction,
      ]);
    }
    return 'OCR found receipt text, but it did not find subtotal or total lines. If this was not the full receipt, add the next section before saving.';
  }

  String get _bottomSectionAlertActionLabel {
    if (_bottomContinuationFromGhost) {
      return parseDiagnostics?.ocrSourceContinuationReviewActionLabel ??
          'Add bottom with top ghost slice';
    }
    if (parseDiagnostics?.shouldSuggestLowerReceiptSection == true) {
      return 'Add Lower Section';
    }
    return parseDiagnostics?.ocrSourceCoverageReviewActionLabel ??
        'Add Next Receipt Section';
  }

  Widget _buildBottomSectionAlert() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF261C0A),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFFFD166), width: 1.1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.vertical_align_bottom_rounded,
            color: Color(0xFFFFD166),
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildBottomSectionAlertText()),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onAddMissingBottomSection,
            icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
            label: Text(_bottomSectionAlertActionLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFFD166),
              side: const BorderSide(color: Color(0xFFFFD166)),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
              minimumSize: const Size(0, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(
                fontSize: 11.2,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSectionAlertText() {
    final sourceSectionLabel =
        parseDiagnostics?.ocrSourceSectionReviewLabel.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _bottomSectionAlertTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _bottomSectionAlertMessage,
          style: const TextStyle(
            color: Color(0xFFE8D8A5),
            fontSize: 11.2,
            fontWeight: FontWeight.w800,
            height: 1.22,
            letterSpacing: 0,
          ),
        ),
        if (sourceSectionLabel.isNotEmpty) ...[
          const SizedBox(height: 5),
          _ReceiptReviewInstructionChip(
            icon: Icons.account_tree_rounded,
            label: sourceSectionLabel,
            color: const Color(0xFF34A9E8),
          ),
        ],
      ],
    );
  }
}
