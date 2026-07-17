enum MaintainiacMapProvider { none, mapbox }

class MaintainiacMapConfig {
  const MaintainiacMapConfig({
    required this.provider,
    required this.mapboxAccessToken,
  });

  factory MaintainiacMapConfig.fromEnvironment() {
    const providerName = String.fromEnvironment(
      'MAINTAINIAC_MAP_PROVIDER',
      defaultValue: 'none',
    );
    const token = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
    const accessToken = String.fromEnvironment('ACCESS_TOKEN');
    return MaintainiacMapConfig(
      provider: _providerFromName(providerName),
      mapboxAccessToken: token.isNotEmpty ? token : accessToken,
    );
  }

  final MaintainiacMapProvider provider;
  final String mapboxAccessToken;

  bool get mapsEnabled => provider != MaintainiacMapProvider.none;

  bool get hasMapboxToken => _isPublicMapboxToken(mapboxAccessToken);

  bool get canInitializeMapbox =>
      provider == MaintainiacMapProvider.mapbox && hasMapboxToken;

  String get statusLabel {
    if (provider == MaintainiacMapProvider.none) return 'Maps off';
    if (provider == MaintainiacMapProvider.mapbox && !hasMapboxToken) {
      return 'Mapbox public token required';
    }
    return 'Mapbox ready';
  }

  static MaintainiacMapProvider _providerFromName(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'mapbox' => MaintainiacMapProvider.mapbox,
      _ => MaintainiacMapProvider.none,
    };
  }
}

bool _isPublicMapboxToken(String value) {
  final token = value.trim();
  return token.startsWith('pk.') && !token.startsWith('sk.');
}
