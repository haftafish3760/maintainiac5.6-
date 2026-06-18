import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../navigation/app_page_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/app_screen_shell.dart';
import '../widgets/industrial_panel.dart';
import '../widgets/receipt_capture/receipt_pdf_viewer_screen.dart';
import 'app_generated_pdf_models.dart';
import 'app_generated_pdf_service.dart';

class AppGeneratedPdfPreviewScreen extends StatefulWidget {
  const AppGeneratedPdfPreviewScreen({
    super.key,
    required this.document,
    this.service = const AppGeneratedPdfService(),
  });

  final AppGeneratedPdfDocument document;
  final AppGeneratedPdfService service;

  @override
  State<AppGeneratedPdfPreviewScreen> createState() =>
      _AppGeneratedPdfPreviewScreenState();
}

class _AppGeneratedPdfPreviewScreenState
    extends State<AppGeneratedPdfPreviewScreen> {
  late Future<AppGeneratedPdfFile> _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = widget.service.writeTemporary(widget.document);
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.invoices,
      body: FutureBuilder<AppGeneratedPdfFile>(
        future: _fileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Preparing PDF preview',
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _PdfGenerationError(error: snapshot.error);
          }
          final generated = snapshot.data!;
          return _GeneratedPdfReady(
            generated: generated,
            onPreview: () => _openPreview(context, generated),
            onShare: _share,
            onPrint: _print,
          );
        },
      ),
    );
  }

  void _openPreview(BuildContext context, AppGeneratedPdfFile generated) {
    Navigator.of(context).push(
      appNativeRoute(
        context,
        ReceiptPdfViewerScreen(
          path: generated.path,
          title: generated.document.title,
        ),
      ),
    );
  }

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final status = await widget.service.share(widget.document);
      if (!mounted) return;
      final message = status == ShareResultStatus.dismissed
          ? 'The share sheet was closed.'
          : 'Choose where to send or save this PDF.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on AppGeneratedPdfException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _print() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final printed = await widget.service.print(widget.document);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            printed ? 'Print flow opened.' : 'The print flow was closed.',
          ),
        ),
      );
    } on AppGeneratedPdfException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _GeneratedPdfReady extends StatelessWidget {
  const _GeneratedPdfReady({
    required this.generated,
    required this.onPreview,
    required this.onShare,
    required this.onPrint,
  });

  final AppGeneratedPdfFile generated;
  final VoidCallback onPreview;
  final VoidCallback onShare;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    final document = generated.document;
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        IndustrialPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${document.kindLabel} PDF ready. Preview is read-only; sharing, printing, and saving use your phone controls.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'File: ${document.safeFileName}\nSize: ${_formatBytes(generated.byteSize)}',
                style: const TextStyle(fontSize: 12, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _PdfActionButton(
          icon: Icons.picture_as_pdf_rounded,
          label: 'Preview PDF',
          onPressed: onPreview,
        ),
        const SizedBox(height: 8),
        _PdfActionButton(
          icon: Icons.ios_share_rounded,
          label: 'Share or Save PDF',
          onPressed: onShare,
        ),
        const SizedBox(height: 8),
        _PdfActionButton(
          icon: Icons.print_rounded,
          label: 'Print PDF',
          onPressed: onPrint,
        ),
      ],
    );
  }
}

class _PdfActionButton extends StatelessWidget {
  const _PdfActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
      ),
    );
  }
}

class _PdfGenerationError extends StatelessWidget {
  const _PdfGenerationError({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final message = error is AppGeneratedPdfException
        ? (error! as AppGeneratedPdfException).message
        : 'Maintaniac could not prepare this PDF.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).ceil()} KB';
  return '$bytes bytes';
}
