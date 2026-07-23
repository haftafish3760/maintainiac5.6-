part of 'maintenance_receipt_review_screen.dart';

class _ReviewItemCard extends StatelessWidget {
  const _ReviewItemCard({
    required this.item,
    required this.currentOdometer,
    required this.issues,
    required this.onChanged,
    super.key,
  });

  final MaintenanceReceiptReviewItem item;
  final int currentOdometer;
  final List<MaintenanceReceiptReviewIssue> issues;
  final ValueChanged<MaintenanceReceiptReviewItem> onChanged;

  bool get _logsService =>
      item.decision == MaintenanceReceiptReviewDecision.serviceOnly ||
      item.decision == MaintenanceReceiptReviewDecision.setupAndService;

  bool get _appliesMaintenance =>
      item.decision == MaintenanceReceiptReviewDecision.setupOnly ||
      item.decision == MaintenanceReceiptReviewDecision.serviceOnly ||
      item.decision == MaintenanceReceiptReviewDecision.setupAndService;

  @override
  Widget build(BuildContext context) {
    final serviceOdometer = item.effectiveServiceOdometer;
    final hasOdometerConflict =
        _logsService &&
        serviceOdometer != null &&
        serviceOdometer > currentOdometer;

    return _ReviewSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.effectiveItemName,
                  style: const TextStyle(
                    color: Color(0xFFE7EEF1),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${(item.source.confidence * 100).round()}% evidence',
                style: const TextStyle(
                  color: Color(0xFF9DADB3),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<MaintenanceReceiptReviewDecision>(
            key: const ValueKey('receipt-review-decision'),
            initialValue: item.decision,
            decoration: const InputDecoration(labelText: 'What should happen?'),
            items: [
              for (final decision in MaintenanceReceiptReviewDecision.values)
                DropdownMenuItem(
                  value: decision,
                  child: Text(_decisionLabel(decision)),
                ),
            ],
            onChanged: (decision) {
              if (decision != null) {
                onChanged(item.copyWith(decision: decision));
              }
            },
          ),
          if (item.recommendedDecision !=
                  MaintenanceReceiptReviewDecision.undecided &&
              item.decision == MaintenanceReceiptReviewDecision.undecided) ...[
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => onChanged(
                  item.copyWith(decision: item.recommendedDecision),
                ),
                icon: const Icon(Icons.auto_fix_high, size: 17),
                label: Text(
                  'Use recommendation: ${_decisionLabel(item.recommendedDecision)}',
                ),
              ),
            ),
          ],
          if (_appliesMaintenance) ...[
            const SizedBox(height: 8),
            TextFormField(
              initialValue: item.effectiveItemName,
              decoration: const InputDecoration(labelText: 'Maintenance item'),
              onChanged: (value) => onChanged(item.copyWith(itemName: value)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MaintenanceReceiptSetupMode>(
              key: const ValueKey('receipt-review-setup-mode'),
              initialValue: item.setupMode,
              decoration: const InputDecoration(labelText: 'Setup detail'),
              items: [
                for (final mode in MaintenanceReceiptSetupMode.values)
                  DropdownMenuItem(
                    value: mode,
                    child: Text(_setupModeLabel(mode)),
                  ),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  onChanged(item.copyWith(setupMode: mode));
                }
              },
            ),
          ],
          if (_appliesMaintenance &&
              item.setupMode == MaintenanceReceiptSetupMode.advanced) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.suggestedDetailA ?? '',
                    decoration: const InputDecoration(labelText: 'Type/detail'),
                    onChanged: (value) =>
                        onChanged(item.copyWith(detailA: value)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.suggestedDetailB ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Specification',
                    ),
                    onChanged: (value) =>
                        onChanged(item.copyWith(detailB: value)),
                  ),
                ),
              ],
            ),
          ],
          if (_logsService) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _dateValue(item.effectiveServiceDate),
                    decoration: const InputDecoration(
                      labelText: 'Service date (MM/DD/YYYY)',
                    ),
                    keyboardType: TextInputType.datetime,
                    onChanged: (value) {
                      final parsed = _parseDate(value);
                      onChanged(
                        item.copyWith(
                          serviceDate: parsed,
                          clearServiceDate: parsed == null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue:
                        item.effectiveServiceOdometer?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Service odometer',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      onChanged(
                        item.copyWith(
                          serviceOdometer: parsed,
                          clearServiceOdometer: parsed == null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
          if (_appliesMaintenance) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.effectiveIntervalMiles?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Interval miles',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      onChanged(
                        item.copyWith(
                          intervalMiles: parsed,
                          clearIntervalMiles: parsed == null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue:
                        item.effectiveIntervalMonths?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Interval months',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      onChanged(
                        item.copyWith(
                          intervalMonths: parsed,
                          clearIntervalMonths: parsed == null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
          if (_logsService &&
              item.source.productPurchased &&
              !item.source.completedServiceIndicated)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: item.confirmedPurchasedItemWasInstalled,
              title: const Text('I confirm this purchased item was installed.'),
              onChanged: (value) => onChanged(
                item.copyWith(
                  confirmedPurchasedItemWasInstalled: value ?? false,
                ),
              ),
            ),
          if (_logsService && item.source.notCompletedIndicated)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: item.confirmedWorkWasCompleted,
              title: const Text(
                'I confirm this work was completed despite the receipt wording.',
              ),
              onChanged: (value) => onChanged(
                item.copyWith(confirmedWorkWasCompleted: value ?? false),
              ),
            ),
          if (_appliesMaintenance && item.source.returnOrExchangeIndicated)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: item.confirmedReturnOrExchangeResolved,
              title: const Text(
                'I resolved the return or exchange and confirmed what was kept.',
              ),
              onChanged: (value) => onChanged(
                item.copyWith(
                  confirmedReturnOrExchangeResolved: value ?? false,
                ),
              ),
            ),
          if (hasOdometerConflict)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: item.confirmedOdometerConflict,
              title: Text(
                'I confirm the receipt reading of $serviceOdometer miles is above the current $currentOdometer miles.',
              ),
              onChanged: (value) => onChanged(
                item.copyWith(confirmedOdometerConflict: value ?? false),
              ),
            ),
          if (item.source.evidence.isNotEmpty) ...[
            const SizedBox(height: 7),
            const Text(
              'Receipt evidence',
              style: TextStyle(
                color: Color(0xFFCAD2D5),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            for (final evidence in item.source.evidence)
              Text(
                'Line ${evidence.lineNumber}: ${evidence.safeSnippet}',
                style: const TextStyle(
                  color: Color(0xFF9DADB3),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
          if (issues.isNotEmpty) ...[
            const SizedBox(height: 8),
            _IssuePanel(issues: issues),
          ],
        ],
      ),
    );
  }
}
