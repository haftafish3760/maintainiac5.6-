import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_screen_shell.dart'
    show AppSection, GlobalOdometerHeader;
import 'maintenance_item_detail_screen.dart';
import 'maintenance_log_service_screen.dart';

class MaintenanceServiceEventDetailScreen extends StatelessWidget {
  const MaintenanceServiceEventDetailScreen({required this.event, super.key});

  final MaintenanceServiceEvent event;

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
              const GlobalOdometerHeader(section: AppSection.maintenance),
              const SizedBox(height: 10),
              AppScreenHeader(title: 'Service Record'),
              const SizedBox(height: 10),
              _ServiceRecordHeader(event: event),
              const SizedBox(height: 10),
              _ServiceRecordDetails(event: event),
              const SizedBox(height: 10),
              _ServiceRecordActions(event: event),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceRecordActions extends StatelessWidget {
  const _ServiceRecordActions({required this.event});

  final MaintenanceServiceEvent event;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final record = _matchingRecord(state);
    if (record == null) {
      return const _UnavailableRecordNotice();
    }
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Open Item',
            compact: true,
            onPressed: () => Navigator.of(context).push(
              appNativeRoute<void>(
                context,
                MaintenanceItemDetailScreen(record: record),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppButton(
            label: 'Log Again',
            tone: AppButtonTone.commit,
            compact: true,
            onPressed: () => Navigator.of(context).push(
              appNativeRoute<void>(
                context,
                MaintenanceLogServiceScreen(records: [record]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  MaintenanceRecord? _matchingRecord(AppStateController state) {
    for (final record in state.maintenance) {
      if (record.vehicleName == event.vehicleName &&
          record.itemName == event.itemName) {
        return record;
      }
    }
    return null;
  }
}

class _UnavailableRecordNotice extends StatelessWidget {
  const _UnavailableRecordNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF151C1F),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5D6A71)),
      ),
      child: const Text(
        'This service record is saved, but the maintenance item is no longer tracked for this vehicle.',
        style: TextStyle(
          color: Color(0xFFE2E8EA),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

class _ServiceRecordHeader extends StatelessWidget {
  const _ServiceRecordHeader({required this.event});

  final MaintenanceServiceEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF111719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF4E5B62)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.build_circle_outlined,
            color: Color(0xFF4FE8FF),
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE7EEF1),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  event.vehicleName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFCAD2D5),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _dateLabel(event.serviceDate),
            style: const TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRecordDetails extends StatelessWidget {
  const _ServiceRecordDetails({required this.event});

  final MaintenanceServiceEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121A1E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF59636A)),
      ),
      child: Column(
        children: [
          _DetailLine(label: 'Date', value: _dateLabel(event.serviceDate)),
          _DetailLine(label: 'Odometer', value: formatMiles(event.odometer)),
          _DetailLine(
            label: 'Provider',
            value: event.provider.trim().isEmpty
                ? 'Not entered'
                : event.provider.trim(),
          ),
          _DetailLine(label: 'Cost', value: _moneyLabel(event.totalCost)),
          _DetailLine(
            label: 'Receipt Proof',
            value: event.receiptProofCount == 0
                ? 'Not attached'
                : '${event.receiptProofCount} attached',
          ),
          _DetailLine(
            label: 'Notes',
            value: event.notes.trim().isEmpty
                ? 'Not entered'
                : event.notes.trim(),
            multiline: true,
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 102,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFCAD2D5),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFFE7EEF1),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  return '${date.month}/${date.day}/${date.year}';
}

String _moneyLabel(double amount) {
  if (amount <= 0) return r'$0';
  return '\$${amount.toStringAsFixed(2)}';
}

String formatMiles(int value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().toString();
  final buffer = StringBuffer(sign);
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
