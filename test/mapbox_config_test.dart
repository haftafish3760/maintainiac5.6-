import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/maps/mapbox_config.dart';

void main() {
  group('MaintainiacMapConfig', () {
    test('defaults maps off unless explicitly configured', () {
      final config = MaintainiacMapConfig.fromEnvironment();

      expect(config.provider, MaintainiacMapProvider.none);
      expect(config.mapsEnabled, isFalse);
      expect(config.canInitializeMapbox, isFalse);
      expect(config.statusLabel, 'Maps off');
    });

    test('fails closed when Mapbox is selected without a token', () {
      const config = MaintainiacMapConfig(
        provider: MaintainiacMapProvider.mapbox,
        mapboxAccessToken: '',
      );

      expect(config.mapsEnabled, isTrue);
      expect(config.hasMapboxToken, isFalse);
      expect(config.canInitializeMapbox, isFalse);
      expect(config.statusLabel, 'Mapbox token missing');
    });

    test('allows Mapbox initialization only with provider and token', () {
      const config = MaintainiacMapConfig(
        provider: MaintainiacMapProvider.mapbox,
        mapboxAccessToken: 'test-token-redacted',
      );

      expect(config.canInitializeMapbox, isTrue);
      expect(config.statusLabel, 'Mapbox ready');
    });
  });

  test('local Mapbox env files are ignored and not tracked', () async {
    final ignore = await File('.gitignore').readAsString();
    final trackedFiles = await Process.run('git', ['ls-files']);

    expect(ignore, contains('.env.*'));
    expect(ignore, contains('*.env'));
    expect('${trackedFiles.stdout}', isNot(contains('.env.mapbox')));
    expect('${trackedFiles.stdout}', isNot(contains('Mapbox_Token.env')));
  });
}
