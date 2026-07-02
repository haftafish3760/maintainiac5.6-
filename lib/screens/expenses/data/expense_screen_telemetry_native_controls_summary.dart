part of 'expense_screen_telemetry.dart';

class _ExpenseTelemetryNativeControlsSummary {
  var tapFocusExpectedCount = 0;
  var pinchZoomExpectedCount = 0;
  var exposureSliderExpectedCount = 0;
  var exposureResetExpectedCount = 0;
  var settingsExpectedCount = 0;
  var backExpectedCount = 0;
  var torchExpectedCount = 0;
  var settingsOpenCount = 0;
  var zoomGestureStartCount = 0;
  var zoomChangeCount = 0;
  var zoomUnavailableCount = 0;

  final _zoomStatusCounts = <String, int>{};
  final _backDispatchPathCounts = <String, int>{};

  Map<String, int> get zoomStatusCounts => Map.unmodifiable(_zoomStatusCounts);

  Map<String, int> get backDispatchPathCounts =>
      Map.unmodifiable(_backDispatchPathCounts);

  String get topZoomStatus => _topCountKey(_zoomStatusCounts);

  String get topBackDispatchPath => _topCountKey(_backDispatchPathCounts);

  void record(Map<String, Object?> metadata) {
    tapFocusExpectedCount += _intValue(
      metadata['tapFocusControlExpectedCount'],
    );
    pinchZoomExpectedCount += _intValue(
      metadata['pinchZoomControlExpectedCount'],
    );
    exposureSliderExpectedCount += _intValue(
      metadata['exposureSliderControlExpectedCount'],
    );
    exposureResetExpectedCount += _intValue(
      metadata['exposureResetControlExpectedCount'],
    );
    settingsExpectedCount += _intValue(
      metadata['settingsControlExpectedCount'],
    );
    backExpectedCount += _intValue(metadata['backControlExpectedCount']);
    torchExpectedCount += _intValue(metadata['torchControlExpectedCount']);
    settingsOpenCount += _intValue(metadata['settingsOpenTotal']);
    zoomGestureStartCount += _intValue(metadata['zoomGestureStartTotal']);
    zoomChangeCount += _intValue(metadata['zoomChangeTotal']);
    zoomUnavailableCount += _intValue(metadata['zoomUnavailableTotal']);
    _mergeCountMap(
      _zoomStatusCounts,
      _metadataValue(metadata['zoomStatusBuckets']),
    );
    _mergeCountMap(
      _backDispatchPathCounts,
      _metadataValue(metadata['backDispatchPathBuckets']),
    );
  }
}
