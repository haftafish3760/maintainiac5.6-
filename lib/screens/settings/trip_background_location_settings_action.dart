import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../dashboard/trip_background_location_settings_prompt.dart';

class TripBackgroundLocationSettingsAction extends StatelessWidget {
  const TripBackgroundLocationSettingsAction({
    super.key,
    required this.onOpenSettings,
    this.platform,
  });

  final Future<bool> Function() onOpenSettings;
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context) {
    if ((platform ?? defaultTargetPlatform) != TargetPlatform.android) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: () => _openSettings(context),
        icon: const Icon(Icons.settings_outlined),
        label: const Text('Review Android background permission'),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    final confirmed = await showTripBackgroundLocationSettingsPrompt(context);
    if (!confirmed || !context.mounted) return;
    final opened = await onOpenSettings();
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Android settings could not be opened. Manual mileage is still available.',
          ),
        ),
      );
    }
  }
}
