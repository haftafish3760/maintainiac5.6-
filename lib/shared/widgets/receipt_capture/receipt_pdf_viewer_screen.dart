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
part 'receipt_pdf_viewer_body.dart';
part 'receipt_pdf_viewer_preview_async.dart';

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
