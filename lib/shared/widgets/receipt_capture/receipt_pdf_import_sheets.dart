part of 'receipt_attachment_panel.dart';

extension _ReceiptPdfImportSheets on _SharedReceiptAttachmentPanelState {
  Future<_PdfReceiptSelectionMode?> _chooseMultiplePdfMode(int count) {
    return showModalBottomSheet<_PdfReceiptSelectionMode>(
      context: context,
      backgroundColor: const Color(0xFF1F2528),
      showDragHandle: true,
      builder: (context) => _PdfMultipleSelectionSheet(count: count),
    );
  }

  Future<_PdfReceiptReadMode?> _choosePdfReadMode(
    int count,
    List<ReceiptPdfInspection> inspections,
  ) async {
    if (widget.onImportedText == null ||
        !_appAssistedReceiptFillEnabled ||
        !inspections.any((inspection) => inspection.canUseAssistedRead)) {
      return _PdfReceiptReadMode.saveProofOnly;
    }
    return showModalBottomSheet<_PdfReceiptReadMode>(
      context: context,
      backgroundColor: const Color(0xFF1F2528),
      showDragHandle: true,
      builder: (context) => _PdfReadModeSheet(
        count: count,
        proofOnlyCount: inspections
            .where((inspection) => !inspection.canUseAssistedRead)
            .length,
      ),
    );
  }

  Future<bool> _confirmLongPdfReading(
    List<ReceiptPdfInspection> inspections,
  ) async {
    final warnings = inspections
        .map((inspection) => inspection.longReceiptWarning)
        .whereType<String>()
        .toList(growable: false);
    if (warnings.isEmpty) return true;
    final shouldRead = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1F2528),
      showDragHandle: true,
      builder: (context) => _PdfLongReadWarningSheet(warnings: warnings),
    );
    return shouldRead ?? false;
  }

  String _pdfAttachedMessage(int count) {
    return count == 1
        ? 'PDF receipt proof attached.'
        : '$count PDFs attached to this receipt.';
  }
}

class _PdfMultipleSelectionSheet extends StatelessWidget {
  const _PdfMultipleSelectionSheet({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _PdfSheetFrame(
      children: [
        _PdfSheetTitle('$count PDFs selected'),
        _PdfSelectionTile(
          icon: Icons.receipt_long_rounded,
          iconColor: const Color(0xFFFFD166),
          title: 'Same Receipt',
          subtitle: 'Use this when one long receipt is split across files.',
          onTap: () => Navigator.of(
            context,
          ).pop(_PdfReceiptSelectionMode.addAllToReceipt),
        ),
        _PdfSelectionTile(
          icon: Icons.looks_one_rounded,
          iconColor: const Color(0xFFA9DFFF),
          title: 'Use First PDF Only',
          subtitle: 'Use this when the extra PDFs are separate receipts.',
          onTap: () =>
              Navigator.of(context).pop(_PdfReceiptSelectionMode.useFirstOnly),
        ),
      ],
    );
  }
}

class _PdfReadModeSheet extends StatelessWidget {
  const _PdfReadModeSheet({required this.count, required this.proofOnlyCount});

  final int count;
  final int proofOnlyCount;

  @override
  Widget build(BuildContext context) {
    final noun = count == 1 ? 'PDF' : '$count PDFs';
    return _PdfSheetFrame(
      children: [
        _PdfSheetTitle('$noun attached'),
        if (proofOnlyCount > 0)
          _PdfSheetWarning(
            proofOnlyCount == 1
                ? 'One PDF will stay proof-only because it is not safe for app-assisted reading.'
                : '$proofOnlyCount PDFs will stay proof-only because they are not safe for app-assisted reading.',
          ),
        _PdfSelectionTile(
          icon: Icons.verified_rounded,
          iconColor: const Color(0xFF8EF6A4),
          title: 'Save Read-Only Proof',
          subtitle:
              'Keep the PDF on this receipt without reading, editing, or changing it.',
          onTap: () =>
              Navigator.of(context).pop(_PdfReceiptReadMode.saveProofOnly),
        ),
        _PdfSelectionTile(
          icon: Icons.document_scanner_rounded,
          iconColor: const Color(0xFFFFD166),
          title: 'Try App-Assisted Fill',
          subtitle:
              'Try filling store, totals, and line items. You still review everything before saving.',
          onTap: () =>
              Navigator.of(context).pop(_PdfReceiptReadMode.readIntoForm),
        ),
      ],
    );
  }
}

class _PdfLongReadWarningSheet extends StatelessWidget {
  const _PdfLongReadWarningSheet({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return _PdfSheetFrame(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      horizontalPadding: 14,
      children: [
        const Text(
          'Review Long PDF',
          style: TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        for (final warning in warnings) ...[
          Text(
            warning,
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
        ],
        const _PdfSheetWarning(
          'Saving proof only is safest. App-assisted fill will only read the allowed front pages and will never edit the PDF proof.',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Save Proof Only'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Read Anyway'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PdfSheetFrame extends StatelessWidget {
  const _PdfSheetFrame({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.horizontalPadding = 12,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.74,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _PdfSheetTitle extends StatelessWidget {
  const _PdfSheetTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PdfSheetWarning extends StatelessWidget {
  const _PdfSheetWarning(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFFFE4A8),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.25,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
