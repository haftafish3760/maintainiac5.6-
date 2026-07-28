# Shared device capability system

Maintainiac has one device-local capability source under
`lib/shared/device_capabilities/`. It is independent of user accounts and
durable business data. Every signed-in device is measured from its own current
hardware and operating conditions.

## What it reports

- Hardware: platform, physical RAM, CPU cores/architecture, Android Media
  Performance Class, application heap, and emulator/physical-device status.
- Runtime: available RAM, free and total storage, power-saving mode, and thermal
  pressure.
- Cameras: front/rear availability, camera count, detailed logical lens type,
  physical-lens count, maximum still size, zoom, frame rate, autofocus,
  stabilization, RAW, depth, HDR, and torch support where the OS exposes it.
- Sensors: normalized availability for motion, heading, pressure, steps,
  proximity/light, environmental, and vendor-defined Android sensor types.
- Battery: current percentage, whether external power is connected, whether the
  battery is actively charging, source type, temperature, chemistry, and health
  where public. Android can distinguish USB, AC, and wireless power and may
  provide an explicitly unreliable full-capacity estimate. iOS exposes only
  external-power/charging state; charger type, battery size, chemistry, and
  health remain unknown instead of being guessed.
- Display: physical pixel dimensions, density scale, maximum refresh rate, HDR,
  and wide-color support.
- Media and graphics: hardware video codecs, OpenGL ES/Vulkan or Metal feature
  level, compute support, and ray-tracing support where reliably queryable.
- Connectivity: connection state, normalized transport, metered/constrained
  state, and Android link-bandwidth estimates. Wi-Fi names, addresses, carrier
  identity, and network identifiers are never collected.

## Using it from any module

Import the barrel file and read the shared profile:

```dart
import 'package:maintaniac/shared/device_capabilities/device_capabilities.dart';

final controller = DeviceCapabilityScope.of(context);
final profile = controller.profile;
final freeStorageMb = profile?.runtime.freeStorageMb;
final hardwareGrade = profile?.baselineGrade; // 1 through 10
final currentGrade = profile?.effectiveGrade; // May drop under live pressure
final pluggedIn = profile?.extended.battery.isExternalPowerConnected;
final sensors = profile?.extended.sensors;
final lenses = profile?.extended.cameraLenses;
final policy = profile?.operationalPolicy;
```

Before an expensive operation, refresh changing conditions:

```dart
await DeviceCapabilityScope.refreshForHeavyWork(context);
final policy = DeviceCapabilityScope.of(context).profile?.operationalPolicy;
```

The app also refreshes automatically on foreground resume and debounced native
battery, power, thermal, and network events. Stable hardware facts remain
cached. Modules must treat nullable/unknown values conservatively.

## Operational policy

`DeviceOperationalPolicy` translates the effective device tier and current
pressure into reusable module guidance:

- camera/OCR live-analysis frame rate;
- maximum OCR image batch size;
- maximum camera megapixels to process at once;
- PDF raster DPI;
- trip-location sampling interval;
- preferred hardware video codec;
- whether to defer nonessential heavy work; and
- whether a large network transfer is currently appropriate.

The policy lowers work for low storage, low unplugged battery, power saving,
thermal pressure, low available memory, and constrained/metered connectivity.
Model name and release year never increase a device's tier.

The six stable workload tiers remain the module-policy contract. A finer 1-10
grade is also reported for commercial device-range decisions: grade 1 is the
minimum supported capability and grade 10 is verified flagship-class hardware.
The baseline grade describes hardware; the effective grade can only decrease
under storage, memory, power-saving, battery, or thermal pressure.

## Privacy and diagnostics

`toPrivacySafeDiagnostics()` omits hardware identifiers, model names, exact RAM,
exact storage, Wi-Fi details, and raw sensor readings. It returns coarse classes
appropriate for future crash-diagnostic metadata. Capability detection does not
read sensor samples and does not request camera, motion, or location permission.

## Platform limitations

Android vendors may expose a logical multi-camera instead of every physical
camera independently. Apple exposes named camera device types but intentionally
hides battery design capacity and health. Unsupported or unreliable facts stay
unknown; they must never be inferred from marketing names or release year.
