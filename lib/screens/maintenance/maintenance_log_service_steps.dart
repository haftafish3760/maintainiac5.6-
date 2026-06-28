part of 'maintenance_log_service_screen.dart';

extension _MaintenanceLogServiceSteps on _MaintenanceLogServiceScreenState {
  Widget _buildItemStep() {
    return _LogSection(
      title: 'What Was Serviced?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InlineNotice(
            text:
                'Select every item handled during this maintenance visit. Multiple items stay together as one visit.',
          ),
          const SizedBox(height: 10),
          for (final record in widget.records) ...[
            _ServiceChoice(
              record: record,
              selected: _selected.contains(record),
              onTap: () => _toggle(record),
            ),
            const SizedBox(height: 8),
          ],
          if (_oilFilterSuggestion != null) ...[
            const SizedBox(height: 2),
            _CompanionServicePrompt(
              label: 'Oil filter usually goes with engine oil.',
              actionLabel: 'Add Oil Filter',
              onPressed: () => _toggle(_oilFilterSuggestion!),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: 'Continue',
              tone: AppButtonTone.commit,
              onPressed: _selected.isEmpty
                  ? null
                  : () {
                      _activeItemIndex = 0;
                      _goToStep(1);
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    final activeItem = _activeManualItem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LogSection(
          title: 'Manual Service Visit',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _InlineNotice(
                text:
                    'This logs maintenance only. Receipt-backed expense logging will connect here after the receipt flow is finalized.',
              ),
              const SizedBox(height: 10),
              _SelectedServiceSummary(
                records: _selectedList,
                onChangeItems: widget.records.length == 1
                    ? null
                    : () => _goToStep(0),
              ),
              if (activeItem != null) ...[
                const SizedBox(height: 12),
                _ManualItemNavigator(
                  activeItem: activeItem,
                  itemIndex: _activeItemIndex,
                  itemCount: _selectedList.length,
                  onPrevious: _activeItemIndex == 0
                      ? null
                      : () => _changeActiveItem(-1),
                  onNext: _activeItemIndex >= _selectedList.length - 1
                      ? null
                      : () => _changeActiveItem(1),
                  onOpenSetup: () => _openItemSetup(activeItem),
                ),
              ],
              const SizedBox(height: 12),
              _DateButton(
                label: 'Date of Service',
                date: _serviceDate,
                onTap: _pickServiceDate,
              ),
              const SizedBox(height: 8),
              RecordTextField(
                label: 'Service Odometer',
                controller: _odometer,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 6),
              _InlineNotice(text: _odometerHelperText),
              if (_detailsIssueText != null) ...[
                const SizedBox(height: 8),
                _InlineAlert(text: _detailsIssueText!, urgent: true),
              ] else if (_odometerAttentionText != null) ...[
                const SizedBox(height: 8),
                _InlineAlert(text: _odometerAttentionText!),
              ],
              const SizedBox(height: 12),
              RecordTextField(
                label: 'Who Did The Work?',
                controller: _provider,
              ),
              const SizedBox(height: 12),
              RecordTextField(
                label: 'Service Notes',
                controller: _notes,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (widget.records.length > 1)
              AppButton(
                label: 'Back',
                tone: AppButtonTone.general,
                onPressed: () => _goToStep(0),
              ),
            const Spacer(),
            AppButton(
              label: 'Review',
              tone: AppButtonTone.commit,
              onPressed: _canReview ? () => _goToStep(2) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return _LogSection(
      title: 'Review Maintenance Visit',
      child: Column(
        children: [
          _ReviewLine(
            label: 'Items serviced',
            value: _selectedList.map((item) => item.itemName).join(', '),
          ),
          _ReviewLine(label: 'Vehicle', value: _vehicleLabel),
          _ReviewLine(label: 'Service date', value: _formatDate(_serviceDate)),
          _ReviewLine(label: 'Odometer', value: _odometerReviewLabel),
          _ReviewLine(label: 'Performed by', value: _providerReviewLabel),
          const _ReviewLine(label: 'Expense', value: 'Not linked'),
          const SizedBox(height: 12),
          Row(
            children: [
              AppButton(
                label: 'Back',
                tone: AppButtonTone.general,
                onPressed: () => _goToStep(1),
              ),
              const Spacer(),
              AppButton(
                label: 'Save Visit',
                tone: AppButtonTone.commit,
                onPressed: _canSave ? _save : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openItemSetup(MaintenanceRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => MaintenanceItemDetailScreen(record: record),
      ),
    );
  }
}
