part of 'receipt_attachment_panel.dart';

class _ReceiptAttachmentSummary extends StatelessWidget {
  const _ReceiptAttachmentSummary({
    required this.photoCount,
    required this.documents,
    required this.dataSaverLevel,
    required this.appAssistedEnabled,
    required this.onReview,
  });

  final int photoCount;
  final List<ReceiptAttachmentRecord> documents;
  final ReceiptDataSaverLevel dataSaverLevel;
  final bool appAssistedEnabled;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final documentCount = documents.length;
    final hasPhotos = photoCount > 0;
    final labelParts = [
      if (hasPhotos)
        '$photoCount receipt ${photoCount == 1 ? 'photo' : 'photos'}',
      if (documentCount > 0)
        '$documentCount imported ${documentCount == 1 ? 'receipt' : 'receipts'}',
    ];
    final label = '${labelParts.join(' + ')} attached';
    final textCount = documents
        .where((attachment) => attachment.isImportedText)
        .length;
    final pdfCount = documents.where((attachment) => attachment.isPdf).length;
    final photoDetail = hasPhotos
        ? [
            if (photoCount > 1) 'Photos kept in receipt order',
            'Saved image size: ${dataSaverLevel.label}',
            appAssistedEnabled
                ? 'Next checks the clear photo before using the smaller image'
                : 'Receipt image only',
          ].join(' | ')
        : null;
    final detailParts = [
      ?photoDetail,
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
