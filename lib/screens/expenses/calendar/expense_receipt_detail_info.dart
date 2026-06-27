part of 'expense_calendar.dart';

class _ReceiptInfoPanel extends StatelessWidget {
  const _ReceiptInfoPanel({required this.receipt});

  final ExpenseReceiptRecord receipt;

  @override
  Widget build(BuildContext context) {
    final addressParts = [
      receipt.street,
      receipt.city,
      receipt.state,
      receipt.zip,
    ].where((part) => part.trim().isNotEmpty).join(', ');
    final contactParts = [
      receipt.phone,
      receipt.email,
      receipt.website,
    ].where((part) => part.trim().isNotEmpty).join(' | ');
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Receipt information',
                  style: TextStyle(
                    color: Color(0xFFF0F4F2),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              _SmallCalendarButton(
                label: 'Edit',
                icon: Icons.edit_rounded,
                onTap: () => _editFullReceipt(context, receipt),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoLine(label: 'Store', value: receipt.title),
          _InfoLine(
            label: 'Receipt proof',
            value: receipt.hasReceiptProof ? 'Attached' : 'Not attached',
          ),
          _InfoLine(
            label: 'Line subtotal',
            value: _money(receipt.lineSubtotal),
          ),
          _InfoLine(
            label: 'Receipt subtotal',
            value: _money(receipt.receiptSubtotal),
          ),
          _InfoLine(
            label: 'Sales tax',
            value: receipt.effectiveTaxRate == null
                ? _money(receipt.receiptTax)
                : '${_money(receipt.receiptTax)} | ${_percent(receipt.effectiveTaxRate!)}',
          ),
          _InfoLine(label: 'Receipt total', value: _money(receipt.total)),
          if (addressParts.isNotEmpty)
            _InfoLine(label: 'Address', value: addressParts),
          if (contactParts.isNotEmpty)
            _InfoLine(label: 'Contact', value: contactParts),
          if (receipt.notes.trim().isNotEmpty)
            _InfoLine(label: 'Notes', value: receipt.notes),
        ],
      ),
    );
  }
}

class _ReceiptAllocationPanel extends StatelessWidget {
  const _ReceiptAllocationPanel({required this.receipt});

  final ExpenseReceiptRecord receipt;

  @override
  Widget build(BuildContext context) {
    final businessLines = receipt.lines
        .where((line) => line.use != ExpenseLineUse.personal)
        .length;
    final personalLines = receipt.lines
        .where((line) => line.use != ExpenseLineUse.business)
        .length;
    final splitLines = receipt.lines
        .where((line) => line.use == ExpenseLineUse.split)
        .length;
    final status = receipt.ocrReview.hasData
        ? (receipt.ocrReview.needsReview ? 'Read needs review' : 'Read saved')
        : 'Manual or proof-only';
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Receipt breakdown',
            style: TextStyle(
              color: Color(0xFFF0F4F2),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ReceiptBreakdownTile(
                  label: 'Business',
                  value: _money(receipt.businessTotal),
                  detail: '$businessLines lines',
                  color: const Color(0xFF8EF6A4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReceiptBreakdownTile(
                  label: 'Personal',
                  value: _money(receipt.personalTotal),
                  detail: '$personalLines lines',
                  color: const Color(0xFFFFD166),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _ReceiptContextChip(
                label: splitLines == 0
                    ? 'No split lines'
                    : '$splitLines split ${splitLines == 1 ? 'line' : 'lines'}',
                icon: Icons.call_split_rounded,
              ),
              _ReceiptContextChip(
                label: receipt.hasReceiptAttachment
                    ? '${receipt.attachments.length} proof ${receipt.attachments.length == 1 ? 'file' : 'files'}'
                    : 'No proof attached',
                icon: receipt.hasReceiptAttachment
                    ? Icons.verified_rounded
                    : Icons.error_outline_rounded,
              ),
              _ReceiptContextChip(
                label: status,
                icon: receipt.ocrReview.needsReview
                    ? Icons.manage_search_rounded
                    : Icons.document_scanner_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptBreakdownTile extends StatelessWidget {
  const _ReceiptBreakdownTile({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFF0F4F2),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptContextChip extends StatelessWidget {
  const _ReceiptContextChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 5, 8, 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2226),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF3E4A50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFC8D0D3), size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF9FAAAF),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
            warning.isEmpty
                ? _statusDetail(review.severity)
                : '$warning. ${_statusDetail(review.severity)}',
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: 0,
            ),
          ),
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
      'blocked' => 'This receipt was saved, but OCR could not complete.',
      'partial' => 'Part of the receipt was saved as proof only.',
      'review' =>
        'The receipt was readable, but the app flagged it for review.',
      _ => 'Receipt read details were saved with this record.',
    };
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

class _ReceiptImagePreview extends StatelessWidget {
  const _ReceiptImagePreview({required this.receipt});

  final ExpenseReceiptRecord receipt;

  @override
  Widget build(BuildContext context) {
    final photoAttachments = receipt.attachments
        .where(
          (attachment) =>
              attachment.isPhoto &&
              attachment.path.trim().isNotEmpty &&
              File(attachment.path).existsSync(),
        )
        .toList(growable: false);
    final pdfAttachments = receipt.attachments
        .where((attachment) => attachment.isPdf)
        .toList(growable: false);
    final hasProof = receipt.hasReceiptAttachment;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE7E0D3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB8AD9B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'RECEIPT PHOTO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF25211A),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          if (photoAttachments.isNotEmpty) ...[
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final attachment = photoAttachments[index];
                  return Semantics(
                    button: true,
                    label: 'Open ${attachment.label}',
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () =>
                            _openReceiptPhotoProof(context, attachment),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(attachment.path),
                            width: 116,
                            height: 168,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const _ReceiptProofUnavailable(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemCount: photoAttachments.length,
              ),
            ),
            if (pdfAttachments.isNotEmpty) const SizedBox(height: 8),
          ],
          if (pdfAttachments.isNotEmpty)
            _ReceiptPdfProofList(attachments: pdfAttachments)
          else if (photoAttachments.isEmpty && hasProof)
            const _ReceiptProofUnavailable()
          else if (photoAttachments.isEmpty)
            const _ReceiptNoProof(),
        ],
      ),
    );
  }
}

void _openReceiptPhotoProof(
  BuildContext context,
  ReceiptAttachmentRecord attachment,
) {
  Navigator.of(context).push<void>(
    appNativeRoute(
      context,
      _ReceiptPhotoProofViewerScreen(attachment: attachment),
    ),
  );
}

class _ReceiptPhotoProofViewerScreen extends StatelessWidget {
  const _ReceiptPhotoProofViewerScreen({required this.attachment});

  final ReceiptAttachmentRecord attachment;

  @override
  Widget build(BuildContext context) {
    final file = File(attachment.path);
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F11),
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: attachment.label,
              actions: [
                IconButton(
                  tooltip: 'Close receipt proof',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFE2E8EA),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: file.existsSync()
                    ? InteractiveViewer(
                        minScale: .75,
                        maxScale: 5,
                        child: Image.file(
                          file,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const _ReceiptProofUnavailable(),
                        ),
                      )
                    : const _ReceiptProofUnavailable(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              child: Text(
                _receiptPhotoProofDetail(attachment),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _receiptPhotoProofDetail(ReceiptAttachmentRecord attachment) {
  final parts = [
    attachment.proofAccessLabel,
    attachment.dataSaverLevel.label,
    if (attachment.byteSize != null)
      ReceiptStorageFormatter.formatBytes(attachment.byteSize!),
  ];
  return parts.join(' | ');
}

class _ReceiptNoProof extends StatelessWidget {
  const _ReceiptNoProof();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'No receipt proof attached.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xFF25211A),
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

class _ReceiptProofUnavailable extends StatelessWidget {
  const _ReceiptProofUnavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 168,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFD7CEBE),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFB8AD9B)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          'Receipt proof could not be previewed.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF25211A),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _ReceiptPdfProofList extends StatelessWidget {
  const _ReceiptPdfProofList({required this.attachments});

  final List<ReceiptAttachmentRecord> attachments;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < attachments.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          _ReceiptPdfProofCard(attachment: attachments[index]),
        ],
      ],
    );
  }
}

class _ReceiptPdfProofCard extends StatelessWidget {
  const _ReceiptPdfProofCard({required this.attachment});

  final ReceiptAttachmentRecord attachment;

  @override
  Widget build(BuildContext context) {
    final details = [
      attachment.readState.label,
      attachment.proofAccessLabel,
      attachment.validationStatus.label,
      attachment.pageCountStatus.label,
      if (attachment.riskFlags.isNotEmpty) 'Review PDF warnings',
      if (attachment.pageCount != null)
        '${attachment.pageCount} ${attachment.pageCount == 1 ? 'page' : 'pages'}',
      if (attachment.byteSize != null)
        ReceiptStorageFormatter.formatBytes(attachment.byteSize!),
    ].join(' | ');
    return Semantics(
      button: true,
      label: 'Open ${attachment.label}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => Navigator.of(context).push<void>(
            appNativeRoute(
              context,
              ReceiptPdfViewerScreen(
                path: attachment.path,
                title: attachment.label,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(6),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFD7CEBE),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFB8AD9B)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFF25211A),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF25211A),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF4D463A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.open_in_full_rounded,
                  color: Color(0xFF25211A),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
