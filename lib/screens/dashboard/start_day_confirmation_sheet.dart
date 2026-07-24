import 'package:flutter/material.dart';

import '../../shared/theme/app_action_colors.dart';

enum StartDayReviewAction { start, editOdometer }

Future<StartDayReviewAction?> openStartDayConfirmationSheet(
  BuildContext context, {
  required String vehicleLabel,
  required String workProfileName,
  required int startingOdometer,
}) {
  return showModalBottomSheet<StartDayReviewAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF2E3A40),
    builder: (context) => _StartDayConfirmationSheet(
      vehicleLabel: vehicleLabel,
      workProfileName: workProfileName,
      startingOdometer: startingOdometer,
    ),
  );
}

class _StartDayConfirmationSheet extends StatelessWidget {
  const _StartDayConfirmationSheet({
    required this.vehicleLabel,
    required this.workProfileName,
    required this.startingOdometer,
  });

  final String vehicleLabel;
  final String workProfileName;
  final int startingOdometer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          14,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ready to Start Day',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF101416),
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _ReviewRow(label: 'Vehicle', value: vehicleLabel),
            const SizedBox(height: 8),
            _ReviewRow(label: 'Work profile', value: workProfileName),
            const SizedBox(height: 8),
            _ReviewRow(
              label: 'Starting odometer',
              value: '${_comma(startingOdometer)} mi',
            ),
            const SizedBox(height: 12),
            const _NextStepPanel(),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(StartDayReviewAction.editOdometer),
                  child: const Text('Edit Odometer'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(StartDayReviewAction.start),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppActionColors.positive,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start Workday'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFAAB4B9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF7C898F)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF273237),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF101416),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepPanel extends StatelessWidget {
  const _NextStepPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5B6A70)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'This creates the active workday record and opens the tracking '
          'screen. GPS is assistance only; your confirmed odometer stays the '
          'official mileage record.',
          style: TextStyle(
            color: Color(0xFFE2E8EA),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

String _comma(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i += 1) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}
