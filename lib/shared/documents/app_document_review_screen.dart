import 'dart:async';

import 'package:flutter/material.dart';

import '../navigation/app_page_routes.dart';
import '../widgets/app_screen_shell.dart';
import '../widgets/receipt_capture/receipt_capture_models.dart';
import '../widgets/receipt_capture/receipt_pdf_viewer_screen.dart';
import '../widgets/receipt_capture/receipt_proof_storage.dart';
import 'app_document_import_service.dart';
import 'app_document_models.dart';
import 'app_document_store.dart';

class AppDocumentReviewScreen extends StatefulWidget {
  const AppDocumentReviewScreen({
    super.key,
    required this.kind,
    required this.attachments,
    this.importedText = '',
    this.store,
  });

  final AppDocumentKind kind;
  final List<ReceiptAttachmentRecord> attachments;
  final String importedText;
  final AppDocumentStore? store;

  @override
  State<AppDocumentReviewScreen> createState() =>
      _AppDocumentReviewScreenState();
}

class _AppDocumentReviewScreenState extends State<AppDocumentReviewScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  var _saved = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.attachments.isEmpty
        ? widget.kind.label
        : widget.attachments.first.label;
  }

  @override
  void dispose() {
    if (!_saved) {
      unawaited(
        ReceiptProofStorage.instance.deleteStagedAttachments(
          widget.attachments,
        ),
      );
    }
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: _sectionForDocumentKind(widget.kind),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          _DocumentReviewHeader(kind: widget.kind),
          const SizedBox(height: 10),
          _DocumentReviewFields(
            titleController: _titleController,
            notesController: _notesController,
          ),
          const SizedBox(height: 10),
          _DocumentProofList(
            attachments: widget.attachments,
            importedText: widget.importedText,
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _saving ? null : _saveDocument,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(
              _saving ? 'Saving Document' : 'Save Read-Only Document',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDocument() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await AppDocumentImportService(store: widget.store).saveReadOnlyDocument(
        kind: widget.kind,
        attachments: widget.attachments,
        title: _titleController.text,
        importedText: widget.importedText,
        notes: _notesController.text,
      );
      _saved = true;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${widget.kind.label} saved.')));
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That document could not be saved.')),
      );
    }
  }
}

class _DocumentReviewHeader extends StatelessWidget {
  const _DocumentReviewHeader({required this.kind});

  final AppDocumentKind kind;

  @override
  Widget build(BuildContext context) {
    return _DocumentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  kind.label,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Save this file as read-only proof. Maintainiac can view the PDF, but it will not edit or alter the original proof copy.',
            style: TextStyle(fontWeight: FontWeight.w700, height: 1.25),
          ),
        ],
      ),
    );
  }
}

class _DocumentReviewFields extends StatelessWidget {
  const _DocumentReviewFields({
    required this.titleController,
    required this.notesController,
  });

  final TextEditingController titleController;
  final TextEditingController notesController;

  @override
  Widget build(BuildContext context) {
    return _DocumentPanel(
      child: Column(
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Document name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: notesController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
        ],
      ),
    );
  }
}

class _DocumentProofList extends StatelessWidget {
  const _DocumentProofList({
    required this.attachments,
    required this.importedText,
  });

  final List<ReceiptAttachmentRecord> attachments;
  final String importedText;

  @override
  Widget build(BuildContext context) {
    return _DocumentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Proof files',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (attachments.isEmpty && importedText.trim().isEmpty)
            const Text('No proof attached yet.'),
          for (final attachment in attachments)
            _DocumentProofTile(attachment: attachment),
          if (importedText.trim().isNotEmpty)
            const ListTile(
              leading: Icon(Icons.text_snippet_rounded),
              title: Text('Shared text'),
              subtitle: Text('Saved with this document record.'),
            ),
        ],
      ),
    );
  }
}

class _DocumentProofTile extends StatelessWidget {
  const _DocumentProofTile({required this.attachment});

  final ReceiptAttachmentRecord attachment;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        attachment.isPdf
            ? Icons.picture_as_pdf_rounded
            : Icons.insert_drive_file_rounded,
      ),
      title: Text(attachment.label),
      subtitle: Text(attachment.proofAccessLabel),
      trailing: attachment.isPdf
          ? const Icon(Icons.chevron_right_rounded)
          : null,
      onTap: attachment.isPdf
          ? () => Navigator.of(context).push<void>(
              appNativeRoute(
                context,
                ReceiptPdfViewerScreen(
                  path: attachment.path,
                  title: attachment.label,
                ),
              ),
            )
          : null,
    );
  }
}

class _DocumentPanel extends StatelessWidget {
  const _DocumentPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2528),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4E5B61)),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

AppSection _sectionForDocumentKind(AppDocumentKind kind) {
  return switch (kind) {
    AppDocumentKind.invoiceDocument => AppSection.invoices,
    AppDocumentKind.jobContractorDocument => AppSection.materials,
    AppDocumentKind.maintenanceRecord => AppSection.maintenance,
    AppDocumentKind.otherDocument => AppSection.expenses,
  };
}
