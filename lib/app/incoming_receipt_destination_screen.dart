import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/expenses/categories/expense_categories.dart';
import '../screens/expenses/data/expense_receipt_classifier.dart';
import '../screens/expenses/entry/expense_receipt_entry_screen.dart';
import '../shared/navigation/app_page_routes.dart';
import '../shared/documents/app_document_models.dart';
import '../shared/documents/app_document_review_screen.dart';
import '../shared/widgets/app_back_button.dart';
import '../shared/widgets/receipt_capture/receipt_capture_models.dart';
import '../shared/widgets/receipt_capture/receipt_proof_storage.dart';

part 'incoming_receipt_destination_sheets.dart';
part 'incoming_receipt_destination_widgets.dart';

class IncomingReceiptDestinationScreen extends StatefulWidget {
  const IncomingReceiptDestinationScreen({
    super.key,
    required this.attachments,
    required this.importedText,
    this.messages = const [],
  });

  final List<ReceiptAttachmentRecord> attachments;
  final String importedText;
  final List<String> messages;

  @override
  State<IncomingReceiptDestinationScreen> createState() =>
      _IncomingReceiptDestinationScreenState();
}

class _IncomingReceiptDestinationScreenState
    extends State<IncomingReceiptDestinationScreen> {
  var _handedOffAttachments = false;

  @override
  void dispose() {
    if (!_handedOffAttachments) {
      unawaited(
        ReceiptProofStorage.instance.deleteStagedAttachments(
          widget.attachments,
        ),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestion = ExpenseReceiptClassifier.classifySharedReceipt(
      attachments: widget.attachments,
      importedText: widget.importedText,
      messages: widget.messages,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF2A3337),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
          children: [
            const AppScreenHeader(title: 'Import Shared Item'),
            const SizedBox(height: 10),
            _ReceiptImportProofSummary(
              attachmentCount: widget.attachments.length,
              hasText: widget.importedText.trim().isNotEmpty,
            ),
            if (widget.messages.isNotEmpty) ...[
              const SizedBox(height: 8),
              _IncomingShareMessages(messages: widget.messages),
            ],
            const SizedBox(height: 10),
            const _IncomingDestinationPrompt(),
            const SizedBox(height: 10),
            _IncomingSuggestionPanel(
              suggestion: suggestion,
              onTap: () => _openSuggestedDestination(context, suggestion),
            ),
            const SizedBox(height: 10),
            _ReceiptDestinationCard(
              icon: Icons.receipt_long_rounded,
              title: 'Receipt / Expense',
              detail:
                  'Log this as a regular business, personal, or split expense.',
              onTap: () => _openReceipt(context),
            ),
            const SizedBox(height: 8),
            _ReceiptDestinationCard(
              icon: Icons.local_gas_station_rounded,
              title: 'Fuel Receipt',
              detail:
                  'Start this receipt in fuel so mileage, gallons, and vehicle cost fields stay up front.',
              onTap: () => _openReceipt(context, initialCategory: 'Fuel'),
            ),
            const SizedBox(height: 8),
            _ReceiptDestinationCard(
              icon: Icons.inventory_2_rounded,
              title: 'Materials / Inventory Receipt',
              detail:
                  'Use this when the receipt has supplies or materials that may also need inventory tracking.',
              onTap: () => _openReceipt(
                context,
                mode: ExpenseReceiptFlowMode.materials,
                initialCategory: 'Materials',
              ),
            ),
            const SizedBox(height: 8),
            _ReceiptDestinationCard(
              icon: Icons.build_rounded,
              title: 'Maintenance Record',
              detail:
                  'Use this for shop receipts, service reports, parts, oil changes, tires, and vehicle upkeep.',
              onTap: () => _openReceipt(
                context,
                mode: ExpenseReceiptFlowMode.maintenanceRepair,
                initialCategory: 'Maintenance',
              ),
            ),
            const SizedBox(height: 8),
            _ReceiptDestinationCard(
              icon: Icons.request_quote_rounded,
              title: 'Job / Contractor Document',
              detail:
                  'Save customer, job, estimate, invoice, or contractor paperwork as read-only proof.',
              onTap: () => _showJobDocumentOptions(context),
            ),
            const SizedBox(height: 8),
            _ReceiptDestinationCard(
              icon: Icons.description_rounded,
              title: 'Other Document',
              detail:
                  'Save this as read-only proof without forcing it into expenses.',
              onTap: () => _showOtherDocumentOptions(context),
            ),
            const SizedBox(height: 8),
            _ReceiptDestinationCard(
              icon: Icons.category_rounded,
              title: 'Choose Expense Category',
              detail:
                  'Pick a specific expense category first, then review the receipt.',
              onTap: () => _chooseCategory(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openSuggestedDestination(
    BuildContext context,
    ExpenseReceiptClassification suggestion,
  ) {
    switch (suggestion.kind) {
      case ExpenseReceiptClassificationKind.ambiguous:
      case ExpenseReceiptClassificationKind.notReceipt:
      case ExpenseReceiptClassificationKind.unsupported:
        _openReceipt(context);
      case ExpenseReceiptClassificationKind.fuel:
        _openReceipt(context, initialCategory: 'Fuel');
      case ExpenseReceiptClassificationKind.materials:
        _openReceipt(
          context,
          mode: ExpenseReceiptFlowMode.materials,
          initialCategory: 'Materials',
        );
      case ExpenseReceiptClassificationKind.maintenance:
        _openReceipt(
          context,
          mode: ExpenseReceiptFlowMode.maintenanceRepair,
          initialCategory: 'Maintenance',
        );
      case ExpenseReceiptClassificationKind.repair:
        _openReceipt(
          context,
          mode: ExpenseReceiptFlowMode.maintenanceRepair,
          initialCategory: 'Repair',
        );
      case ExpenseReceiptClassificationKind.cellPhone:
        _openReceipt(context, initialCategory: 'Cell Phone');
      case ExpenseReceiptClassificationKind.expenseReceipt:
        _openReceipt(context);
      case ExpenseReceiptClassificationKind.otherDocument:
        _showOtherDocumentOptions(context);
      case ExpenseReceiptClassificationKind.jobDocument:
        _showJobDocumentOptions(context);
    }
  }

  Future<void> _showOtherDocumentOptions(BuildContext context) async {
    final action = await showModalBottomSheet<_IncomingDocumentFallbackAction>(
      context: context,
      backgroundColor: const Color(0xFF1F2528),
      showDragHandle: true,
      builder: (context) => const _OtherDocumentChoiceSheet(),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case _IncomingDocumentFallbackAction.saveAsAppDocument:
        _openDocument(context, kind: AppDocumentKind.otherDocument);
      case _IncomingDocumentFallbackAction.chooseExpenseCategory:
        await _chooseCategory(context);
    }
  }

  Future<void> _showJobDocumentOptions(BuildContext context) async {
    final action = await showModalBottomSheet<_IncomingDocumentFallbackAction>(
      context: context,
      backgroundColor: const Color(0xFF1F2528),
      showDragHandle: true,
      builder: (context) => const _JobDocumentChoiceSheet(),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case _IncomingDocumentFallbackAction.saveAsAppDocument:
        _openDocument(context, kind: AppDocumentKind.jobContractorDocument);
      case _IncomingDocumentFallbackAction.chooseExpenseCategory:
        await _chooseCategory(context);
    }
  }

  Future<void> _chooseCategory(BuildContext context) async {
    final category = await showModalBottomSheet<ExpenseCategoryDefinition>(
      context: context,
      backgroundColor: const Color(0xFF1F2528),
      showDragHandle: true,
      builder: (context) => const _ReceiptCategoryChoiceSheet(),
    );
    if (category == null || !context.mounted) return;
    final mode =
        category.category == 'Repair' || category.category == 'Maintenance'
        ? ExpenseReceiptFlowMode.maintenanceRepair
        : category.category == 'Materials'
        ? ExpenseReceiptFlowMode.materials
        : ExpenseReceiptFlowMode.general;
    _openReceipt(context, mode: mode, initialCategory: category.category);
  }

  void _openReceipt(
    BuildContext context, {
    ExpenseReceiptFlowMode mode = ExpenseReceiptFlowMode.general,
    String? initialCategory,
  }) {
    _handedOffAttachments = true;
    Navigator.of(context).pushReplacement(
      appNativeRoute<Object>(
        context,
        ExpenseReceiptEntryScreen(
          mode: mode,
          initialCategory: initialCategory,
          initialAttachments: widget.attachments,
          initialImportedText: widget.importedText,
        ),
      ),
    );
  }

  void _openDocument(BuildContext context, {required AppDocumentKind kind}) {
    _handedOffAttachments = true;
    Navigator.of(context).pushReplacement(
      appNativeRoute<void>(
        context,
        AppDocumentReviewScreen(
          kind: kind,
          attachments: widget.attachments,
          importedText: widget.importedText,
        ),
      ),
    );
  }
}
