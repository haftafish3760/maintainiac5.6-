part of 'trip_tracking_settings_screen.dart';

String _samplingPresetLabel(TripTrackingSamplingPreset preset) =>
    switch (preset) {
      TripTrackingSamplingPreset.highAccuracy => 'High accuracy (2 sec)',
      TripTrackingSamplingPreset.enhancedAccuracy => 'Enhanced (8 sec)',
      TripTrackingSamplingPreset.balanced => 'Balanced (15 sec)',
      TripTrackingSamplingPreset.batterySaver => 'Battery saver (30 sec)',
      TripTrackingSamplingPreset.extremeOptimized =>
        'Extreme optimized (60 sec)',
      TripTrackingSamplingPreset.custom => 'Custom',
    };

String _profileLabel(TripTrackingProfile profile) => switch (profile) {
  TripTrackingProfile.roadVehicle => 'Road vehicle',
  TripTrackingProfile.rideshareVehicle => 'Rideshare / passenger driving',
  TripTrackingProfile.deliveryVehicle => 'Delivery driver',
  TripTrackingProfile.contractorVehicle => 'Contractor / service vehicle',
  TripTrackingProfile.lowSpeedEquipment => 'Low-speed equipment',
};

String _profileTrackingDetail(TripTrackingProfile profile) => switch (profile) {
  TripTrackingProfile.rideshareVehicle =>
    'Because you may stay in the vehicle, Maintainiac waits for clearer signs before suggesting a stop.',
  TripTrackingProfile.deliveryVehicle =>
    'After you stop driving and begin walking, Maintainiac can suggest a pickup or delivery stop for you to review.',
  TripTrackingProfile.contractorVehicle =>
    'After you stop driving and begin walking, Maintainiac can suggest a jobsite or supplier stop for you to review.',
  TripTrackingProfile.lowSpeedEquipment =>
    'Walking does not create stop suggestions while using the equipment profile.',
  TripTrackingProfile.roadVehicle =>
    'After driving, walking can suggest a possible stop for you to review.',
};
