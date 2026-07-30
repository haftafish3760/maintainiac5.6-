// Calendar ownership: the Calendar settings surface for Calendar presentation.
// Device notification permissions, channels, sounds, and speech stay device-service owned.

import 'package:flutter/material.dart';

import '../widgets/app_back_button.dart';
import 'calendar_flow_widgets.dart';
import 'calendar_preferences_store.dart';

class CalendarSettingsScreen extends StatelessWidget {
  const CalendarSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CalendarPreferencesScope.maybeOf(context);
    final preferences =
        controller?.preferences ?? const CalendarPresentationPreferences();

    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const AppScreenHeader(title: 'Calendar settings'),
            const SizedBox(height: 12),
            const CalendarStatusPanel(
              icon: Icons.tune_rounded,
              title: 'Calendar presentation',
              subtitle:
                  'These choices affect Calendar only. Records and source-screen settings stay where they belong.',
            ),
            const SizedBox(height: 14),
            const CalendarSectionTitle('WEEK STARTS ON'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _WeekStartChoice(
                  label: 'Sunday',
                  selected:
                      preferences.firstDayOfWeek ==
                      CalendarFirstDayOfWeek.sunday,
                  onSelected: controller == null
                      ? null
                      : () => controller.update(
                          firstDayOfWeek: CalendarFirstDayOfWeek.sunday,
                        ),
                ),
                _WeekStartChoice(
                  label: 'Monday',
                  selected:
                      preferences.firstDayOfWeek ==
                      CalendarFirstDayOfWeek.monday,
                  onSelected: controller == null
                      ? null
                      : () => controller.update(
                          firstDayOfWeek: CalendarFirstDayOfWeek.monday,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const CalendarSectionTitle('REVIEW SHORTCUTS'),
            const SizedBox(height: 8),
            _SettingsSwitch(
              title: 'Show review-required shortcuts',
              subtitle:
                  'Shows a compact action list above the full chronological timeline. The timeline always keeps every entry.',
              value: preferences.showReviewShortcuts,
              onChanged: controller == null
                  ? null
                  : (value) => controller.update(showReviewShortcuts: value),
            ),
            const SizedBox(height: 14),
            const CalendarStatusPanel(
              icon: Icons.notifications_none_rounded,
              title: 'Reminder delivery',
              subtitle:
                  'Schedules are saved here. Device notification permissions, sound, volume, and spoken alerts are configured by the notification service when it is connected.',
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekStartChoice extends StatelessWidget {
  const _WeekStartChoice({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected == null ? null : (_) => onSelected!(),
    selectedColor: const Color(0xFF1976B9),
    backgroundColor: const Color(0xFF2A3135),
    side: const BorderSide(color: Color(0xFF59636A)),
    labelStyle: const TextStyle(
      color: Color(0xFFE2E8EA),
      fontWeight: FontWeight.w800,
    ),
  );
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF2A3135),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: const Color(0xFF59636A)),
    ),
    child: SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeTrackColor: const Color(0xFF1976B9),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFE2E8EA),
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFFB7C4CA), height: 1.2),
      ),
    ),
  );
}
