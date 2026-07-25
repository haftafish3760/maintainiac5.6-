import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app supervises active native tracking while foregrounded', () {
    final source = File('lib/app/maintaniac_app.dart').readAsStringSync();
    final appTree = File('lib/main.dart').readAsStringSync();

    expect(source, contains('Timer.periodic('));
    expect(source, contains('_tripHeartbeatCheckInterval'));
    expect(source, contains('_appLifecycleState != AppLifecycleState.resumed'));
    expect(source, contains('_tripHeartbeatCheckInFlight'));
    expect(source, contains('!tripTracking.nativeTracking'));
    expect(source, contains('await tripTracking.checkNativeHeartbeat()'));
    expect(source, contains('_tripHeartbeatTimer?.cancel()'));
    expect(appTree.indexOf('TripTrackingScope('), greaterThanOrEqualTo(0));
    expect(
      appTree.indexOf('TripTrackingScope('),
      lessThan(appTree.indexOf('const MaintaniacApp()')),
    );
  });
}
