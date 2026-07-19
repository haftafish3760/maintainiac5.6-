import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_feature_capability_parser.dart';

void main() {
  const parser = DeviceFeatureCapabilityParser();

  test('parses normalized extended capability sections', () {
    final result = parser.parse({
      'cameraLenses': [
        {
          'position': 'rear',
          'lensType': 'ultrawide',
          'physicalLensCount': 2,
          'maxStillWidth': 8000,
          'maxStillHeight': 6000,
          'maxDigitalZoom': 10.0,
          'supportsAutofocus': true,
          'supportsStabilization': true,
        },
      ],
      'sensors': {
        'sensorCount': 6,
        'types': [
          'accelerometer',
          'gyroscope',
          'barometer',
          'step_counter',
          'walking_cadence',
          'stationary_detect',
        ],
        'permissionGatedTypes': ['heart_rate'],
      },
      'battery': {
        'levelPercent': 19,
        'isCharging': true,
        'powerSource': 'usb',
        'health': 'good',
        'estimatedFullCapacityMah': 4100,
        'capacityEstimateReliable': false,
      },
      'display': {
        'widthPixels': 1440,
        'heightPixels': 3120,
        'densityScale': 3.5,
        'maxRefreshRateHz': 120,
        'supportsHdr': true,
      },
      'media': {
        'hardwareDecodeTypes': ['h264', 'hevc', 'av1'],
        'hardwareEncodeTypes': ['h264', 'hevc'],
      },
      'graphics': {
        'apiName': 'vulkan+opengl_es',
        'apiVersion': '3.2',
        'featureLevel': 'vulkan_4202496',
        'supportsCompute': true,
      },
      'connectivity': {
        'transports': ['wifi'],
        'isConnected': true,
        'isMetered': false,
        'isConstrained': false,
        'downstreamKbps': 120000,
      },
    });

    expect(result.cameraLenses.single.lensType, 'ultrawide');
    expect(result.cameraLenses.single.maxStillMegapixels, 48);
    expect(result.sensors.hasMotion, isTrue);
    expect(result.sensors.hasPressure, isTrue);
    expect(result.sensors.hasExerciseSignals, isTrue);
    expect(result.sensors.hasMotionStateTransitions, isTrue);
    expect(result.sensors.hasBodySignals, isTrue);
    expect(result.battery.isLow, isTrue);
    expect(result.battery.powerSource.name, 'usb');
    expect(result.display.maxRefreshRateHz, 120);
    expect(result.media.canHardwareDecode('av1'), isTrue);
    expect(result.graphics.supportsCompute, isTrue);
    expect(result.connectivity.permitsLargeTransfer, isTrue);
  });

  test('rejects invalid native values instead of inventing capabilities', () {
    final result = parser.parse({
      'battery': {
        'levelPercent': 110,
        'remainingChargeMah': -1,
        'health': 'not-a-health',
      },
      'display': {'maxRefreshRateHz': -60},
      'cameraLenses': 'invalid',
    });

    expect(result.battery.levelPercent, isNull);
    expect(result.battery.remainingChargeMah, isNull);
    expect(result.battery.health.name, 'unknown');
    expect(result.display.maxRefreshRateHz, 0);
    expect(result.cameraLenses, isEmpty);
  });
}
