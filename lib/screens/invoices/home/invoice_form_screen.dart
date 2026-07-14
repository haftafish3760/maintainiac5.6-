import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/pdf/app_generated_pdf_models.dart';
import '../../../shared/pdf/app_generated_pdf_preview_screen.dart';
import '../../../shared/pdf/app_generated_pdf_service.dart';
import '../../../shared/signatures/app_signature_models.dart';
import '../../../shared/signatures/app_signature_store.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../../shared/widgets/industrial_panel_surface.dart';
import '../data/invoice_ledger_models.dart';
import '../data/invoice_ledger_store.dart';
import '../data/invoice_pdf_preview_factory.dart';
import '../data/invoice_record.dart';
import '../data/invoice_template_catalog.dart';
import 'invoice_form_details.dart';
import 'invoice_info_screens.dart';
import 'invoice_template_screen.dart';

class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({
    this.documentType = InvoiceDocumentType.invoice,
    this.recordId,
    this.pdfPreviewFactory = const InvoicePdfPreviewFactory(),
    this.pdfPreviewService = const AppGeneratedPdfService(),
    super.key,
  });

  final InvoiceDocumentType documentType;
  final String? recordId;
  final InvoicePdfPreviewFactory pdfPreviewFactory;
  final AppGeneratedPdfService pdfPreviewService;

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  InvoiceLedgerStore? _ledger;
  InvoiceRecord? _record;
  var _creatingDraft = false;
  var _paymentMethod = 'Cash';
  var _status = 'Unpaid';
  AppSignatureResult? _ownerSignature;
  AppSignatureResult? _customerSignature;
  AppSignatureStore? _signatureStore;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = AppSignatureStoreScope.maybeOf(context);
    if (!identical(store, _signatureStore)) {
      _signatureStore = store;
      final savedOwnerSignature = store?.ownerSignature;
      if (_ownerSignature == null && savedOwnerSignature?.hasInk == true) {
        _ownerSignature = savedOwnerSignature;
      }
    }
    _ledger ??=
        InvoiceLedgerScope.maybeOf(context) ??
        InvoiceLedgerStore.memory(canPersist: false);
    _scheduleEnsureDraft();
  }

  void _scheduleEnsureDraft() {
    if (_creatingDraft || _record != null) return;
    _creatingDraft = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_ensureDraft());
    });
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    final isEstimate = widget.documentType == InvoiceDocumentType.estimate;
    return AppScreenShell(
      section: AppSection.invoices,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
        children: [
          const AppBackButton(),
          const SizedBox(height: 8),
          AppScreenHeader(title: isEstimate ? 'Estimate' : 'Invoice'),
          const SizedBox(height: 8),
          if (_creatingDraft || record == null) ...[
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 8),
          ],
          _InvoiceActionTile(
            title: 'Invoice Information',
            detail: record == null
                ? 'Creating local draft'
                : _invoiceInfoDetail(record),
            icon: Icons.description_rounded,
            onTap: record == null
                ? () {}
                : () async {
                    final updated = await Navigator.of(context)
                        .push<InvoiceRecord>(
                          appNativeRoute<InvoiceRecord>(
                            context,
                            InvoiceInformationScreen(record: record),
                          ),
                        );
                    if (updated != null) await _saveRecord(updated);
                  },
          ),
          _InvoiceActionTile(
            title: 'Select A Template',
            detail: record == null
                ? 'Choose design'
                : _templateName(record.templateId),
            icon: Icons.dashboard_customize_rounded,
            onTap: record == null
                ? () {}
                : () async {
                    final templateId = await Navigator.of(context).push<String>(
                      appNativeRoute<String>(
                        context,
                        InvoiceTemplateScreen(
                          selectionMode: true,
                          selectedTemplateId: record.templateId,
                        ),
                      ),
                    );
                    if (templateId != null) {
                      await _saveRecord(
                        record.copyWith(templateId: templateId),
                      );
                    }
                  },
          ),
          _InvoiceActionTile(
            title: 'Company Information',
            detail: record == null
                ? 'Add company information'
                : _partyInfoDetail(
                    record.company,
                    fallback: 'Add company information',
                  ),
            icon: Icons.business_rounded,
            onTap: record == null
                ? () {}
                : () async {
                    final company = await Navigator.of(context)
                        .push<InvoicePartySnapshot>(
                          appNativeRoute<InvoicePartySnapshot>(
                            context,
                            InvoiceCompanyInfoScreen(initial: record.company),
                          ),
                        );
                    if (company != null) {
                      await _saveRecord(record.copyWith(company: company));
                    }
                  },
          ),
          _InvoiceActionTile(
            title: 'Client Information',
            detail: record == null
                ? 'Add client information'
                : _partyInfoDetail(
                    record.client,
                    fallback: 'Add client information',
                  ),
            icon: Icons.group_rounded,
            onTap: record == null
                ? () {}
                : () async {
                    final client = await Navigator.of(context)
                        .push<InvoicePartySnapshot>(
                          appNativeRoute<InvoicePartySnapshot>(
                            context,
                            InvoiceClientInfoScreen(initial: record.client),
                          ),
                        );
                    if (client != null) {
                      await _saveRecord(record.copyWith(client: client));
                    }
                  },
          ),
          _InvoiceActionTile(
            title: 'Items',
            detail: record == null
                ? 'Add items'
                : '${record.lines.length} ${record.lines.length == 1 ? 'item' : 'items'} • ${_money(record.subtotal)}',
            icon: Icons.inventory_2_rounded,
            onTap: record == null
                ? () {}
                : () async {
                    final updated = await Navigator.of(context)
                        .push<InvoiceRecord>(
                          appNativeRoute<InvoiceRecord>(
                            context,
                            InvoiceItemsScreen(record: record),
                          ),
                        );
                    if (updated != null) await _saveRecord(updated);
                  },
          ),
          _InvoiceActionTile(
            title: 'Subtotal',
            detail: record == null ? r'$0.00' : _money(record.subtotal),
            icon: Icons.receipt_rounded,
            onTap: () => showInvoiceTotalsSheet(context),
          ),
          _InvoiceActionTile(
            title: 'Discount',
            detail: r'$0.00 (0%)',
            icon: Icons.percent_rounded,
            onTap: () => showInvoiceDiscountSheet(context),
          ),
          _InvoiceActionTile(
            title: 'Tax',
            detail: record == null ? r'$0.00' : _money(record.taxTotal),
            icon: Icons.request_quote_rounded,
            onTap: () => showInvoiceTaxSheet(context),
          ),
          _InvoiceActionTile(
            title: 'Total',
            detail: record == null ? r'$0.00' : _money(record.balanceDue),
            icon: Icons.summarize_rounded,
            onTap: () => showInvoiceTotalsSheet(context),
          ),
          _InvoiceActionTile(
            title: 'Payment Method',
            detail: _paymentMethod,
            icon: Icons.payments_rounded,
            onTap: () async {
              final selected = await showInvoicePaymentMethodSheet(
                context,
                _paymentMethod,
              );
              if (selected != null) {
                setState(() => _paymentMethod = selected);
              }
            },
          ),
          _InvoiceActionTile(
            title: 'Signature',
            detail: _signatureDetail,
            icon: Icons.draw_rounded,
            onTap: _captureSignature,
          ),
          _InvoiceActionTile(
            title: 'Terms And Conditions',
            detail: 'Payment due terms',
            icon: Icons.rule_rounded,
            onTap: () => showInvoiceTermsSheet(context),
          ),
          _InvoiceActionTile(
            title: 'Mark As',
            detail: _status,
            icon: Icons.fact_check_rounded,
            onTap: () async {
              final selected = await showInvoiceStatusSheet(context, _status);
              if (selected != null) setState(() => _status = selected);
            },
          ),
          const SizedBox(height: 8),
          _InvoiceFooterActions(
            onSaveDraft: _saveCurrentDraft,
            onPreview: _previewInvoice,
            onChangeTemplate: () => Navigator.of(context).push(
              appNativeRoute<void>(context, const InvoiceTemplateScreen()),
            ),
            onSaveInvoice: () async {
              final navigator = Navigator.of(context);
              final saved = await _saveFinalDocument();
              if (!saved) return;
              if (mounted) navigator.pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _ensureDraft() async {
    if (_record != null) return;
    final ledger = _ledger;
    if (ledger == null) {
      _creatingDraft = false;
      return;
    }
    final existingId = widget.recordId;
    final existing = existingId == null ? null : ledger.recordById(existingId);
    final draft =
        existing ??
        await ledger.createDraft(
          type: widget.documentType,
          now: DateTime.now(),
        );
    if (!mounted) return;
    setState(() {
      _record = draft;
      _restoreDocumentSignatures(draft);
      _paymentMethod = draft.paymentMethod.trim().isEmpty
          ? _paymentMethod
          : draft.paymentMethod;
      _status = _statusLabel(draft.status);
      _creatingDraft = false;
    });
  }

  Future<void> _saveRecord(InvoiceRecord record) async {
    final saved = await _ledger!.saveRecord(record);
    if (!mounted) return;
    setState(() {
      _record = saved;
      _restoreDocumentSignatures(saved);
    });
  }

  void _restoreDocumentSignatures(InvoiceRecord record) {
    if (record.ownerSignature.hasInk) {
      _ownerSignature = record.ownerSignature.signature;
    }
    _customerSignature = record.customerSignature.hasInk
        ? record.customerSignature.signature
        : null;
  }

  Future<void> _saveCurrentDraft() async {
    final record = _record;
    if (record == null) return;
    await _saveRecord(
      record.copyWith(
        paymentMethod: _paymentMethod,
        status: _statusFromLabel(_status),
      ),
    );
    _showMessage(
      record.isEstimate
          ? 'Estimate draft saved locally.'
          : 'Invoice draft saved locally.',
    );
  }

  Future<bool> _saveFinalDocument() async {
    final record = _record;
    if (record == null) {
      _showMessage('The draft is still being created.');
      return false;
    }
    try {
      final saved = await _ledger!.saveRecord(
        record.copyWith(
          paymentMethod: _paymentMethod,
          status: _statusFromLabel(_status),
        ),
      );
      if (!mounted) return false;
      setState(() => _record = saved);
      final document = await widget.pdfPreviewFactory.buildRecordPreview(
        record: saved,
      );
      final generatedRecord = await _ledger!.saveRecord(
        saved.recordPdfGenerated(
          document,
          fileHashSha256: document.contentHashSha256,
        ),
      );
      if (!mounted) return false;
      setState(() => _record = generatedRecord);
      _showMessage(
        generatedRecord.isEstimate
            ? 'Estimate saved. The PDF will be created when you preview or send it.'
            : 'Invoice saved. The PDF will be created when you preview or send it.',
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      await _recordPdfFailure(
        record: _record ?? record,
        reasonCode: 'finalize_pdf_metadata_failed',
      );
      _showMessage(
        'The invoice was saved, but its PDF metadata could not be recorded.',
      );
      return false;
    }
  }

  Future<void> _previewInvoice() async {
    final record = _record;
    if (record == null) {
      _showMessage('The draft is still being created.');
      return;
    }
    final saved = await _ledger!.saveRecord(
      record.copyWith(
        paymentMethod: _paymentMethod,
        status: _statusFromLabel(_status),
      ),
    );
    if (!mounted) return;
    setState(() => _record = saved);
    try {
      final document = await widget.pdfPreviewFactory.buildRecordPreview(
        record: saved,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        appNativeRoute(
          context,
          AppGeneratedPdfPreviewScreen(
            document: document,
            service: widget.pdfPreviewService,
            onAction: (event) {
              unawaited(_recordPdfPreviewAction(document, event));
            },
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      await _recordPdfFailure(
        record: _record ?? saved,
        reasonCode: 'preview_unknown_failure',
      );
      _showMessage('That invoice PDF could not be prepared.');
    }
  }

  Future<void> _recordPdfPreviewAction(
    AppGeneratedPdfDocument document,
    AppGeneratedPdfPreviewActionEvent event,
  ) async {
    final record = _record;
    if (record == null) return;
    final updated = switch (event.action) {
      AppGeneratedPdfPreviewAction.prepared => record.recordPdfGenerated(
        document,
      ),
      AppGeneratedPdfPreviewAction.preparationFailed =>
        record.recordPdfDeliveryFailed(
          reasonCode: event.reasonCode.isEmpty
              ? 'preview_prepare_failed'
              : event.reasonCode,
          pdfKind: document.kind.name,
          fileName: document.safeFileName,
        ),
      AppGeneratedPdfPreviewAction.previewOpened => record.recordPdfPreviewed(
        document,
      ),
      AppGeneratedPdfPreviewAction.shareCompleted => record.recordPdfShared(
        pdfKind: document.kind.name,
        fileName: document.safeFileName,
        byteSize: document.byteSize,
        fileHashSha256: document.contentHashSha256,
        documentRevisionHashSha256: document.documentRevisionHashSha256,
        signatureState: document.signatureState.name,
      ),
      AppGeneratedPdfPreviewAction.shareDismissed =>
        record.recordPdfDeliveryCancelled(
          reasonCode: 'share_sheet_dismissed',
          pdfKind: document.kind.name,
          fileName: document.safeFileName,
          byteSize: document.byteSize,
          fileHashSha256: document.contentHashSha256,
          documentRevisionHashSha256: document.documentRevisionHashSha256,
          signatureState: document.signatureState.name,
        ),
      AppGeneratedPdfPreviewAction.shareFailed =>
        record.recordPdfDeliveryFailed(
          reasonCode: event.reasonCode.isEmpty
              ? 'preview_share_failed'
              : event.reasonCode,
          pdfKind: document.kind.name,
          fileName: document.safeFileName,
        ),
      AppGeneratedPdfPreviewAction.printOpened => record.recordPdfPrinted(
        pdfKind: document.kind.name,
        fileName: document.safeFileName,
        byteSize: document.byteSize,
        fileHashSha256: document.contentHashSha256,
        documentRevisionHashSha256: document.documentRevisionHashSha256,
        signatureState: document.signatureState.name,
      ),
      AppGeneratedPdfPreviewAction.printDismissed =>
        record.recordPdfDeliveryCancelled(
          reasonCode: 'print_flow_dismissed',
          pdfKind: document.kind.name,
          fileName: document.safeFileName,
          byteSize: document.byteSize,
          fileHashSha256: document.contentHashSha256,
          documentRevisionHashSha256: document.documentRevisionHashSha256,
          signatureState: document.signatureState.name,
        ),
      AppGeneratedPdfPreviewAction.printFailed =>
        record.recordPdfDeliveryFailed(
          reasonCode: event.reasonCode.isEmpty
              ? 'preview_print_failed'
              : event.reasonCode,
          pdfKind: document.kind.name,
          fileName: document.safeFileName,
        ),
    };
    final saved = await _ledger!.saveRecord(updated);
    if (mounted) setState(() => _record = saved);
  }

  Future<void> _recordPdfFailure({
    required InvoiceRecord record,
    required String reasonCode,
  }) async {
    final failed = await _ledger!.saveRecord(
      record.recordPdfDeliveryFailed(reasonCode: reasonCode),
    );
    if (mounted) setState(() => _record = failed);
  }

  String get _signatureDetail {
    final owner = _ownerSignature?.hasInk ?? false;
    final customer = _customerSignature?.hasInk ?? false;
    if (owner && customer) return 'My signature and customer signature saved';
    if (owner) return 'My signature saved';
    if (customer) return 'Customer signature saved';
    return 'Add my signature or customer signature';
  }

  Future<void> _captureSignature() async {
    final result = await showInvoiceSignatureSheet(
      context,
      savedOwnerSignature: _signatureStore?.ownerSignature,
    );
    if (!mounted || result == null || !result.hasInk) return;
    var savedOwnerGlobally = false;
    if (result.role == AppSignatureRole.owner) {
      await _signatureStore?.saveOwnerSignature(result);
      savedOwnerGlobally = _signatureStore?.canPersistOwnerSignature == true;
      if (!mounted) return;
    }
    setState(() {
      if (result.role == AppSignatureRole.owner) {
        _ownerSignature = result;
      } else {
        _customerSignature = result;
      }
    });
    final record = _record;
    if (record != null) {
      final signature = InvoiceSignatureSnapshot(
        role: result.role.name,
        signedAt: result.signedAt,
        signatureHashSha256: result.role == AppSignatureRole.customer
            ? record.documentRevisionHashSha256
            : '',
        signature: result,
      );
      await _saveRecord(
        result.role == AppSignatureRole.owner
            ? record.copyWith(ownerSignature: signature)
            : record.copyWith(customerSignature: signature),
      );
    }
    _showMessage(switch (result.role) {
      AppSignatureRole.owner when savedOwnerGlobally =>
        'My signature saved locally.',
      AppSignatureRole.owner => 'My signature was added to this invoice.',
      AppSignatureRole.customer => 'Customer signature saved.',
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

String _invoiceInfoDetail(InvoiceRecord record) {
  final due = record.dueDate == null
      ? ''
      : ' • Due ${_shortDate(record.dueDate!)}';
  return '${record.invoiceNumber} • Date ${_shortDate(record.issueDate)}$due';
}

String _shortDate(DateTime day) => '${day.month}/${day.day}/${day.year}';

String _partyInfoDetail(
  InvoicePartySnapshot party, {
  required String fallback,
}) {
  final name = party.bestName;
  if (name.isEmpty) return fallback;
  final logo = party.logoPath.trim().isEmpty ? '' : ' • Logo attached';
  return '$name$logo';
}

String _money(num value) => '\$${value.toStringAsFixed(2)}';

String _templateName(String templateId) {
  return InvoiceTemplateCatalog.byId(templateId).name;
}

String _statusLabel(InvoiceRecordStatus status) {
  return switch (status) {
    InvoiceRecordStatus.paid => 'Paid',
    InvoiceRecordStatus.partlyPaid => 'Partly Paid',
    _ => 'Unpaid',
  };
}

InvoiceRecordStatus _statusFromLabel(String label) {
  return switch (label) {
    'Paid' => InvoiceRecordStatus.paid,
    'Partly Paid' => InvoiceRecordStatus.partlyPaid,
    _ => InvoiceRecordStatus.unpaid,
  };
}

class _InvoiceActionTile extends StatelessWidget {
  const _InvoiceActionTile({
    required this.title,
    required this.detail,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: IndustrialPanelSurface(
        dark: true,
        padding: EdgeInsets.zero,
        child: ListTile(
          minTileHeight: 68,
          leading: Icon(icon, color: const Color(0xFFFFD166), size: 25),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE2E8EA),
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFCAD2D5),
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _InvoiceFooterActions extends StatelessWidget {
  const _InvoiceFooterActions({
    required this.onSaveDraft,
    required this.onPreview,
    required this.onChangeTemplate,
    required this.onSaveInvoice,
  });

  final VoidCallback onSaveDraft;
  final VoidCallback onPreview;
  final VoidCallback onChangeTemplate;
  final VoidCallback onSaveInvoice;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(10),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 3.15,
        children: [
          OutlinedButton(
            onPressed: onSaveDraft,
            child: const Text('Save Draft'),
          ),
          OutlinedButton(onPressed: onPreview, child: const Text('Preview')),
          OutlinedButton(
            onPressed: onChangeTemplate,
            child: const Text('Change Template'),
          ),
          FilledButton(
            onPressed: onSaveInvoice,
            child: const Text('Save Invoice'),
          ),
        ],
      ),
    );
  }
}
