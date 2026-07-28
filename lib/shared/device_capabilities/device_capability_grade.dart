class DeviceCapabilityGradeScale {
  const DeviceCapabilityGradeScale._();

  /// Converts the measured hardware score into a stable 1-10 grade.
  static int fromScore(int score) => switch (score) {
    <= -3 => 1,
    <= -1 => 2,
    <= 1 => 3,
    <= 3 => 4,
    <= 5 => 5,
    <= 7 => 6,
    <= 9 => 7,
    <= 11 => 8,
    <= 13 => 9,
    _ => 10,
  };

  static int maximumForTierIndex(int tierIndex) => switch (tierIndex) {
    <= 0 => 2,
    1 => 3,
    2 => 5,
    3 => 6,
    4 => 8,
    _ => 10,
  };

  static int capForTier(int grade, int tierIndex) =>
      grade.clamp(1, maximumForTierIndex(tierIndex));

  static String label(int grade) => switch (grade.clamp(1, 10)) {
    1 => 'minimum',
    2 => 'constrained',
    3 => 'entry',
    4 => 'basic',
    5 => 'balanced',
    6 => 'enhanced',
    7 => 'performance',
    8 => 'highPerformance',
    9 => 'premium',
    _ => 'flagship',
  };
}
