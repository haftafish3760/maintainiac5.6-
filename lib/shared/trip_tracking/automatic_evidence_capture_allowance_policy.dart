// Monthly entitlement decisions for automatic evidence capture.
//
// Owns deterministic free-versus-paid allowance decisions and period keys.
// It does not persist counters, start trips, accept proposals, or charge users.
// Automatic-start detection consumes this policy; the separately owned durable
// layer supplies accepted-use counts. A free use is consumed only after the
// user accepts a recovered-workday proposal.

enum AutomaticEvidenceCaptureAccess { free, paid }

class AutomaticEvidenceCaptureAllowanceDecision {
  const AutomaticEvidenceCaptureAllowanceDecision({
    required this.allowed,
    required this.periodKey,
    required this.freeLimit,
    required this.acceptedFreeUses,
    required this.freeUsesRemaining,
    required this.consumesFreeUseIfAccepted,
    required this.reasonCode,
  });

  final bool allowed;
  final String periodKey;
  final int freeLimit;
  final int acceptedFreeUses;
  final int freeUsesRemaining;
  final bool consumesFreeUseIfAccepted;
  final String reasonCode;

  bool get consumesOnDetection => false;
  bool get consumesOnRejection => false;
  bool get canStartTrip => false;
  bool get requiresUserApproval => true;

  Map<String, Object?> toSafeMap() => {
    'schemaVersion': 1,
    'allowed': allowed,
    'periodKey': periodKey,
    'freeLimit': freeLimit,
    'acceptedFreeUses': acceptedFreeUses,
    'freeUsesRemaining': freeUsesRemaining,
    'consumesFreeUseIfAccepted': consumesFreeUseIfAccepted,
    'consumesOnDetection': false,
    'consumesOnRejection': false,
    'canStartTrip': false,
    'requiresUserApproval': true,
    'reasonCode': reasonCode,
  };
}

class AutomaticEvidenceCaptureAllowancePolicy {
  const AutomaticEvidenceCaptureAllowancePolicy({this.freeMonthlyLimit = 4});

  final int freeMonthlyLimit;

  AutomaticEvidenceCaptureAllowanceDecision evaluate({
    required AutomaticEvidenceCaptureAccess access,
    required DateTime occurredAt,
    required int acceptedFreeUsesInPeriod,
  }) {
    final safeLimit = freeMonthlyLimit < 0 ? 0 : freeMonthlyLimit;
    final safeUsed = acceptedFreeUsesInPeriod < 0
        ? 0
        : acceptedFreeUsesInPeriod;
    final periodKey = automaticEvidenceCapturePeriodKey(occurredAt);
    if (access == AutomaticEvidenceCaptureAccess.paid) {
      return AutomaticEvidenceCaptureAllowanceDecision(
        allowed: true,
        periodKey: periodKey,
        freeLimit: safeLimit,
        acceptedFreeUses: safeUsed,
        freeUsesRemaining: safeLimit,
        consumesFreeUseIfAccepted: false,
        reasonCode: 'paid_automatic_evidence_capture_available',
      );
    }
    final remaining = (safeLimit - safeUsed).clamp(0, safeLimit).toInt();
    return AutomaticEvidenceCaptureAllowanceDecision(
      allowed: remaining > 0,
      periodKey: periodKey,
      freeLimit: safeLimit,
      acceptedFreeUses: safeUsed,
      freeUsesRemaining: remaining,
      consumesFreeUseIfAccepted: remaining > 0,
      reasonCode: remaining > 0
          ? 'free_recovery_available'
          : 'free_recovery_allowance_used',
    );
  }
}

String automaticEvidenceCapturePeriodKey(DateTime occurredAt) {
  final utc = occurredAt.toUtc();
  return '${utc.year.toString().padLeft(4, '0')}-${utc.month.toString().padLeft(2, '0')}';
}
