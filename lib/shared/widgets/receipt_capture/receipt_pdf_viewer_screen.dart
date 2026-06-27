import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'receipt_assistance_policy.dart';
import 'receipt_pdf_inspector.dart';
import 'receipt_pdf_limits.dart';

part 'receipt_pdf_viewer_preview_plan.dart';
part 'receipt_pdf_viewer_status.dart';
part 'receipt_pdf_viewer_header.dart';

class ReceiptPdfViewerScreen extends StatelessWidget {
  const ReceiptPdfViewerScreen({
    super.key,
    required this.path,
    required this.title,
    this.performanceProfile = ReceiptPdfPerformanceProfile.standard,
  });

  final String path;
  final String title;
  final ReceiptPdfPerformanceProfile performanceProfile;

  static const previewPageLimit = 10;
  static const longPreviewPageLimit = 5;
  static const hugePreviewPageLimit = 3;
  static const highCapacityPreviewPageLimit = 12;
  static const highCapacityLongPreviewPageLimit = 8;
  static const highCapacityHugePreviewPageLimit = 5;
  static const lowPowerPreviewPageLimit = 4;
  static const lowPowerLongPreviewPageLimit = 2;
  static const lowPowerHugePreviewPageLimit = 1;
  static const previewTimeout = Duration(seconds: 12);

  @override
  Widget build(BuildContext context) {
    final fileName = title.trim().isEmpty ? 'Receipt PDF' : title.trim();
    return Scaffold(
      backgroundColor: const Color(0xFF050607),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11181B),
        foregroundColor: const Color(0xFFE8ECEE),
        title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          _PdfProofHeader(path: path),
          Expanded(
            child: _PdfProofPages(
              path: path,
              performanceProfile: performanceProfile,
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfProofWarning extends StatelessWidget {
  const _PdfProofWarning({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReceiptPdfInspection>(
      future: ReceiptPdfInspector.inspect(path),
      builder: (context, snapshot) {
        final inspection = snapshot.data;
        final warning = inspection?.userWarning;
        if (warning == null) return const SizedBox.shrink();
        return Semantics(
          label: 'PDF proof warning. $warning',
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2210),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFD166)),
            ),
            child: Text(
              warning,
              style: const TextStyle(
                color: Color(0xFFFFE4A8),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PdfProofPreviewLimitNotice extends StatelessWidget {
  const _PdfProofPreviewLimitNotice({
    required this.totalPages,
    required this.previewedPages,
    required this.plan,
  });

  final int? totalPages;
  final int previewedPages;
  final ReceiptPdfPreviewPlan plan;

  @override
  Widget build(BuildContext context) {
    final pages = totalPages;
    if (pages == null || pages <= previewedPages) {
      return const SizedBox.shrink();
    }
    return Semantics(
      label:
          'PDF preview limit. Showing first $previewedPages pages of $pages. ${plan.reason}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Text(
          'Showing first $previewedPages pages of $pages. ${plan.reason} The original PDF proof is still saved read-only.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PdfProofPreviewPlanNotice extends StatelessWidget {
  const _PdfProofPreviewPlanNotice({required this.plan});

  final ReceiptPdfPreviewPlan plan;

  @override
  Widget build(BuildContext context) {
    if (!plan.isReduced) return const SizedBox.shrink();
    return Semantics(
      label: 'PDF preview limit. ${plan.reason}',
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF10212A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF8FD3FF)),
        ),
        child: Text(
          plan.reason,
          style: const TextStyle(
            color: Color(0xFFA9DFFF),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1.25,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _PdfProofPages extends StatefulWidget {
  const _PdfProofPages({required this.path, required this.performanceProfile});

  final String path;
  final ReceiptPdfPerformanceProfile performanceProfile;

  @override
  State<_PdfProofPages> createState() => _PdfProofPagesState();
}

class _PdfProofPagesState extends State<_PdfProofPages> {
  late Future<_PdfProofPreview> _previewFuture;

  @override
  void initState() {
    super.initState();
    _previewFuture = _preview(widget.path);
  }

  @override
  void didUpdateWidget(_PdfProofPages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.performanceProfile != widget.performanceProfile) {
      _previewFuture = _preview(widget.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PdfProofPreview>(
      future: _previewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFD166),
              semanticsLabel: 'Loading PDF proof preview',
            ),
          );
        }
        final preview = snapshot.data ?? const _PdfProofPreview();
        if (preview.status != ReceiptPdfPreviewStatus.ready) {
          return _PdfProofUnavailable(status: preview.status);
        }
        if (preview.pages.isEmpty) {
          return const _PdfProofUnavailable(
            status: ReceiptPdfPreviewStatus.noPreviewPages,
          );
        }
        return InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          boundaryMargin: const EdgeInsets.all(40),
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              _PdfProofWarning(path: widget.path),
              _PdfProofPreviewPlanNotice(plan: preview.plan),
              const SizedBox(height: 10),
              for (var index = 0; index < preview.pages.length; index++) ...[
                Semantics(
                  label: 'Read-only PDF proof page ${index + 1} preview image.',
                  image: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF445159)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                          child: Text(
                            'Page ${index + 1}',
                            style: const TextStyle(
                              color: Color(0xFF11181B),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Image.memory(preview.pages[index], fit: BoxFit.contain),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              _PdfProofPreviewLimitNotice(
                totalPages: preview.totalPages,
                previewedPages: preview.pages.length,
                plan: preview.plan,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_PdfProofPreview> _preview(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return const _PdfProofPreview(status: ReceiptPdfPreviewStatus.missing);
    }
    late final ReceiptPdfInspection inspection;
    try {
      inspection = await ReceiptPdfInspector.inspect(path);
    } catch (_) {
      return const _PdfProofPreview(status: ReceiptPdfPreviewStatus.unreadable);
    }
    final preflightStatus = receiptPdfPreviewStatusForInspection(inspection);
    if (preflightStatus != ReceiptPdfPreviewStatus.ready) {
      return _PdfProofPreview(status: preflightStatus);
    }
    try {
      if (await file.length() > ReceiptPdfLimits.localAssistedReadBytes) {
        return const _PdfProofPreview(
          status: ReceiptPdfPreviewStatus.tooLargeForPreview,
        );
      }
    } catch (_) {
      return const _PdfProofPreview(status: ReceiptPdfPreviewStatus.unreadable);
    }
    late final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      return const _PdfProofPreview(status: ReceiptPdfPreviewStatus.unreadable);
    }
    final totalPages = ReceiptPdfInspector.estimatePageCount(bytes);
    final previewPlan = ReceiptPdfPreviewPlan.fromInspection(
      inspection,
      performanceProfile: widget.performanceProfile,
    );
    final pageImages = <Uint8List>[];
    var pageIndex = 0;
    try {
      await for (final page in Printing.raster(
        bytes,
        dpi: previewPlan.dpi,
      ).timeout(ReceiptPdfViewerScreen.previewTimeout)) {
        if (pageIndex >= previewPlan.pageLimit) break;
        pageImages.add(await page.toPng());
        pageIndex += 1;
      }
    } catch (_) {
      return const _PdfProofPreview(
        status: ReceiptPdfPreviewStatus.renderFailed,
      );
    }
    return _PdfProofPreview(
      pages: pageImages,
      totalPages: totalPages,
      plan: previewPlan,
    );
  }
}

class _PdfProofPreview {
  const _PdfProofPreview({
    this.pages = const [],
    this.totalPages,
    this.plan = const ReceiptPdfPreviewPlan.normal(),
    this.status = ReceiptPdfPreviewStatus.ready,
  });

  final List<Uint8List> pages;
  final int? totalPages;
  final ReceiptPdfPreviewPlan plan;
  final ReceiptPdfPreviewStatus status;
}

@visibleForTesting
int receiptPdfPreviewPageLimit(int? totalPages) {
  return receiptPdfPreviewPlanForPageCount(totalPages).pageLimit;
}
