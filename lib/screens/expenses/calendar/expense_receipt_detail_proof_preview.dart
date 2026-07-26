part of 'expense_calendar.dart';

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
