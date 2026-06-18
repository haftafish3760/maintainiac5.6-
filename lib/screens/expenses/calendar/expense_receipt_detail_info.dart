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
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File(attachment.path),
                      width: 116,
                      height: 168,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _ReceiptProofUnavailable(),
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
