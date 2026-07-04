import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../navigation/app_page_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/app_screen_shell.dart';
import '../widgets/industrial_panel.dart';
import '../widgets/receipt_capture/receipt_pdf_viewer_screen.dart';
import 'app_generated_pdf_models.dart';
import 'app_generated_pdf_service.dart';

enum AppGeneratedPdfPreviewAction {
  prepared,
  preparationFailed,
  previewOpened,
  shareCompleted,
  shareDismissed,
  shareFailed,
  printOpened,
  printDismissed,
  printFailed,
}

class AppGeneratedPdfPreviewActionEvent {
  const AppGeneratedPdfPreviewActionEvent({
    required this.action,
    this.reasonCode = '',
  });

  final AppGeneratedPdfPreviewAction action;
  final String reasonCode;

  bool get isFailure =>
      action == AppGeneratedPdfPreviewAction.preparationFailed ||
      action == AppGeneratedPdfPreviewAction.shareFailed ||
      action == AppGeneratedPdfPreviewAction.printFailed;
}

class AppGeneratedPdfPreviewScreen extends StatefulWidget {
  const AppGeneratedPdfPreviewScreen({
    super.key,
    required this.document,
    this.service = const AppGeneratedPdfService(),
    this.onAction,
  });

  final AppGeneratedPdfDocument document;
  final AppGeneratedPdfService service;
  final ValueChanged<AppGeneratedPdfPreviewActionEvent>? onAction;

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
    _fileFuture = _prepare();
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
            return _PdfGenerationError(error: snapshot.error, onRetry: _retry);
          }
          final generated = snapshot.data!;
          return _GeneratedPdfReady(
            generated: generated,
            onPreview: () => _openPreview(context, generated),
            onShare: () => _share(generated),
            onPrint: _print,
          );
        },
      ),
    );
  }

  void _openPreview(BuildContext context, AppGeneratedPdfFile generated) {
    _notify(
      const AppGeneratedPdfPreviewActionEvent(
        action: AppGeneratedPdfPreviewAction.previewOpened,
      ),
    );
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

  void _retry() {
    setState(() {
      _fileFuture = _prepare();
    });
  }

  Future<AppGeneratedPdfFile> _prepare() async {
    try {
      final generated = await widget.service.writeTemporary(widget.document);
      _notify(
        const AppGeneratedPdfPreviewActionEvent(
          action: AppGeneratedPdfPreviewAction.prepared,
        ),
      );
      return generated;
    } on AppGeneratedPdfException {
      _notify(
        const AppGeneratedPdfPreviewActionEvent(
          action: AppGeneratedPdfPreviewAction.preparationFailed,
          reasonCode: 'prepare_pdf_validation_failed',
        ),
      );
      rethrow;
    } catch (_) {
      _notify(
        const AppGeneratedPdfPreviewActionEvent(
          action: AppGeneratedPdfPreviewAction.preparationFailed,
          reasonCode: 'prepare_platform_failed',
        ),
      );
      rethrow;
    }
  }

  Future<void> _share(AppGeneratedPdfFile generated) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final status = await widget.service.shareGeneratedFile(generated);
      if (!mounted) return;
      final message = status == ShareResultStatus.dismissed
          ? 'The share sheet was closed.'
          : 'Choose where to send or save this PDF.';
      _notify(
        AppGeneratedPdfPreviewActionEvent(
          action: status == ShareResultStatus.dismissed
              ? AppGeneratedPdfPreviewAction.shareDismissed
              : AppGeneratedPdfPreviewAction.shareCompleted,
        ),
      );
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on AppGeneratedPdfException catch (error) {
      if (!mounted) return;
      _notify(
        const AppGeneratedPdfPreviewActionEvent(
          action: AppGeneratedPdfPreviewAction.shareFailed,
          reasonCode: 'share_pdf_validation_failed',
        ),
      );
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      _notify(
        const AppGeneratedPdfPreviewActionEvent(
          action: AppGeneratedPdfPreviewAction.shareFailed,
          reasonCode: 'share_platform_failed',
        ),
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Maintainiac could not open sharing for this PDF. Try again or save it from the preview.',
          ),
        ),
      );
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
      _notify(
        AppGeneratedPdfPreviewActionEvent(
          action: printed
              ? AppGeneratedPdfPreviewAction.printOpened
              : AppGeneratedPdfPreviewAction.printDismissed,
        ),
      );
    } on AppGeneratedPdfException catch (error) {
      if (!mounted) return;
      _notify(
        const AppGeneratedPdfPreviewActionEvent(
          action: AppGeneratedPdfPreviewAction.printFailed,
          reasonCode: 'print_pdf_validation_failed',
        ),
      );
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      _notify(
        const AppGeneratedPdfPreviewActionEvent(
          action: AppGeneratedPdfPreviewAction.printFailed,
          reasonCode: 'print_platform_failed',
        ),
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Maintainiac could not open printing for this PDF. Try again or share the PDF instead.',
          ),
        ),
      );
    }
  }

  void _notify(AppGeneratedPdfPreviewActionEvent event) {
    widget.onAction?.call(event);
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
  const _PdfGenerationError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is AppGeneratedPdfException
        ? (error! as AppGeneratedPdfException).message
        : 'Maintainiac could not prepare this PDF.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.picture_as_pdf_rounded,
              color: Color(0xFFFFD166),
              size: 38,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
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
