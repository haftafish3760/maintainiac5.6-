// Source-owned Active Workday session detail opened from Calendar projections.

import 'package:flutter/material.dart';

import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_screen_shell.dart';
import 'data/active_workday_store.dart';

class ActiveWorkdaySessionDetailScreen extends StatelessWidget {
  const ActiveWorkdaySessionDetailScreen({required this.session, super.key});

  final ActiveWorkdaySessionRecord session;

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.dashboard,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const AppBackButton(),
          const SizedBox(height: 10),
          Text(
            'Workday detail',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          _DetailCard(label: 'Status', value: session.status.name),
          _DetailCard(label: 'Vehicle', value: session.vehicleLabel),
          _DetailCard(label: 'Work profile', value: session.workProfileId),
          _DetailCard(label: 'Started', value: _dateTime(session.startedAt)),
          if (session.endedAt != null)
            _DetailCard(label: 'Ended', value: _dateTime(session.endedAt!)),
          _DetailCard(
            label: 'Start odometer',
            value: '${session.startOdometer} mi',
          ),
          if (session.endOdometer != null)
            _DetailCard(
              label: 'End odometer',
              value: '${session.endOdometer} mi',
            ),
          const SizedBox(height: 12),
          Text(
            'Recorded timeline',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          if (session.events.isEmpty)
            const Text('No workday events were recorded.')
          else
            for (final event in session.events)
              _DetailCard(
                label: _dateTime(event.occurredAt),
                value: event.displayText,
              ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(title: Text(label), subtitle: Text(value)),
  );
}

String _dateTime(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
