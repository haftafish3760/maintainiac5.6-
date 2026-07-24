import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'mapbox_config.dart';

class MaintainiacMapRuntime {
  const MaintainiacMapRuntime._();

  static bool initializeFromEnvironment() {
    final config = MaintainiacMapConfig.fromEnvironment();
    if (!config.canInitializeMapbox) return false;
    MapboxOptions.setAccessToken(config.sanitizedMapboxAccessToken);
    return true;
  }
}
