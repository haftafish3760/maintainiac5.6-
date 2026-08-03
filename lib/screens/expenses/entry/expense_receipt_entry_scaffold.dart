part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryScaffold on _ExpenseReceiptEntryScreenState {
  Widget _buildReceiptEntryScaffold(BuildContext context) {
    if (_usesRebuiltManualDetailedReceiptFlow) {
      return _buildManualDetailedReceiptFlow(context);
    }
    return _buildLegacyReceiptEntryScaffold(context);
  }

  Widget _buildLegacyReceiptEntryScaffold(BuildContext context) {
    final showAttachmentBeforeReview = !_receiptReviewFlowStarted;
    final receiptAttachmentPanel = _buildReceiptAttachmentPanel(context);
    final showSharedReceiptLines = _lines.isNotEmpty;
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
              category: _receiptCategory,
            ),
            const SizedBox(height: 8),
            if (showAttachmentBeforeReview && _showReceiptEntryGuide) ...[
              const _ReceiptEntryStartGuide(),
              const SizedBox(height: 8),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Select which vehicle this expense belongs to.',
                style: TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const GlobalOdometerHeader(section: AppSection.expenses),
            const SizedBox(height: 8),
            _ExpenseOdometerPanel(
              reading: _expenseOdometerReading,
              onEdit: _editExpenseOdometerReading,
            ),
            const SizedBox(height: 8),
            _buildJobContextPanel(context),
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
            // A receipt belongs to a merchant. Put the optional proof after
            // the store fields so a manual detailed receipt reads top to
            // bottom like a real receipt form: date, merchant, proof, lines.
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
                  // OCR is started by the shared attachment panel. Keep that
                  // stateful widget mounted while the parent swaps from the
                  // capture controls to the receipt-review progress card.
                  Offstage(
                    offstage: !showAttachmentBeforeReview,
                    child: Column(
                      children: [
                        receiptAttachmentPanel,
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_shouldShowReceiptReviewFields) ...[
              KeyedSubtree(
                key: _receiptReviewKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_lines.isEmpty) ...[
                      _buildReceiptNoLineRecoveryPanel(),
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
                  manualReviewOnly: _receiptRecoveryNeedsManualReviewOnly,
                  child: receiptAttachmentPanel,
                ),
              ),
              const SizedBox(height: 8),
            ],
            _ReceiptWholeUseReviewPanel(
              selectedUse: _receiptUse,
              onMarkBusiness: () => _setReceiptUse(_ExpenseLineUse.business),
              onMarkPersonal: () => _setReceiptUse(_ExpenseLineUse.personal),
              onMarkMixed: () => _setReceiptUse(_ExpenseLineUse.split),
            ),
            const SizedBox(height: 8),
            _ReceiptLineActionsPanel(
              nextLineNumber: _lines.length + 1,
              materialMode: _isMaterialsFlow,
              maintenanceRepairMode: _isMaintenanceRepairFlow,
              fuelMode: widget.initialCategory == 'Fuel',
              onAddItem: () => _editLine(
                initial: _ExpenseReceiptLine.blank(
                  use: _receiptUse,
                  category: _isMaterialsFlow
                      ? 'Materials'
                      : _isMaintenanceRepairFlow
                      ? widget.initialCategory == 'Maintenance'
                            ? 'Maintenance'
                            : 'Repair'
                      : _newReceiptLineCategory,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (showSharedReceiptLines) ...[
              _ReceiptRecapPanel(
                lines: _lines,
                storeName: _storeController.text.trim(),
                storeAddress: _receiptStoreAddressLabel,
                receiptDateLabel: _receiptDateLabel,
                receiptSubtotal: _enteredReceiptSubtotal,
                salesTax: _enteredReceiptTax,
                receiptTotal: _receiptTotal,
                detailMode: _detailEntryMode,
                onEdit: (index) =>
                    _editLine(index: index, initial: _lines[index]),
                onSetUse: _setReceiptLineUse,
              ),
              const SizedBox(height: 8),
            ],
            _ReceiptTotalsPanel(
              detailMode: _detailEntryMode,
              lineSubtotal: _lineSubtotal,
              receiptSubtotalController: _receiptSubtotalController,
              salesTaxController: _salesTaxController,
              receiptTotalController: _receiptTotalController,
            ),
            const SizedBox(height: 8),
            _ReceiptSavePanel(
              lineCount: _lines.length,
              total: _receiptTotal,
              splitPercentIssueCount: _splitLinesMissingBusinessPercentCount,
              onSave: _saveReceipt,
            ),
          ],
        ),
      ),
    );
  }
}
