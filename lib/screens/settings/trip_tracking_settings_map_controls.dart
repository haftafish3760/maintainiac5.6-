part of 'trip_tracking_settings_screen.dart';

extension _TripTrackingSettingsMapControls on _TripTrackingSettingsPanel {
  Widget _mapRouteHistoryControls(TripTrackingSettings settings) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: _rowDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingText(
            title: 'Map route storage limits',
            detail:
                'Free users choose how much optional route preview data to keep. Raw route geometry is not mirrored in dashboard summaries.',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _smallNumberField(
                  key: const Key('mapRouteHistoryDailyBudgetMb'),
                  label: 'Daily MB',
                  initialValue: _formatMapBudget(_defaultMapBudgetMb(settings)),
                  onSubmitted: (value) {
                    final mb = double.tryParse(value);
                    if (mb != null) {
                      onChanged(
                        settings.copyWith(mapRouteHistoryDailyBudgetMb: mb),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _smallNumberField(
                  key: const Key('mapRouteHistorySampleIntervalSeconds'),
                  label: 'Sample seconds',
                  initialValue: '${_defaultMapSampleIntervalSeconds(settings)}',
                  onSubmitted: (value) {
                    final seconds = int.tryParse(value);
                    if (seconds != null) {
                      onChanged(
                        settings.copyWith(
                          mapRouteHistorySampleIntervalSeconds: seconds,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _smallNumberField({
    required Key key,
    required String label,
    required String initialValue,
    required ValueChanged<String> onSubmitted,
  }) => TextFormField(
    key: key,
    initialValue: initialValue,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFFCAD2D5),
        fontWeight: FontWeight.w800,
      ),
      isDense: true,
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF445158)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE2E8EA)),
      ),
    ),
    style: const TextStyle(
      color: Color(0xFFE2E8EA),
      fontWeight: FontWeight.w800,
    ),
    onFieldSubmitted: onSubmitted,
  );
}

double _defaultMapBudgetMb(TripTrackingSettings settings) =>
    settings.mapRouteHistoryDailyBudgetMb > 0
    ? settings.mapRouteHistoryDailyBudgetMb
    : 1;

int _defaultMapSampleIntervalSeconds(TripTrackingSettings settings) =>
    settings.mapRouteHistorySampleIntervalSeconds < 15
    ? 30
    : settings.mapRouteHistorySampleIntervalSeconds;

String _formatMapBudget(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
