part of 'receipt_attachment_panel.dart';

class _ImportedReceiptTextSheet extends StatefulWidget {
  const _ImportedReceiptTextSheet({required this.kind, this.initialAttachment});

  final ReceiptAttachmentKind kind;
  final ReceiptAttachmentRecord? initialAttachment;

  @override
  State<_ImportedReceiptTextSheet> createState() =>
      _ImportedReceiptTextSheetState();
}

class _ImportedReceiptTextSheetState extends State<_ImportedReceiptTextSheet> {
  final _labelController = TextEditingController();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAttachment;
    if (initial == null) return;
    _labelController.text = initial.displayName;
    _textController.text = initial.importedText;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottom + 12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste Receipt Text',
              style: TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Paste copied receipt text here. If the receipt is a PDF or image, attach that file instead.',
              style: TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _labelController,
              style: const TextStyle(
                color: Color(0xFF101416),
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFAAB4B9),
                labelText: 'Receipt label or store',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _textController,
              minLines: 8,
              maxLines: 14,
              style: const TextStyle(
                color: Color(0xFF101416),
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFAAB4B9),
                labelText: 'Receipt text',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pasteClipboard,
                  icon: const Icon(Icons.content_paste_rounded),
                  label: const Text('Paste Clipboard'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Use Receipt Text'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The clipboard does not contain text.')),
      );
      return;
    }
    _textController.text = text;
  }

  void _save() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste the receipt text first.')),
      );
      return;
    }
    final now = DateTime.now();
    final label = _labelController.text.trim();
    final initial = widget.initialAttachment;
    Navigator.of(context).pop(
      ReceiptAttachmentRecord(
        id: initial?.id ?? 'RCPT-${now.microsecondsSinceEpoch}',
        path: initial?.path ?? '',
        kind: widget.kind,
        dataSaverLevel:
            initial?.dataSaverLevel ?? ReceiptDataSaverLevel.balanced,
        createdAt: initial?.createdAt ?? now,
        displayName: label.isEmpty ? 'Receipt text' : label,
        importedText: text,
        byteSize: text.length,
      ),
    );
  }
}
