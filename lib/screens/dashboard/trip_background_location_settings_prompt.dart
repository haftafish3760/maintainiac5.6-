import 'package:flutter/material.dart';

Future<bool> showTripBackgroundLocationSettingsPrompt(
  BuildContext context,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => const TripBackgroundLocationSettingsPrompt(),
    ) ??
    false;

class TripBackgroundLocationSettingsPrompt extends StatelessWidget {
  const TripBackgroundLocationSettingsPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Allow background GPS'),
      content: const Text(
        'Android requires you to choose “Allow all the time” in '
        'Maintainiac’s Location permission settings. Maintainiac cannot '
        'change this setting for you. Manual mileage remains available.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Open Android settings'),
        ),
      ],
    );
  }
}
