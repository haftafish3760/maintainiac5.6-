import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app startup initializes only validated environment Mapbox config', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final runtimeSource = File(
      'lib/shared/maps/mapbox_runtime.dart',
    ).readAsStringSync();

    expect(
      mainSource,
      contains('MaintainiacMapRuntime.initializeFromEnvironment();'),
    );
    expect(runtimeSource, contains('MaintainiacMapConfig.fromEnvironment()'));
    expect(runtimeSource, contains('if (!config.canInitializeMapbox)'));
    expect(
      runtimeSource,
      contains(
        'MapboxOptions.setAccessToken(config.sanitizedMapboxAccessToken)',
      ),
    );
    expect(runtimeSource, isNot(contains('print(')));
    expect(runtimeSource, isNot(contains('sk.')));
  });
}
