import '../../../shared/pdf/app_generated_pdf_models.dart';
import '../../../shared/pdf/app_generated_pdf_export_verifier.dart';
import '../../../shared/pdf/app_generated_pdf_share_content.dart';
import 'invoice_ledger_models.dart';
import 'invoice_pdf_template_renderer.dart';
import 'invoice_record.dart';
import 'invoice_template_catalog.dart';

class InvoicePdfPreviewFactory {
  const InvoicePdfPreviewFactory({
    this.renderer = const InvoicePdfTemplateRenderer(),
  });

  final InvoicePdfTemplateRenderer renderer;

  Future<AppGeneratedPdfDocument> buildInvoicePreview() async {
    final createdAt = DateTime.now();
    final template = InvoiceTemplateCatalog.byId('structured-logo');
    final bytes = await renderer.buildDocumentBytes(
      createdAt: createdAt,
      title: 'Invoice',
      documentNumber: 'INV-2409',
      totalLabel: r'$937.74',
      template: template,
    );
    AppGeneratedPdfExportVerification.inspect(bytes).throwIfInvalid();
    final share = AppGeneratedPdfShareContent.invoicePreview();
    return AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Time & Materials Invoice Preview',
      fileName: 'maintainiac_invoice_preview.pdf',
      bytes: bytes,
      createdAt: createdAt,
      sourceModule: 'invoices',
      shareSubject: share.subject,
      shareText: share.text,
    );
  }

  Future<AppGeneratedPdfDocument> buildRecordPreview({
    required InvoiceRecord record,
  }) async {
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final bytes = await renderer.buildRecordDocumentBytes(
      record: record,
      template: template,
    );
    AppGeneratedPdfExportVerification.inspect(
      bytes,
      expectedPageCount: invoicePdfPageCountForRecord(record),
    ).throwIfInvalid();
    final title = record.documentType == InvoiceDocumentType.estimate
        ? 'Estimate ${record.invoiceNumber}'
        : 'Invoice ${record.invoiceNumber}';
    final prefix = record.documentType == InvoiceDocumentType.estimate
        ? 'estimate'
        : 'invoice';
    final share = AppGeneratedPdfShareContent.invoiceRecord(
      isEstimate: record.documentType == InvoiceDocumentType.estimate,
      documentNumber: record.invoiceNumber,
    );
    return AppGeneratedPdfDocument(
      kind: record.documentType == InvoiceDocumentType.estimate
          ? AppGeneratedPdfKind.estimate
          : AppGeneratedPdfKind.invoice,
      title: title,
      fileName: 'maintainiac_${prefix}_${record.invoiceNumber}.pdf',
      bytes: bytes,
      createdAt: record.meta.updatedAt,
      sourceModule: 'invoices',
      sourceRecordId: record.id,
      shareSubject: share.subject,
      shareText: share.text,
    );
  }

  Future<AppGeneratedPdfDocument> buildEstimatePreview() async {
    final createdAt = DateTime.now();
    final template = InvoiceTemplateCatalog.byId('structured-logo');
    final bytes = await renderer.buildDocumentBytes(
      createdAt: createdAt,
      title: 'Estimate',
      documentNumber: 'EST-2409',
      totalLabel: r'$937.74',
      template: template,
    );
    AppGeneratedPdfExportVerification.inspect(bytes).throwIfInvalid();
    final share = AppGeneratedPdfShareContent.estimatePreview();
    return AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.estimate,
      title: 'Time & Materials Estimate Preview',
      fileName: 'maintainiac_estimate_preview.pdf',
      bytes: bytes,
      createdAt: createdAt,
      sourceModule: 'invoices',
      shareSubject: share.subject,
      shareText: share.text,
    );
  }

  Future<AppGeneratedPdfDocument> buildTemplateSamplePreview({
    required InvoiceTemplateDefinition template,
  }) async {
    final createdAt = DateTime(2026, 6, 15, 10, 30);
    final bytes = await renderer.buildDocumentBytes(
      createdAt: createdAt,
      title: 'Invoice',
      documentNumber: 'INV-1017',
      totalLabel: r'$1,247.62',
      template: template,
    );
    AppGeneratedPdfExportVerification.inspect(bytes).throwIfInvalid();
    final share = AppGeneratedPdfShareContent.templateSample();
    return AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: '${template.name} Sample Invoice',
      fileName: 'maintainiac_${template.id}_sample.pdf',
      bytes: bytes,
      createdAt: createdAt,
      sourceModule: 'invoices',
      shareSubject: share.subject,
      shareText: share.text,
    );
  }
}
