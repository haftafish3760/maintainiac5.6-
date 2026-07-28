// Human-readable GPS sampling accuracy and battery guidance.
//
// Owns only the explanatory copy rendered below the sampling control. It does
// not choose sampling, request permission, or change tracking state. The GPS
// settings screen consumes this widget so users understand each interval.

import 'package:flutter/material.dart';

import '../../shared/trip_tracking/trip_tracking_settings_store.dart';

class TripTrackingSamplingExplanation extends StatelessWidget {
  const TripTrackingSamplingExplanation({super.key, required this.preset});

  final TripTrackingSamplingPreset preset;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF172023),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF445158)),
      ),
      child: Text(
        _detailFor(preset),
        style: const TextStyle(
          color: Color(0xFFE2E8EA),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    ),
  );

  String _detailFor(TripTrackingSamplingPreset value) => switch (value) {
    TripTrackingSamplingPreset.highAccuracy =>
      '2-second updates: strongest evidence for turns and short stops; highest battery use.',
    TripTrackingSamplingPreset.enhancedAccuracy =>
      '8-second updates: strong everyday evidence with moderate battery use.',
    TripTrackingSamplingPreset.balanced =>
      '15-second updates: balanced battery use; short turns and brief stops may be less precise.',
    TripTrackingSamplingPreset.batterySaver =>
      '30-second updates: lower battery use; route evidence and short-stop detection may be less precise.',
    TripTrackingSamplingPreset.extremeOptimized =>
      '60-second updates: lowest battery use; do not rely on it for tight route or brief-stop accuracy.',
    TripTrackingSamplingPreset.custom =>
      'Custom interval: longer intervals use less battery but can miss short turns and brief stops.',
  };
}
