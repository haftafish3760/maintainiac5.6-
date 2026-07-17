import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maps/mapbox_test_screen.dart';
import 'package:maintaniac/shared/maps/mapbox_config.dart';

void main() {
  testWidgets('Mapbox test screen fails closed without a runtime token', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MapboxTestScreen(
          config: MaintainiacMapConfig(
            provider: MaintainiacMapProvider.mapbox,
            mapboxAccessToken: '',
          ),
        ),
      ),
    );

    expect(find.text('Mapbox public token required'), findsOneWidget);
    expect(
      find.textContaining('Trip tracking must continue to work'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('maintainiac-mapbox-test-map')),
      findsNothing,
    );
  });

  testWidgets('Mapbox test screen rejects secret runtime tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MapboxTestScreen(
          config: MaintainiacMapConfig(
            provider: MaintainiacMapProvider.mapbox,
            mapboxAccessToken: 'sk.secret-download-token',
          ),
        ),
      ),
    );

    expect(find.text('Mapbox public token required'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('maintainiac-mapbox-test-map')),
      findsNothing,
    );
  });
}
