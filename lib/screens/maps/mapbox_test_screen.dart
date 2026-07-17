import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../shared/maps/mapbox_config.dart';

class MapboxTestScreen extends StatefulWidget {
  const MapboxTestScreen({
    super.key,
    this.config = const MaintainiacMapConfig(
      provider: MaintainiacMapProvider.none,
      mapboxAccessToken: '',
    ),
  });

  final MaintainiacMapConfig config;

  @override
  State<MapboxTestScreen> createState() => _MapboxTestScreenState();
}

class _MapboxTestScreenState extends State<MapboxTestScreen> {
  @override
  void initState() {
    super.initState();
    _configureMapboxIfReady();
  }

  @override
  void didUpdateWidget(covariant MapboxTestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.mapboxAccessToken != widget.config.mapboxAccessToken ||
        oldWidget.config.provider != widget.config.provider) {
      _configureMapboxIfReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    return Scaffold(
      appBar: AppBar(title: const Text('Mapbox test map')),
      body: config.canInitializeMapbox
          ? MapWidget(
              key: const ValueKey('maintainiac-mapbox-test-map'),
              viewport: CameraViewportState(
                center: Point(coordinates: Position(-98.0, 39.5)),
                zoom: 2,
                bearing: 0,
                pitch: 0,
              ),
            )
          : _MapboxNotConfigured(statusLabel: config.statusLabel),
    );
  }

  void _configureMapboxIfReady() {
    final config = widget.config;
    if (!config.canInitializeMapbox) return;
    MapboxOptions.setAccessToken(config.sanitizedMapboxAccessToken);
  }
}

class _MapboxNotConfigured extends StatelessWidget {
  const _MapboxNotConfigured({required this.statusLabel});

  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              statusLabel,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Maps are optional. Trip tracking must continue to work even '
              'when Mapbox is not configured.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
