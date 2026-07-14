import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../shared/firebase/maintainiac_auth_service.dart';
import '../../shared/trip_tracking/trip_tracking_models.dart';
import '../../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../../shared/profiles/user_profile_store.dart';
import '../../shared/widgets/app_screen_shell.dart';

/// Shared preference surface opened from both Dashboard Settings and Menu.
class TripTrackingSettingsScreen extends StatelessWidget {
  const TripTrackingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TripTrackingSettingsScope.of(context);
    final settings = controller.settings;
    final userProfiles = UserProfileScope.maybeOf(context);
    return AppScreenShell(
      section: AppSection.dashboard,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 22),
        children: [
          const GlobalOdometerHeader(),
          const SizedBox(height: 12),
          if (Firebase.apps.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: _FirebaseBackupAccountPanel(),
            ),
            const SizedBox(height: 8),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _TripTrackingSettingsPanel(
              settings: settings,
              onChanged: controller.update,
              cloudBackupEnabled:
                  userProfiles?.activeProfile.cloudBackupEnabled ?? false,
              onCloudBackupChanged: userProfiles == null
                  ? null
                  : (enabled) => userProfiles.saveActiveProfile(
                      userProfiles.activeProfile.copyWith(
                        cloudBackupEnabled: enabled,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FirebaseBackupAccountPanel extends StatefulWidget {
  const _FirebaseBackupAccountPanel();

  @override
  State<_FirebaseBackupAccountPanel> createState() =>
      _FirebaseBackupAccountPanelState();
}

class _FirebaseBackupAccountPanelState
    extends State<_FirebaseBackupAccountPanel> {
  final _authService = MaintainiacAuthService();
  var _busy = false;
  String? _error;

  Future<void> _run(Future<UserCredential> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _authService.signOut();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      initialData: _authService.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF172023),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF5D6A71)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Firebase backup account',
                style: TextStyle(
                  color: Color(0xFFE2E8EA),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                user == null
                    ? 'Sign in only if you want reviewed mileage backup. This never enables backup by itself.'
                    : 'Signed in as ${user.email ?? user.displayName ?? user.uid}. Backup remains separately opt-in below.',
                style: const TextStyle(
                  color: Color(0xFFCAD2D5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFFFB4AB),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 7),
              if (user == null)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _run(_authService.signInWithGoogle),
                      child: Text(
                        _busy ? 'SIGNING IN…' : 'SIGN IN WITH GOOGLE',
                      ),
                    ),
                    if (_authService.canShowAppleSignIn)
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _run(_authService.signInWithApple),
                        child: const Text('SIGN IN WITH APPLE'),
                      ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _signOut,
                    child: Text(_busy ? 'SIGNING OUT…' : 'SIGN OUT'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TripTrackingSettingsPanel extends StatelessWidget {
  const _TripTrackingSettingsPanel({
    required this.settings,
    required this.onChanged,
    required this.cloudBackupEnabled,
    required this.onCloudBackupChanged,
  });

  final TripTrackingSettings settings;
  final ValueChanged<TripTrackingSettings> onChanged;
  final bool cloudBackupEnabled;
  final ValueChanged<bool>? onCloudBackupChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF172023),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5D6A71)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'GPS-Assisted Trip Tracking',
            style: TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Location stays on this device for active-trip recovery and review. It does not start until you choose Start GPS Trip.',
            style: TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _switch(
            title: 'Back up reviewed mileage to Firebase',
            detail:
                'Off by default. Turning it off cancels unsent backup. Only reviewed mileage summaries are backed up; GPS coordinates, routes, raw samples, and live location never leave this device.',
            value: cloudBackupEnabled,
            onChanged: onCloudBackupChanged ?? (_) {},
          ),
          _switch(
            title: 'Share reviewed mileage summaries with organization',
            detail:
                'Off by default. Turn this on only when you agree to share reviewed mileage totals with your organization. GPS coordinates, routes, and live location are never shared.',
            value: settings.organizationMileageSharingEnabled,
            onChanged: (value) => onChanged(
              settings.copyWith(organizationMileageSharingEnabled: value),
            ),
          ),
          _switch(
            title: 'Enable GPS-assisted tracking',
            detail:
                'Keep the manual trip and odometer workflow available even when this is off.',
            value: settings.gpsAssistedTrackingEnabled,
            onChanged: (value) =>
                onChanged(settings.copyWith(gpsAssistedTrackingEnabled: value)),
          ),
          _switch(
            title: 'Continue during an active background trip',
            detail:
                'Off by default. Without it, GPS stops when the app is backgrounded. Requests the extra location permission only when you start a trip with this enabled.',
            value: settings.backgroundTrackingEnabled,
            onChanged: (value) =>
                onChanged(settings.copyWith(backgroundTrackingEnabled: value)),
          ),
          _choice<TripTrackingSamplingPreset>(
            title: 'GPS update preset',
            value: settings.samplingPreset,
            items: TripTrackingSamplingPreset.values,
            label: _samplingPresetLabel,
            onChanged: (value) =>
                onChanged(settings.copyWith(samplingPreset: value)),
          ),
          if (settings.samplingPreset == TripTrackingSamplingPreset.custom)
            _customInterval(settings),
          _switch(
            title: 'Adaptive GPS sampling',
            detail:
                'Let the tracker temporarily adjust the selected interval when movement evidence supports it.',
            value: settings.adaptiveSamplingEnabled,
            onChanged: (value) =>
                onChanged(settings.copyWith(adaptiveSamplingEnabled: value)),
          ),
          _choice<TripTrackingProfile>(
            title: 'Default tracking profile',
            value: settings.defaultProfile,
            items: TripTrackingProfile.values,
            label: _profileLabel,
            onChanged: (value) =>
                onChanged(settings.copyWith(defaultProfile: value)),
          ),
          _switch(
            title: 'Walking-transition review',
            detail:
                'When motion evidence is available, flag likely walking rather than silently counting it as vehicle distance.',
            value: settings.walkingTransitionReviewEnabled,
            onChanged: (value) => onChanged(
              settings.copyWith(walkingTransitionReviewEnabled: value),
            ),
          ),
          _switch(
            title: 'Recognize a linked vehicle by Bluetooth',
            detail:
                'Uses only Bluetooth devices you explicitly link to a vehicle on this device.',
            value: settings.bluetoothVehicleRecognitionEnabled,
            onChanged: (value) => onChanged(
              settings.copyWith(bluetoothVehicleRecognitionEnabled: value),
            ),
          ),
          _switch(
            title: 'Automatically switch the active vehicle',
            detail:
                'Never switches while a GPS trip is active. Otherwise, a linked device can select its vehicle.',
            value: settings.automaticVehicleSwitchEnabled,
            onChanged: settings.bluetoothVehicleRecognitionEnabled
                ? (value) => onChanged(
                    settings.copyWith(automaticVehicleSwitchEnabled: value),
                  )
                : (_) {},
          ),
        ],
      ),
    );
  }

  Widget _switch({
    required String title,
    required String detail,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
      decoration: _rowDecoration,
      child: Row(
        children: [
          Expanded(
            child: _SettingText(title: title, detail: detail),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    ),
  );

  Widget _choice<T>({
    required String title,
    required T value,
    required List<T> items,
    required String Function(T) label,
    required ValueChanged<T> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: _rowDecoration,
      child: Row(
        children: [
          Expanded(child: Text(title, style: _titleStyle)),
          const SizedBox(width: 8),
          DropdownButton<T>(
            value: value,
            dropdownColor: const Color(0xFF202A2E),
            underline: const SizedBox.shrink(),
            style: const TextStyle(
              color: Color(0xFFE2E8EA),
              fontWeight: FontWeight.w800,
            ),
            items: [
              for (final item in items)
                DropdownMenuItem(value: item, child: Text(label(item))),
            ],
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ],
      ),
    ),
  );

  Widget _customInterval(TripTrackingSettings settings) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: _rowDecoration,
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Custom update interval (3–600 sec)',
              style: _titleStyle,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: TextFormField(
              key: const Key('gpsCustomIntervalSeconds'),
              initialValue: '${settings.customIntervalSeconds}',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFFE2E8EA),
                fontWeight: FontWeight.w800,
              ),
              onFieldSubmitted: (value) {
                final seconds = int.tryParse(value);
                if (seconds != null) {
                  onChanged(settings.copyWith(customIntervalSeconds: seconds));
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}

const _rowDecoration = BoxDecoration(
  color: Color(0xFF202A2E),
  borderRadius: BorderRadius.all(Radius.circular(5)),
  border: Border.fromBorderSide(BorderSide(color: Color(0xFF445158))),
);

const _titleStyle = TextStyle(
  color: Color(0xFFE2E8EA),
  fontSize: 14,
  fontWeight: FontWeight.w900,
);

class _SettingText extends StatelessWidget {
  const _SettingText({required this.title, required this.detail});
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: _titleStyle),
      const SizedBox(height: 3),
      Text(
        detail,
        style: const TextStyle(
          color: Color(0xFFCAD2D5),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.18,
        ),
      ),
    ],
  );
}

String _samplingPresetLabel(TripTrackingSamplingPreset preset) =>
    switch (preset) {
      TripTrackingSamplingPreset.highAccuracy => 'High accuracy (3 sec)',
      TripTrackingSamplingPreset.enhancedAccuracy => 'Enhanced (8 sec)',
      TripTrackingSamplingPreset.balanced => 'Balanced (15 sec)',
      TripTrackingSamplingPreset.batterySaver => 'Battery saver (30 sec)',
      TripTrackingSamplingPreset.extremeOptimized =>
        'Extreme optimized (60 sec)',
      TripTrackingSamplingPreset.custom => 'Custom',
    };

String _profileLabel(TripTrackingProfile profile) => switch (profile) {
  TripTrackingProfile.roadVehicle => 'Road vehicle',
  TripTrackingProfile.lowSpeedEquipment => 'Low-speed equipment',
};
