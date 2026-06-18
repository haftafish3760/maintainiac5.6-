part of 'receipt_attachment_panel.dart';

class _ReceiptAttachmentList extends StatelessWidget {
  const _ReceiptAttachmentList({
    required this.photoPaths,
    required this.documents,
    required this.dataSaverLevel,
    required this.onReviewPhotos,
    required this.onRemovePhoto,
    required this.onRemoveDocument,
    required this.onEditDocument,
    required this.onReadDocument,
  });

  final List<String> photoPaths;
  final List<ReceiptAttachmentRecord> documents;
  final ReceiptDataSaverLevel dataSaverLevel;
  final VoidCallback onReviewPhotos;
  final ValueChanged<int> onRemovePhoto;
  final ValueChanged<ReceiptAttachmentRecord> onRemoveDocument;
  final ValueChanged<ReceiptAttachmentRecord> onEditDocument;
  final ValueChanged<ReceiptAttachmentRecord> onReadDocument;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      for (var index = 0; index < photoPaths.length; index++)
        _ReceiptAttachmentRow(
          icon: Icons.photo_rounded,
          title: 'Receipt photo ${index + 1}',
          subtitle:
              '${dataSaverLevel.label} copy${_fileDetail(photoPaths[index])}',
          onTap: onReviewPhotos,
          onRemove: () => onRemovePhoto(index),
        ),
      for (final document in documents)
        _ReceiptAttachmentRow(
          icon: _iconFor(document.kind),
          title: document.label,
          subtitle: _documentDetail(document),
          onTap: () => onEditDocument(document),
          onRemove: () => onRemoveDocument(document),
          onRead: document.isPdf || document.isImportedText
              ? () => onReadDocument(document)
              : null,
        ),
    ];
    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0) const SizedBox(height: 6),
          rows[index],
        ],
      ],
    );
  }

  static IconData _iconFor(ReceiptAttachmentKind kind) {
    return switch (kind) {
      ReceiptAttachmentKind.photo => Icons.photo_rounded,
      ReceiptAttachmentKind.pdf => Icons.picture_as_pdf_rounded,
      ReceiptAttachmentKind.emailText => Icons.description_rounded,
      ReceiptAttachmentKind.textMessageText => Icons.description_rounded,
    };
  }

  static String _documentDetail(ReceiptAttachmentRecord attachment) {
    final size = _formatBytes(attachment.byteSize);
    final source = attachment.sourceLabel.trim();
    final pages = attachment.pageCount;
    final pageLabel = pages == null
        ? null
        : '$pages ${pages == 1 ? 'page' : 'pages'}';
    return switch (attachment.kind) {
      ReceiptAttachmentKind.photo => 'Receipt photo',
      ReceiptAttachmentKind.pdf => [
        attachment.proofAccessLabel,
        attachment.readState.label,
        attachment.validationStatus.label,
        attachment.pageCountStatus.label,
        if (attachment.documentSignals.contains(
          ReceiptPdfInspector.imageContentSignal,
        ))
          'Scanned/image PDF',
        if (_looksLikeNonReceiptDocument(attachment)) 'Review document type',
        if (attachment.riskFlags.isNotEmpty) 'Review PDF warnings',
        ?pageLabel,
        ?size,
        if (source.isNotEmpty) source,
      ].join(' | '),
      ReceiptAttachmentKind.emailText =>
        size == null ? 'Receipt text' : 'Receipt text | $size',
      ReceiptAttachmentKind.textMessageText =>
        size == null ? 'Receipt text' : 'Receipt text | $size',
    };
  }

  static bool _looksLikeNonReceiptDocument(ReceiptAttachmentRecord attachment) {
    final signals = attachment.documentSignals;
    if (signals.isEmpty) return false;
    final hasReceiptSignal = signals.any(
      ReceiptPdfInspector.receiptSignals.contains,
    );
    final hasNonReceiptSignal = signals.any(
      ReceiptPdfInspector.nonReceiptSignals.contains,
    );
    return hasNonReceiptSignal && !hasReceiptSignal;
  }

  static String _fileDetail(String path) {
    final size = _formatBytes(_tryFileSize(path));
    return size == null ? '' : ' | $size';
  }

  static int? _tryFileSize(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      return file.lengthSync();
    } catch (_) {
      return null;
    }
  }

  static String? _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return null;
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }
}

class _ReceiptAttachmentRow extends StatelessWidget {
  const _ReceiptAttachmentRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRemove,
    this.onTap,
    this.onRead,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onRead;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF11181B),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF445159)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFFD166), size: 22),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFC7D0D4),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_ReceiptAttachmentMenuAction>(
                tooltip: 'Receipt attachment actions',
                icon: const Icon(Icons.more_vert_rounded),
                color: const Color(0xFF1F2528),
                onSelected: (action) {
                  switch (action) {
                    case _ReceiptAttachmentMenuAction.view:
                      onTap?.call();
                    case _ReceiptAttachmentMenuAction.read:
                      onRead?.call();
                    case _ReceiptAttachmentMenuAction.remove:
                      onRemove();
                  }
                },
                itemBuilder: (context) => [
                  if (onTap != null)
                    const PopupMenuItem(
                      value: _ReceiptAttachmentMenuAction.view,
                      child: _ReceiptAttachmentMenuText('View'),
                    ),
                  if (onRead != null)
                    const PopupMenuItem(
                      value: _ReceiptAttachmentMenuAction.read,
                      child: _ReceiptAttachmentMenuText('Fill Receipt'),
                    ),
                  const PopupMenuItem(
                    value: _ReceiptAttachmentMenuAction.remove,
                    child: _ReceiptAttachmentMenuText('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ReceiptAttachmentMenuAction { view, read, remove }

class _ReceiptAttachmentMenuText extends StatelessWidget {
  const _ReceiptAttachmentMenuText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFE8ECEE),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ReceiptAttachmentSummary extends StatelessWidget {
  const _ReceiptAttachmentSummary({
    required this.photoCount,
    required this.documents,
    required this.dataSaverLevel,
    required this.onReview,
  });

  final int photoCount;
  final List<ReceiptAttachmentRecord> documents;
  final ReceiptDataSaverLevel dataSaverLevel;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final documentCount = documents.length;
    final hasPhotos = photoCount > 0;
    final labelParts = [
      if (hasPhotos) '$photoCount ${photoCount == 1 ? 'photo' : 'photos'}',
      if (documentCount > 0)
        '$documentCount imported ${documentCount == 1 ? 'receipt' : 'receipts'}',
    ];
    final label = '${labelParts.join(' + ')} attached';
    final textCount = documents
        .where((attachment) => attachment.isImportedText)
        .length;
    final pdfCount = documents.where((attachment) => attachment.isPdf).length;
    final detailParts = [
      if (hasPhotos) 'Data saver: ${dataSaverLevel.label}',
      if (pdfCount > 0) '$pdfCount PDF ${pdfCount == 1 ? 'file' : 'files'}',
      if (textCount > 0)
        '$textCount pasted ${textCount == 1 ? 'receipt' : 'receipts'}',
    ];
    final detail = detailParts.join(' | ');
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: hasPhotos ? onReview : null,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1114),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF6E7B81), width: 1.2),
          ),
          child: Row(
            children: [
              Icon(
                hasPhotos
                    ? Icons.photo_library_outlined
                    : Icons.attach_file_rounded,
                color: const Color(0xFF8FD3FF),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: Color(0xFFC7D0D4),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasPhotos)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFC7D0D4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
