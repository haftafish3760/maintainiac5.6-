part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryScaffold on _ExpenseReceiptEntryScreenState {
  Widget _buildReceiptEntryScaffold(BuildContext context) {
    final showAttachmentBeforeReview = !_receiptReviewFlowStarted;
    final receiptAttachmentPanel = _buildReceiptAttachmentPanel(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),
      body: SafeArea(
        child: ListView(
          controller: _receiptScrollController,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
          children: [
            _ReceiptHeader(
              title: _isEditingReceipt
                  ? _isMaterialsFlow
                        ? 'Edit Materials Receipt'
                        : _isMaintenanceRepairFlow
                        ? 'Edit Maintenance Receipt'
                        : 'Edit Expense Receipt'
                  : _isMaterialsFlow
                  ? 'Materials Receipt'
                  : _isMaintenanceRepairFlow
                  ? 'Maintenance / Repair Receipt'
                  : 'Expense Receipt',
              subtitle: _isMaterialsFlow
                  ? 'Log material purchases as expenses. Inventory tracking is optional.'
                  : _isMaintenanceRepairFlow
                  ? 'Log the expense now. Maintenance event linking is next so the same receipt can update maintenance records.'
                  : _isEditingReceipt
                  ? 'Review and update the original saved receipt fields.'
                  : 'Record what was spent. Add each receipt line as business or personal.',
            ),
            const SizedBox(height: 8),
            const GlobalOdometerHeader(section: AppSection.expenses),
            const SizedBox(height: 8),
            if (_isMaterialsFlow) ...[
              _InventoryTrackingPrompt(
                value: _trackMaterialsInInventory,
                onChanged: (value) {
                  _setReceiptEntryState(
                    () => _trackMaterialsInInventory = value,
                  );
                  _scheduleDraftSave();
                },
              ),
              const SizedBox(height: 8),
            ],
            SharedReceiptDateTimePanel(
              selectedDate: _selectedDate,
              selectedTime: _selectedTime,
              onSelectDate: _selectDate,
              onSelectTime: _selectTime,
              onClearTime: () {
                _setReceiptEntryState(() => _selectedTime = null);
                _scheduleDraftSave();
              },
            ),
            const SizedBox(height: 8),
            KeyedSubtree(
              key: _receiptReadHandoffKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_shouldShowReceiptReadHandoffPanel) ...[
                    _ReceiptReadHandoffPanel(
                      savedProofCount: _receiptReadHandoffProofCount,
                      ocrSourceCount: _receiptReadHandoffOcrSourceCount,
                      processingInFlight: _scanningReceiptPhotos,
                      decisionLabel: _receiptReadHandoffDecision,
                      actionLabel: _receiptReadHandoffAction,
                      stageLabel: _receiptReadHandoffStage,
                      routeResultLabel: _receiptReadHandoffRouteResult,
                      coverageWarningLabel: _receiptReadHandoffCoverageWarning,
                      onReviewDetails: _scrollToReceiptReview,
                      onAddOrRetakePhoto: _scrollToReceiptPhotoRecovery,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (showAttachmentBeforeReview) ...[
                    receiptAttachmentPanel,
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            if (_hasAppAssistedReceiptReview) ...[
              KeyedSubtree(
                key: _receiptReviewKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ReceiptAppAssistedReviewIntroPanel(
                      lineCount: _lines.length,
                      unreviewedLineCount: _unreviewedParsedLineCount,
                      receiptTotalLabel: _money(_receiptTotal),
                      detailMode: _detailEntryMode,
                      ocrDiagnostics: _lastOcrDiagnostics,
                      parseDiagnostics: _lastParseDiagnostics,
                      ocrWarnings: _lastOcrWarnings,
                      onAddMissingBottomSection: _scrollToReceiptPhotoRecovery,
                    ),
                    const SizedBox(height: 8),
                    if (_receiptClassification != null) ...[
                      _ReceiptClassificationReviewPanel(
                        classification: _receiptClassification!,
                        parseQuality: _lastParseQuality,
                        parseDiagnostics: _lastParseDiagnostics,
                        fieldConfidences: _lastFieldConfidences,
                        ocrDiagnostics: _lastOcrDiagnostics,
                        ocrWarnings: _lastOcrWarnings,
                        maintenanceHints: _maintenanceHints,
                        onApplyCategory: _applySuggestedReceiptCategory,
                        ocrActionCallbacks: _ocrReviewActionCallbacks,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_lines.isEmpty) ...[
                      _buildReceiptNoLineRecoveryPanel(),
                      const SizedBox(height: 8),
                    ],
                    if (_lines.isNotEmpty) ...[
                      _ReceiptWholeUseReviewPanel(
                        lines: _lines,
                        onMarkBusiness: () =>
                            _markAllReceiptLines(_ExpenseLineUse.business),
                        onMarkPersonal: () =>
                            _markAllReceiptLines(_ExpenseLineUse.personal),
                        onMarkMixed: () =>
                            _markAllReceiptLines(_ExpenseLineUse.split),
                      ),
                      const SizedBox(height: 8),
                      if (_lines.any((line) => line.hasParserReview)) ...[
                        _ReceiptLineEvidenceReviewPanel(
                          lines: _lines,
                          onConfirm: _confirmParsedLine,
                          onEdit: (index) =>
                              _editLine(index: index, initial: _lines[index]),
                          onMarkExpenseOnly: _markLineExpenseOnly,
                        ),
                        const SizedBox(height: 8),
                      ],
                      _ReceiptRecapPanel(
                        lines: _lines,
                        storeName: _storeController.text.trim(),
                        storeAddress: _receiptStoreAddressLabel,
                        receiptDateLabel: _receiptDateLabel,
                        receiptSubtotal: _enteredReceiptSubtotal,
                        salesTax: _enteredReceiptTax,
                        receiptTotal: _receiptTotal,
                        businessTotal: _businessTotal,
                        personalTotal: _personalTotal,
                        onEdit: (index) =>
                            _editLine(index: index, initial: _lines[index]),
                        onSetUse: _setReceiptLineUse,
                        onDelete: (index) {
                          _setReceiptEntryState(() => _lines.removeAt(index));
                          _scheduleDraftSave();
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
            if (_shouldShowCollapsedReceiptPhotoRecovery) ...[
              KeyedSubtree(
                key: _receiptPhotoRecoveryKey,
                child: _ReceiptPhotoRecoveryPanel(
                  onReviewDetails: _scrollToReceiptReview,
                  missingBottomSection:
                      _lastOcrDiagnostics?.receiptMayNeedBottomSection == true,
                  missingBottomEdgeAndTotals:
                      _lastOcrDiagnostics?.receiptMissingBottomEdgeAndTotals ==
                      true,
                  child: receiptAttachmentPanel,
                ),
              ),
              const SizedBox(height: 8),
            ],
            SharedReceiptStorePanel(
              store: _storeController,
              phone: _phoneController,
              street: _streetController,
              city: _cityController,
              state: _stateController,
              zip: _zipController,
              email: _emailController,
              website: _websiteController,
              notes: _storeNotesController,
              onChanged: () {
                _setReceiptEntryState(() {});
                _scheduleDraftSave();
              },
            ),
            const SizedBox(height: 8),
            _ReceiptDetailModePanel(
              value: _detailEntryMode,
              onChanged: _setReceiptReviewMode,
            ),
            const SizedBox(height: 8),
            _ReceiptLineActionsPanel(
              nextLineNumber: _lines.length + 1,
              materialMode: _isMaterialsFlow,
              maintenanceRepairMode: _isMaintenanceRepairFlow,
              fuelMode: widget.initialCategory == 'Fuel',
              detailedMode:
                  _detailEntryMode == _ReceiptDetailEntryMode.detailedItems,
              onAddBusiness: () => _addReceiptLineForMode(
                use: _ExpenseLineUse.business,
                category: _isMaterialsFlow
                    ? 'Materials'
                    : widget.initialCategory ?? 'Uncategorized',
              ),
              onAddPersonal: () => _addReceiptLineForMode(
                use: _ExpenseLineUse.personal,
                category: widget.initialCategory ?? 'Uncategorized',
              ),
              onAddShared: () => _addReceiptLineForMode(
                use: _ExpenseLineUse.split,
                category: widget.initialCategory ?? 'Uncategorized',
              ),
              onAddMaterial: () => _editLine(
                initial: _ExpenseReceiptLine.blank(category: 'Materials'),
              ),
              onAddMaintenanceRepair: () => _editLine(
                initial: _ExpenseReceiptLine.blank(
                  category: widget.initialCategory == 'Maintenance'
                      ? 'Maintenance'
                      : 'Repair',
                ),
              ),
            ),
            const SizedBox(height: 8),
            _ReceiptTotalsPanel(
              lineSubtotal: _lineSubtotal,
              receiptSubtotalController: _receiptSubtotalController,
              salesTaxController: _salesTaxController,
              receiptTotalController: _receiptTotalController,
            ),
            const SizedBox(height: 8),
            _ReceiptSavePanel(
              lineCount: _lines.length,
              reviewCount: _lines
                  .where((line) => line.parserNeedsReview)
                  .length,
              splitPercentIssueCount: _splitLinesMissingBusinessPercentCount,
              total: _receiptTotal,
              onSave: _saveReceipt,
            ),
          ],
        ),
      ),
    );
  }
}
