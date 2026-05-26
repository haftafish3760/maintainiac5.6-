import 'package:flutter/material.dart';

import 'app_back_button.dart';
import 'odometer_entry_sheet.dart';

class FlowPlaceholderScreen extends StatelessWidget {
  const FlowPlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.summary,
    this.details = const [],
    this.requiresOdometer = false,
  });

  final String title;
  final IconData icon;
  final String summary;
  final List<String> details;
  final bool requiresOdometer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),

      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
          children: [
            AppScreenHeader(title: title),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFAAB4B9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF101416), width: 1.3),
              ),
              child: Column(
                children: [
                  Icon(icon, color: const Color(0xFF101416), size: 36),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF101416),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2F383D),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (final detail in details) _FlowDetailRow(text: detail),
            ],
            const SizedBox(height: 14),
            if (requiresOdometer)
              FilledButton.icon(
                onPressed: () => _openOdometerEntry(context),
                icon: const Icon(Icons.speed_rounded),
                label: const Text('Enter Odometer'),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _openOdometerEntry(context),
                icon: const Icon(Icons.speed_rounded),
                label: const Text('Update Odometer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE2E8EA),
                  side: const BorderSide(color: Color(0xFF59636A)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openOdometerEntry(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2E3A40),
      builder: (_) => OdometerEntrySheet(
        title: requiresOdometer
            ? 'Odometer Required'
            : 'Update Global Odometer',
        saveLabel: 'Save Reading',
      ),
    );
  }
}

class _FlowDetailRow extends StatelessWidget {
  const _FlowDetailRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF151B1E),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF3E4A50)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFE2E8EA),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.22,
        ),
      ),
    );
  }
}
