import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_back_button.dart';
import 'maintenance_item_detail_screen.dart';
import 'maintenance_svg_icon.dart';

class MaintenanceRecordListScreen extends StatelessWidget {
  const MaintenanceRecordListScreen({
    required this.title,
    required this.records,
    super.key,
  });

  final String title;
  final List<MaintenanceRecord> records;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            padding: const EdgeInsets.all(10),
            children: [
              AppScreenHeader(title: title),
              const SizedBox(height: 10),
              if (records.isEmpty)
                const _EmptyRecordList()
              else
                for (final record in records) ...[
                  _RecordListRow(record: record),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRecordList extends StatelessWidget {
  const _EmptyRecordList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151C1F),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5D6A71)),
      ),
      child: const Text(
        'Nothing is in this maintenance group right now.',
        style: TextStyle(color: Color(0xFFE7EEF1), fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _RecordListRow extends StatelessWidget {
  const _RecordListRow({required this.record});

  final MaintenanceRecord record;

  @override
  Widget build(BuildContext context) {
    final status = record.setupComplete
        ? record.timeOnly
              ? '${record.monthsRemaining} months remaining'
              : '${_formatMiles(record.milesRemaining)} miles remaining'
        : 'Not set up yet';
    return InkWell(
      onTap: () => Navigator.of(context).push(
        appNativeRoute<void>(
          context,
          MaintenanceItemDetailScreen(record: record),
        ),
      ),
      borderRadius: BorderRadius.circular(6),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF151C1F),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF5D6A71)),
        ),
        child: Row(
          children: [
            MaintenanceSvgIcon(itemName: record.itemName, size: 42),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.itemName,
                    style: const TextStyle(
                      color: Color(0xFFE7EEF1),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    status,
                    style: const TextStyle(
                      color: Color(0xFFCAD2D5),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMiles(int value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().toString();
  final buffer = StringBuffer(sign);
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
