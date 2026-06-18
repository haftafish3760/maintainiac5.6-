import 'package:flutter/material.dart';

import 'receipt_form_panel.dart';

class SharedReceiptDateTimePanel extends StatelessWidget {
  const SharedReceiptDateTimePanel({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onSelectDate,
    required this.onSelectTime,
    required this.onClearTime,
  });

  final DateTime selectedDate;
  final TimeOfDay? selectedTime;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;
  final VoidCallback onClearTime;

  @override
  Widget build(BuildContext context) {
    return ReceiptFormPanel(
      title: 'Receipt Date And Time',
      subtitle: 'Set when this purchase happened.',
      icon: Icons.event_note_rounded,
      children: [
        Row(
          children: [
            Expanded(
              child: _ReceiptContextButton(
                label: 'Date',
                value: _formatDate(selectedDate),
                requiredText: 'Required',
                icon: Icons.calendar_month_rounded,
                onTap: onSelectDate,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptContextButton(
                label: 'Time',
                value: selectedTime == null
                    ? 'No time'
                    : selectedTime!.format(context),
                requiredText: 'Optional',
                icon: Icons.schedule_rounded,
                trailing: selectedTime == null
                    ? null
                    : IconButton(
                        onPressed: onClearTime,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF101416),
                          size: 18,
                        ),
                        tooltip: 'Clear time',
                      ),
                onTap: onSelectTime,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _ReceiptContextButton extends StatelessWidget {
  const _ReceiptContextButton({
    required this.label,
    required this.value,
    required this.requiredText,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final String value;
  final String requiredText;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFAAB4B9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF101416), width: .8),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF101416), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: _style(12, FontWeight.w900)),
                    Text(requiredText, style: _style(10, FontWeight.w700)),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _style(13, FontWeight.w800),
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF101416),
                    size: 19,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _style(double size, FontWeight weight) {
    return TextStyle(
      color: const Color(0xFF101416),
      fontSize: size,
      fontWeight: weight,
    );
  }
}
