import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_capability.dart';
import 'package:maintaniac/shared/device_capabilities/device_capability_grade.dart';

void main() {
  test('grade scale covers every commercial capability grade', () {
    final grades = <int>{
      for (var score = -4; score <= 15; score++)
        DeviceCapabilityGradeScale.fromScore(score),
    };

    expect(grades, containsAll(List<int>.generate(10, (index) => index + 1)));
  });

  test('runtime tier can lower but never raise the hardware grade', () {
    final profile = DeviceCapabilityProfile(
      hardware: const DeviceHardwareSnapshot(platform: 'android'),
      runtime: DeviceRuntimeSnapshot(observedAt: DateTime.utc(2026, 7, 23)),
      camera: const DeviceCameraCapabilities(),
      baselineTier: DevicePerformanceTier.flagship,
      tier: DevicePerformanceTier.entry,
      confidence: DeviceCapabilityConfidence.high,
      score: 15,
      limitingFactors: const ['power_saving'],
    );

    expect(profile.baselineGrade, 10);
    expect(profile.effectiveGrade, 3);
    expect(profile.effectiveGradeLabel, 'entry');
  });
}
