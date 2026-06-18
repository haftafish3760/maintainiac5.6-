import 'package:flutter/material.dart';

import '../../../shared/pdf/app_generated_pdf_models.dart';
import '../../../shared/pdf/app_generated_pdf_preview_screen.dart';

class InvoiceTemplatePreviewScreen extends StatefulWidget {
  const InvoiceTemplatePreviewScreen({
    required this.documentFuture,
    required this.title,
    super.key,
  });

  final Future<AppGeneratedPdfDocument> documentFuture;
  final String title;

  @override
  State<InvoiceTemplatePreviewScreen> createState() =>
      _InvoiceTemplatePreviewScreenState();
}

class _InvoiceTemplatePreviewScreenState
    extends State<InvoiceTemplatePreviewScreen> {
  late Future<AppGeneratedPdfDocument> _documentFuture;

  @override
  void initState() {
    super.initState();
    _documentFuture = widget.documentFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppGeneratedPdfDocument>(
      future: _documentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: const Color(0xFF050607),
            appBar: AppBar(title: Text(widget.title)),
            body: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD166),
                semanticsLabel: 'Preparing invoice template',
              ),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xFF050607),
            appBar: AppBar(title: Text(widget.title)),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Maintaniac could not prepare that invoice template.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          );
        }
        return AppGeneratedPdfPreviewScreen(document: snapshot.data!);
      },
    );
  }
}
