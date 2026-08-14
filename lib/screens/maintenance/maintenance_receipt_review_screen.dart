import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/state/app_state.dart';
import '../../shared/state/global_odometer.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_screen_shell.dart'
    show AppSection, GlobalOdometerHeader;
import 'data/maintenance_receipt_parser.dart';
import 'data/maintenance_receipt_review.dart';
import 'maintenance_draft_store.dart';

part 'maintenance_receipt_review_item_card.dart';

class MaintenanceReceiptReviewScreen extends StatefulWidget {
  MaintenanceReceiptReviewScreen({
    required this.parserResult,
    this.initialReview,
    super.key,
  }) : assert(
         initialReview == null ||
             initialReview.parserResult.sourceFingerprintSha256 ==
                 parserResult.sourceFingerprintSha256,
       );

  final MaintenanceReceiptParserResult parserResult;
  final MaintenanceReceiptReview? initialReview;

  @override
  State<MaintenanceReceiptReviewScreen> createState() =>
      _MaintenanceReceiptReviewScreenState();
}

class _MaintenanceReceiptReviewScreenState
    extends State<MaintenanceReceiptReviewScreen> {
  late List<MaintenanceReceiptReviewItem> _items =
      widget.initialReview?.items.toList() ??
      [
        for (final candidate in widget.parserResult.candidates)
          createMaintenanceReceiptReviewItem(candidate),
      ];
  List<MaintenanceReceiptReviewIssue> _issues = const [];
  late bool _hasEdited = widget.initialReview != null;
  bool _draftWarningShown = false;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final odometer = GlobalOdometerScope.of(context);
    final activeVehicle = state.activeVehicle;
    final vehicleMatches =
        activeVehicle != null &&
        activeVehicle.id == widget.parserResult.activeVehicleId;

    return PopScope(
      canPop: !_hasEdited,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard()) {
          await _discardAndPop();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: ListView(
              key: const PageStorageKey('maintenance-receipt-review'),
              padding: const EdgeInsets.all(10),
              children: [
                const GlobalOdometerHeader(section: AppSection.maintenance),
                const SizedBox(height: 10),
                const AppScreenHeader(title: 'Review Maintenance Receipt'),
                const SizedBox(height: 10),
                _ReceiptSummary(
                  result: widget.parserResult,
                  currentVehicleName: activeVehicle?.nickname,
                  currentOdometer: odometer.reading,
                ),
                if (!vehicleMatches) ...[
                  const SizedBox(height: 10),
                  const _ReviewNotice(
                    color: Color(0xFFE3342F),
                    icon: Icons.car_crash_outlined,
                    text:
                        'The active vehicle changed after this receipt was parsed. Return and parse it again for the currently selected vehicle.',
                  ),
                ],
                if (widget.initialReview != null) ...[
                  const SizedBox(height: 10),
                  const _ReviewNotice(
                    color: Color(0xFFFFA640),
                    icon: Icons.restore,
                    text:
                        'This unfinished receipt review was restored from local maintenance drafts.',
                  ),
                ],
                for (var index = 0; index < _items.length; index++) ...[
                  const SizedBox(height: 10),
                  _ReviewItemCard(
                    key: ValueKey('receipt-review-item-$index'),
                    item: _items[index],
                    currentOdometer: odometer.reading,
                    issues: _issues
                        .where((issue) => issue.itemIndex == index)
                        .toList(growable: false),
                    onChanged: (item) => _replaceItem(index, item),
                  ),
                ],
                if (_items.isEmpty) ...[
                  const SizedBox(height: 10),
                  const _ReviewNotice(
                    color: Color(0xFFFFC928),
                    icon: Icons.search_off,
                    text:
                        'No maintenance candidates were found. Nothing will be added or logged.',
                  ),
                ],
                if (_issues.any((issue) => issue.itemIndex == null)) ...[
                  const SizedBox(height: 10),
                  _IssuePanel(
                    issues: _issues
                        .where((issue) => issue.itemIndex == null)
                        .toList(growable: false),
                  ),
                ],
                const SizedBox(height: 12),
                const _ReviewNotice(
                  color: Color(0xFF4FE8FF),
                  icon: Icons.verified_user_outlined,
                  text:
                      'Reviewing creates no maintenance record and never changes the odometer. Confirmed choices must still pass the maintenance setup and durable-save layer.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    AppButton(
                      label: 'Cancel',
                      tone: AppButtonTone.destructive,
                      compact: true,
                      onPressed: _cancel,
                    ),
                    AppButton(
                      label: 'Continue with Reviewed Items',
                      tone: AppButtonTone.commit,
                      compact: true,
                      onPressed: vehicleMatches && _items.isNotEmpty
                          ? () => _continue(odometer.reading)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _replaceItem(int index, MaintenanceReceiptReviewItem item) {
    setState(() {
      _items = [..._items]..[index] = item;
      _issues = const [];
      _hasEdited = true;
    });
    unawaited(_saveDraft(GlobalOdometerScope.of(context).reading));
  }

  Future<void> _continue(int currentOdometer) async {
    final review = MaintenanceReceiptReview(
      parserResult: widget.parserResult,
      currentOdometer: currentOdometer,
      items: List.unmodifiable(_items),
    );
    final outcome = buildMaintenanceReceiptCommands(review);
    if (!outcome.isValid) {
      setState(() => _issues = outcome.issues);
      return;
    }
    if (!mounted) return;
    setState(() => _hasEdited = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(outcome);
    });
  }

  Future<void> _cancel() async {
    if (!_hasEdited || await _confirmDiscard()) {
      await _discardAndPop();
    }
  }

  Future<void> _saveDraft(int currentOdometer) async {
    try {
      await MaintenanceDraftStore.saveReceiptReviewDraft(
        vehicleId: widget.parserResult.activeVehicleId,
        vehicleName: widget.parserResult.activeVehicleName,
        sourceFingerprintSha256: widget.parserResult.sourceFingerprintSha256,
        review: MaintenanceReceiptReview(
          parserResult: widget.parserResult,
          currentOdometer: currentOdometer,
          items: List.unmodifiable(_items),
        ).toDraftJson(),
      );
    } on Object catch (error) {
      if (!mounted || _draftWarningShown) return;
      _draftWarningShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Receipt review draft was not saved: $error')),
      );
    }
  }

  Future<bool> _clearDraft() async {
    try {
      await MaintenanceDraftStore.clearReceiptReviewDraft(
        vehicleId: widget.parserResult.activeVehicleId,
        sourceFingerprintSha256: widget.parserResult.sourceFingerprintSha256,
      );
      return true;
    } on Object catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Receipt review draft was not cleared: $error')),
      );
      return false;
    }
  }

  Future<void> _discardAndPop() async {
    if (!await _clearDraft() || !mounted) return;
    setState(() => _hasEdited = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<bool> _confirmDiscard() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Discard receipt review?'),
            content: const Text(
              'Your review choices have not changed maintenance or the vehicle odometer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep Reviewing'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Discard Review'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _ReceiptSummary extends StatelessWidget {
  const _ReceiptSummary({
    required this.result,
    required this.currentVehicleName,
    required this.currentOdometer,
  });

  final MaintenanceReceiptParserResult result;
  final String? currentVehicleName;
  final int currentOdometer;

  @override
  Widget build(BuildContext context) {
    final merchant = result.merchantName.trim().isEmpty
        ? 'Merchant not identified'
        : result.merchantName;
    final date = result.receiptDate;
    return _ReviewSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            merchant,
            style: const TextStyle(
              color: Color(0xFFE7EEF1),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            [
              if (date != null) '${date.month}/${date.day}/${date.year}',
              _receiptKindLabel(result.kind),
              currentVehicleName ?? 'No active vehicle',
              '$currentOdometer miles current',
            ].join(' • '),
            style: const TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final warning in result.warnings) ...[
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFC928),
                  size: 17,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    warning,
                    style: const TextStyle(
                      color: Color(0xFFFFE7A0),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _IssuePanel extends StatelessWidget {
  const _IssuePanel({required this.issues});

  final List<MaintenanceReceiptReviewIssue> issues;

  @override
  Widget build(BuildContext context) {
    return _ReviewNotice(
      color: const Color(0xFFE3342F),
      icon: Icons.error_outline,
      text: issues.map((issue) => issue.message).join('\n'),
    );
  }
}

class _ReviewNotice extends StatelessWidget {
  const _ReviewNotice({
    required this.color,
    required this.icon,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .72)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFE7EEF1),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSurface extends StatelessWidget {
  const _ReviewSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF172023),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5D6A71)),
      ),
      child: child,
    );
  }
}

String _decisionLabel(MaintenanceReceiptReviewDecision decision) {
  return switch (decision) {
    MaintenanceReceiptReviewDecision.undecided => 'Choose an action',
    MaintenanceReceiptReviewDecision.setupOnly => 'Set up tracking only',
    MaintenanceReceiptReviewDecision.serviceOnly =>
      'Log completed service only',
    MaintenanceReceiptReviewDecision.setupAndService =>
      'Set up tracking and log service',
    MaintenanceReceiptReviewDecision.expenseOnly => 'Expense only',
    MaintenanceReceiptReviewDecision.ignore => 'Ignore',
  };
}

String _setupModeLabel(MaintenanceReceiptSetupMode mode) {
  return switch (mode) {
    MaintenanceReceiptSetupMode.basic => 'Basic — interval only',
    MaintenanceReceiptSetupMode.advanced => 'Advanced — include item details',
  };
}

String _receiptKindLabel(MaintenanceReceiptKind kind) {
  return switch (kind) {
    MaintenanceReceiptKind.partsPurchase => 'Parts purchase',
    MaintenanceReceiptKind.serviceInvoice => 'Service invoice',
    MaintenanceReceiptKind.mixed => 'Mixed receipt',
    MaintenanceReceiptKind.unknown => 'Receipt type unknown',
  };
}

String _dateValue(DateTime? value) {
  return value == null ? '' : '${value.month}/${value.day}/${value.year}';
}

DateTime? _parseDate(String value) {
  final match = RegExp(
    r'^\s*(\d{1,2})/(\d{1,2})/(\d{4})\s*$',
  ).firstMatch(value);
  if (match == null) return null;
  final month = int.parse(match.group(1)!);
  final day = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  final parsed = DateTime(year, month, day);
  return parsed.year == year && parsed.month == month && parsed.day == day
      ? parsed
      : null;
}
