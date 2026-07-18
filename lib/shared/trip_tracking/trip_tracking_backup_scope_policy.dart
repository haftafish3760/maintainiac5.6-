import 'trip_tracking_session_store.dart';

enum TripTrackingBackupScopeFailure {
  unsafeAccount,
  accountMismatch,
  missingOrganization,
  scopeMismatch,
}

class TripTrackingBackupScopeDecision {
  const TripTrackingBackupScopeDecision._({
    required this.boundReview,
    required this.failure,
  });

  const TripTrackingBackupScopeDecision.allowed(TripTrackingReviewRecord review)
    : this._(boundReview: review, failure: null);

  const TripTrackingBackupScopeDecision.rejected(
    TripTrackingBackupScopeFailure failure,
  ) : this._(boundReview: null, failure: failure);

  final TripTrackingReviewRecord? boundReview;
  final TripTrackingBackupScopeFailure? failure;

  bool get canQueue => boundReview != null && failure == null;

  Map<String, Object?> toSafeSummary() {
    final review = boundReview;
    final scope = review?.cloudBackupScope;
    final safeCanQueue = _safeCanQueue(review: review, failure: failure);
    final hasOrganizationBinding =
        scope == TripTrackingCloudBackupScope.organization &&
        TripTrackingBackupScopePolicy.hasUsableOrganizationId(
          review?.cloudOrganizationId,
        );
    return {
      'schemaVersion': 1,
      'canQueue': safeCanQueue,
      'scope': safeCanQueue ? scope?.name ?? 'unbound' : 'unbound',
      'failure': failure?.name,
      'requiresReview': !safeCanQueue,
      'safeErrorMessage': safeErrorMessage,
      'accountBound': TripTrackingBackupScopePolicy.isSafeCloudToken(
        review?.cloudAccountUid,
      ),
      'organizationBound': hasOrganizationBinding,
      'authorizationRequired': true,
      'authenticationImpliesAuthorization': false,
      'ownershipVerifiedBeforeWrite': safeCanQueue,
      'scopeBindingRequiredBeforeWrite': true,
      'backupConsentRequiredBeforeWrite': true,
      'organizationSharingConsentRequiredBeforeFleetVisibility': true,
      'queueAllowedAfterValidationOnly': true,
      'firestoreRulesMustVerifyOwner': true,
      'cloudFunctionMustVerifyOwnerAndScope': true,
      'cloudMirrorOnly': true,
      'hiveRemainsSourceOfTruth': true,
      'remoteDataCanOverrideLocalTripLog': false,
      'remoteTotalsCanBecomeCanonical': false,
      'cloudMirrorCanDeleteLocalTripLog': false,
      'queuedWriteCanContainRawGps': false,
      'queuedWriteCanContainMapboxGeometry': false,
      'employeeTrackingRequiresMutualConsent': true,
      'locationSharingRequiresActiveOptIn': true,
      'employerGodModeAllowed': false,
      'preciseLocationIncluded': false,
      'accountIdIncluded': false,
      'organizationIdIncluded': false,
      'rawReviewIncluded': false,
    };
  }

  String get safeErrorMessage {
    return switch (failure) {
      TripTrackingBackupScopeFailure.unsafeAccount =>
        TripTrackingBackupScopePolicy.unsafeAccountMessage,
      TripTrackingBackupScopeFailure.accountMismatch ||
      TripTrackingBackupScopeFailure.scopeMismatch =>
        TripTrackingBackupScopePolicy.scopeMismatchMessage,
      TripTrackingBackupScopeFailure.missingOrganization =>
        TripTrackingBackupScopePolicy.missingOrganizationMessage,
      null => '',
    };
  }
}

bool _safeCanQueue({
  required TripTrackingReviewRecord? review,
  required TripTrackingBackupScopeFailure? failure,
}) {
  if (failure != null || review == null) return false;
  if (!TripTrackingBackupScopePolicy.isSafeCloudToken(review.cloudAccountUid)) {
    return false;
  }
  return TripTrackingBackupScopePolicy.hasValidScopeBinding(
    scope: review.cloudBackupScope,
    organizationId: review.cloudOrganizationId,
  );
}

class TripTrackingBackupScopePolicy {
  const TripTrackingBackupScopePolicy._();

  static const missingOrganizationMessage =
      'An organization is required before company mileage backup can be queued.';
  static const unsafeAccountMessage =
      'Mileage backup is waiting for a valid authenticated account.';
  static const scopeMismatchMessage =
      'Mileage backup is waiting for its original account and organization.';

  static bool isSafeCloudToken(String? value) {
    final clean = value?.trim();
    return clean != null &&
        clean.isNotEmpty &&
        clean.length <= 128 &&
        RegExp(r'^[A-Za-z0-9:_-]+$').hasMatch(clean);
  }

  static bool hasUsableOrganizationId(String? orgId) => isSafeCloudToken(orgId);

  static bool hasValidScopeBinding({
    required TripTrackingCloudBackupScope? scope,
    required String? organizationId,
  }) {
    final hasOrg = hasUsableOrganizationId(organizationId);
    return switch (scope) {
      TripTrackingCloudBackupScope.organization => hasOrg,
      TripTrackingCloudBackupScope.personal || null => !hasOrg,
    };
  }

  static TripTrackingBackupScopeDecision bindForQueue({
    required TripTrackingReviewRecord review,
    required String createdByUid,
    required bool personalBackup,
    required bool organizationSharingEnabled,
    String? orgId,
  }) {
    final uid = createdByUid.trim();
    if (!isSafeCloudToken(uid)) {
      return const TripTrackingBackupScopeDecision.rejected(
        TripTrackingBackupScopeFailure.unsafeAccount,
      );
    }

    final accountUid = review.cloudAccountUid?.trim();
    if (accountUid != null && accountUid.isNotEmpty) {
      if (!isSafeCloudToken(accountUid)) {
        return const TripTrackingBackupScopeDecision.rejected(
          TripTrackingBackupScopeFailure.unsafeAccount,
        );
      }
      if (accountUid != uid) {
        return const TripTrackingBackupScopeDecision.rejected(
          TripTrackingBackupScopeFailure.accountMismatch,
        );
      }
    }

    final usesOrganizationBackup =
        !personalBackup && organizationSharingEnabled;
    final cleanOrgId = orgId?.trim();
    if (usesOrganizationBackup && !hasUsableOrganizationId(cleanOrgId)) {
      return const TripTrackingBackupScopeDecision.rejected(
        TripTrackingBackupScopeFailure.missingOrganization,
      );
    }

    final scope = review.cloudBackupScope;
    if (scope == TripTrackingCloudBackupScope.personal) {
      if (usesOrganizationBackup) {
        return const TripTrackingBackupScopeDecision.rejected(
          TripTrackingBackupScopeFailure.scopeMismatch,
        );
      }
      return TripTrackingBackupScopeDecision.allowed(
        accountUid == null || accountUid.isEmpty
            ? review.copyWith(cloudAccountUid: uid)
            : review,
      );
    }

    if (scope == TripTrackingCloudBackupScope.organization) {
      if (!usesOrganizationBackup ||
          !hasValidScopeBinding(
            scope: scope,
            organizationId: review.cloudOrganizationId,
          ) ||
          review.cloudOrganizationId?.trim() != cleanOrgId) {
        return const TripTrackingBackupScopeDecision.rejected(
          TripTrackingBackupScopeFailure.scopeMismatch,
        );
      }
      return TripTrackingBackupScopeDecision.allowed(
        accountUid == null || accountUid.isEmpty
            ? review.copyWith(cloudAccountUid: uid)
            : review,
      );
    }

    return TripTrackingBackupScopeDecision.allowed(
      review.copyWith(
        cloudAccountUid: uid,
        cloudBackupScope: usesOrganizationBackup
            ? TripTrackingCloudBackupScope.organization
            : TripTrackingCloudBackupScope.personal,
        cloudOrganizationId: usesOrganizationBackup ? cleanOrgId : null,
      ),
    );
  }
}
