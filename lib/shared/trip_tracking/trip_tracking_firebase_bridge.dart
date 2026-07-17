import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../firebase/maintainiac_firestore_documents.dart';
import '../firebase/maintainiac_firestore_upload_queue.dart';
import 'trip_tracking_session_store.dart';

abstract interface class TripTrackingCloudMirror {
  Future<void> queueReview(TripTrackingReviewRecord review);

  Future<void> flushPending();

  /// Withdraws backup consent without touching locally stored trip reviews.
  Future<void> withdrawBackupConsent();

  /// Stops unsent organization sharing without changing private backup consent.
  Future<void> withdrawOrganizationSharingConsent();

  void dispose();
}

class NoopTripTrackingCloudMirror implements TripTrackingCloudMirror {
  const NoopTripTrackingCloudMirror();

  @override
  Future<void> queueReview(TripTrackingReviewRecord review) async {}

  @override
  Future<void> flushPending() async {}

  @override
  Future<void> withdrawBackupConsent() async {}

  @override
  Future<void> withdrawOrganizationSharingConsent() async {}

  @override
  void dispose() {}
}

/// Queues only reviewed mileage summaries. It never mirrors live coordinates
/// or raw tracking evidence and never becomes the source of truth for a trip.
class TripTrackingFirebaseMirror implements TripTrackingCloudMirror {
  TripTrackingFirebaseMirror({
    required MaintainiacFirestoreUploadQueueStore queueStore,
    required MaintainiacFirestoreUploadCoordinator uploadCoordinator,
    TripTrackingSessionStore? localStore,
    String? orgId,
    this.personal = false,
    String? createdByUid,
    FirebaseAuth? firebaseAuth,
    String? Function()? authenticatedUid,
    bool Function()? backupEnabled,
    bool Function()? organizationSharingEnabled,
  }) : _queueStore = queueStore,
       _uploadCoordinator = uploadCoordinator,
       _localStore = localStore,
       _orgId = orgId,
       _createdByUid = createdByUid,
       _firebaseAuth = firebaseAuth,
       _authenticatedUid = authenticatedUid,
       _backupEnabled = backupEnabled,
       _organizationSharingEnabled = organizationSharingEnabled {
    _authSubscription = firebaseAuth?.authStateChanges().listen((user) {
      if (user != null) unawaited(flushPending());
    });
  }

  final MaintainiacFirestoreUploadQueueStore _queueStore;
  final MaintainiacFirestoreUploadCoordinator _uploadCoordinator;
  final TripTrackingSessionStore? _localStore;
  final String? _orgId;
  final bool personal;
  final String? _createdByUid;
  final FirebaseAuth? _firebaseAuth;
  final String? Function()? _authenticatedUid;
  final bool Function()? _backupEnabled;
  final bool Function()? _organizationSharingEnabled;
  late final StreamSubscription<User?>? _authSubscription;
  Future<void>? _flushInFlight;

  @override
  Future<void> queueReview(TripTrackingReviewRecord review) async {
    if (!_isReviewEligibleForBackup(review)) {
      await _discardQueuedBackupFor(review);
      await _saveReviewState(
        review.copyWith(
          cloudSyncState: TripTrackingCloudSyncState.localOnly,
          clearCloudSyncError: true,
        ),
      );
      throw StateError(
        'A valid, physically confirmed trip review is required before mileage backup.',
      );
    }
    if (!_isBackupEnabled) {
      await _discardQueuedBackupFor(review);
      await _saveReviewState(
        review.copyWith(
          cloudSyncState: TripTrackingCloudSyncState.localOnly,
          clearCloudSyncError: true,
        ),
      );
      return;
    }
    final rawCreatedByUid = _currentUid;
    final createdByUid = rawCreatedByUid?.trim();
    if (createdByUid == null || createdByUid.isEmpty) {
      await _saveReviewState(
        review.copyWith(
          cloudSyncState: TripTrackingCloudSyncState.pending,
          cloudSyncError: 'Backup sign-in is required before backup.',
        ),
      );
      throw StateError(
        'Backup sign-in is required before mileage backup can be queued.',
      );
    }
    if (!_isSafeFirestoreUid(createdByUid)) {
      await _saveReviewState(
        review.copyWith(
          cloudSyncState: TripTrackingCloudSyncState.pending,
          cloudSyncError: _unsafeAccountMessage,
        ),
      );
      throw StateError(_unsafeAccountMessage);
    }
    if (_usesOrganizationBackup && !(_orgId?.trim().isNotEmpty ?? false)) {
      const message = _missingOrganizationMessage;
      await _saveReviewState(
        review.copyWith(
          cloudSyncState: TripTrackingCloudSyncState.pending,
          cloudSyncError: message,
        ),
      );
      throw StateError(message);
    }
    final boundReview = _bindReview(review, createdByUid);
    if (boundReview == null) {
      await _saveReviewState(
        review.copyWith(
          cloudSyncState: TripTrackingCloudSyncState.pending,
          cloudSyncError: _backupScopeMismatchMessage,
        ),
      );
      throw StateError(_backupScopeMismatchMessage);
    }
    late final MaintainiacFirestoreDocumentDraft document;
    try {
      document = _documentFor(createdByUid, boundReview);
    } catch (_) {
      await _saveReviewState(
        review.copyWith(
          cloudSyncState: TripTrackingCloudSyncState.pending,
          cloudSyncError: _unsafeMileageIdentityMessage,
        ),
      );
      throw StateError(_unsafeMileageIdentityMessage);
    }
    await _queueStore.enqueueReplacingPendingForPath(
      document,
      queuedAtUtc: boundReview.finishedAt.toUtc(),
      preserveAttemptMetadata: true,
    );
    await _saveReviewState(
      boundReview.copyWith(
        cloudSyncState: TripTrackingCloudSyncState.queued,
        clearCloudSyncError: true,
      ),
    );
  }

  @override
  Future<void> flushPending() {
    final inFlight = _flushInFlight;
    if (inFlight != null) return inFlight;

    late final Future<void> next;
    next = _flushPending().whenComplete(() {
      if (identical(_flushInFlight, next)) _flushInFlight = null;
    });
    _flushInFlight = next;
    return next;
  }

  @override
  Future<void> withdrawBackupConsent() async {
    final localStore = _localStore;
    if (localStore == null) return;
    for (final review in localStore.pendingReviews) {
      if (review.cloudSyncState == TripTrackingCloudSyncState.synced ||
          review.cloudSyncState == TripTrackingCloudSyncState.localOnly) {
        continue;
      }
      await _discardQueuedBackupFor(review);
      await _saveReviewState(
        review.copyWith(
          cloudSyncState: TripTrackingCloudSyncState.localOnly,
          clearCloudSyncError: true,
        ),
      );
    }
  }

  @override
  Future<void> withdrawOrganizationSharingConsent() async {
    final localStore = _localStore;
    if (localStore == null) return;
    for (final review in localStore.pendingReviews) {
      final isOrganizationReview =
          review.cloudBackupScope ==
              TripTrackingCloudBackupScope.organization ||
          (review.cloudBackupScope == null &&
              !personal &&
              _orgId?.trim().isNotEmpty == true);
      if (!isOrganizationReview ||
          review.cloudSyncState == TripTrackingCloudSyncState.synced ||
          review.cloudSyncState == TripTrackingCloudSyncState.localOnly) {
        continue;
      }
      await _discardQueuedBackupFor(review);
      await _saveReviewState(
        review.copyWith(
          cloudSyncState: TripTrackingCloudSyncState.localOnly,
          clearCloudSyncError: true,
        ),
      );
    }
  }

  Future<void> _flushPending() async {
    if (!_isBackupEnabled) {
      // A settings change may race a scheduled/auth-triggered flush. Treat
      // the live consent read as authoritative and remove unsent summaries
      // rather than leaving them eligible for a later upload.
      await withdrawBackupConsent();
      return;
    }
    final rawCreatedByUid = _currentUid;
    final createdByUid = rawCreatedByUid?.trim();
    if (createdByUid == null || createdByUid.isEmpty) return;
    final localStore = _localStore;
    if (!_isSafeFirestoreUid(createdByUid)) {
      if (localStore != null) {
        for (final review in localStore.pendingReviews) {
          if (review.cloudSyncState == TripTrackingCloudSyncState.synced ||
              review.cloudSyncState == TripTrackingCloudSyncState.localOnly) {
            continue;
          }
          await _saveReviewState(
            review.copyWith(
              cloudSyncState: TripTrackingCloudSyncState.pending,
              cloudSyncError: _unsafeAccountMessage,
            ),
          );
        }
      }
      return;
    }
    if (_usesOrganizationBackup && !(_orgId?.trim().isNotEmpty ?? false)) {
      if (localStore != null) {
        for (final review in localStore.pendingReviews) {
          if (review.cloudSyncState == TripTrackingCloudSyncState.synced ||
              review.cloudSyncState == TripTrackingCloudSyncState.localOnly) {
            continue;
          }
          await _saveReviewState(
            review.copyWith(
              cloudSyncState: TripTrackingCloudSyncState.pending,
              cloudSyncError: _missingOrganizationMessage,
            ),
          );
        }
      }
      return;
    }
    // The durable local review is the proof that a queue item was physically
    // confirmed. Without it, an old or foreign queue entry must remain local
    // rather than being uploaded speculatively.
    if (localStore == null) return;
    final reviews = localStore.pendingReviews.where(
      (review) =>
          review.cloudSyncState != TripTrackingCloudSyncState.localOnly &&
          review.cloudSyncState != TripTrackingCloudSyncState.synced,
    );
    for (final review in reviews) {
      try {
        if (!_isBackupEnabled) {
          await withdrawBackupConsent();
          return;
        }
        if (!_isReviewEligibleForBackup(review)) {
          await _discardQueuedBackupFor(review);
          await _saveReviewState(
            review.copyWith(
              cloudSyncState: TripTrackingCloudSyncState.localOnly,
              clearCloudSyncError: true,
            ),
          );
          continue;
        }
        final boundReview = _bindReview(review, createdByUid);
        if (boundReview == null) {
          await _discardQueuedBackupFor(review);
          await _saveReviewState(
            review.copyWith(
              cloudSyncState: TripTrackingCloudSyncState.pending,
              cloudSyncError: _backupScopeMismatchMessage,
            ),
          );
          continue;
        }
        late final MaintainiacFirestoreDocumentDraft document;
        try {
          document = _documentFor(createdByUid, boundReview);
        } catch (_) {
          await _discardQueuedBackupFor(review);
          await _saveReviewState(
            review.copyWith(
              cloudSyncState: TripTrackingCloudSyncState.pending,
              cloudSyncError: _unsafeMileageIdentityMessage,
            ),
          );
          continue;
        }
        await _queueStore.enqueueReplacingPendingForPath(
          document,
          queuedAtUtc: boundReview.finishedAt.toUtc(),
          preserveAttemptMetadata: true,
        );
        await _saveReviewState(
          boundReview.copyWith(
            cloudSyncState: TripTrackingCloudSyncState.queued,
            clearCloudSyncError: true,
          ),
        );
        if (!_isBackupEnabled) {
          await withdrawBackupConsent();
          return;
        }
        final result = await _uploadCoordinator.uploadPending(
          limit: 1,
          path: document.path,
        );
        if (result.uploadedCount == 1) {
          await _saveReviewState(
            boundReview.copyWith(
              cloudSyncState: TripTrackingCloudSyncState.synced,
              cloudSyncedAt: DateTime.now().toUtc(),
              clearCloudSyncError: true,
            ),
          );
        } else if (result.status ==
                MaintainiacFirestoreUploadStatus.quotaExceeded ||
            result.status ==
                MaintainiacFirestoreUploadStatus.networkUnavailable ||
            result.status == MaintainiacFirestoreUploadStatus.disabled) {
          await _saveReviewState(
            boundReview.copyWith(
              cloudSyncState: TripTrackingCloudSyncState.pending,
              cloudSyncError: result.reason ?? result.status.name,
            ),
          );
        } else if (result.failedCount > 0) {
          await _saveReviewState(
            boundReview.copyWith(
              cloudSyncState: TripTrackingCloudSyncState.failed,
              cloudSyncError: result.status.name,
            ),
          );
        }
      } catch (_) {
        await _saveReviewState(
          review.copyWith(
            cloudSyncState: TripTrackingCloudSyncState.failed,
            cloudSyncError: _backupFlushFailedMessage,
          ),
        );
      }
    }
  }

  String? get _currentUid {
    // When an auth provider is supplied, its current state is authoritative.
    // Never reuse the startup UID after sign-out or account switching. The
    // constructor fallback is intentionally limited to dependency-free tests
    // and non-Firebase callers that do not provide an auth provider.
    final authenticatedUid = _authenticatedUid;
    if (authenticatedUid != null) return authenticatedUid();
    final firebaseAuth = _firebaseAuth;
    if (firebaseAuth != null) return firebaseAuth.currentUser?.uid;
    return _createdByUid;
  }

  bool get _isBackupEnabled {
    final backupEnabled = _backupEnabled;
    if (backupEnabled == null) return true;
    try {
      return backupEnabled();
    } catch (_) {
      // A broken consent/settings read must fail closed to local-only.
      return false;
    }
  }

  bool get _usesOrganizationBackup {
    if (personal) return false;
    final organizationSharingEnabled = _organizationSharingEnabled;
    if (organizationSharingEnabled == null) return true;
    try {
      return organizationSharingEnabled();
    } catch (_) {
      // A broken consent/settings read must fail closed to private backup.
      return false;
    }
  }

  bool _isReviewEligibleForBackup(TripTrackingReviewRecord review) =>
      review.hasValidTimeline &&
      review.id.trim().isNotEmpty &&
      review.vehicleId.trim().isNotEmpty &&
      review.estimatedEndingOdometer >= review.startingOdometer &&
      review.isOdometerConfirmed;

  static const _missingOrganizationMessage =
      'An organization is required before company mileage backup can be queued.';
  static const _unsafeAccountMessage =
      'Mileage backup is waiting for a valid authenticated account.';
  static const _backupScopeMismatchMessage =
      'Mileage backup is waiting for its original account and organization.';
  static const _unsafeMileageIdentityMessage =
      'Mileage backup is waiting for a valid trip and vehicle identity.';
  static const _backupFlushFailedMessage =
      'Mileage backup could not finish. Retry backup when the connection is stable.';

  TripTrackingReviewRecord? _bindReview(
    TripTrackingReviewRecord review,
    String createdByUid,
  ) {
    final accountUid = review.cloudAccountUid?.trim();
    if (accountUid != null &&
        accountUid.isNotEmpty &&
        !_isSafeFirestoreUid(accountUid)) {
      return null;
    }
    if (accountUid != null &&
        accountUid.isNotEmpty &&
        accountUid != createdByUid) {
      return null;
    }
    final scope = review.cloudBackupScope;
    final orgId = _orgId?.trim();
    final usesOrganizationBackup = _usesOrganizationBackup;
    if (scope == TripTrackingCloudBackupScope.personal &&
        usesOrganizationBackup) {
      return null;
    }
    if (scope == TripTrackingCloudBackupScope.personal) {
      return accountUid == null || accountUid.isEmpty
          ? review.copyWith(cloudAccountUid: createdByUid)
          : review;
    }
    if (scope == TripTrackingCloudBackupScope.organization &&
        (!usesOrganizationBackup ||
            review.cloudOrganizationId?.trim() != orgId)) {
      return null;
    }
    if (scope == TripTrackingCloudBackupScope.organization) {
      return accountUid == null || accountUid.isEmpty
          ? review.copyWith(cloudAccountUid: createdByUid)
          : review;
    }
    if (scope == null) {
      return review.copyWith(
        cloudAccountUid: createdByUid,
        cloudBackupScope: usesOrganizationBackup
            ? TripTrackingCloudBackupScope.organization
            : TripTrackingCloudBackupScope.personal,
        cloudOrganizationId: usesOrganizationBackup ? orgId : null,
      );
    }
    return review;
  }

  Future<void> _discardQueuedBackupFor(TripTrackingReviewRecord review) async {
    final accountUid = review.cloudAccountUid?.trim() ?? _currentUid?.trim();
    if (accountUid == null || accountUid.isEmpty) return;
    if (!_isSafeFirestoreUid(accountUid)) return;
    final scope = review.cloudBackupScope;
    try {
      if (scope == TripTrackingCloudBackupScope.organization &&
          review.cloudOrganizationId?.trim().isNotEmpty == true) {
        await _queueStore.discardPendingForPath(
          MaintainiacFirestoreDocumentBuilder.tripTrackingReviewPath(
            orgId: review.cloudOrganizationId!.trim(),
            tripId: review.id,
          ),
        );
      } else if (scope == null &&
          !personal &&
          _orgId?.trim().isNotEmpty == true) {
        // Reviews queued before scope binding was introduced used the active
        // organization path. Remove that legacy pending record on withdrawal.
        await _queueStore.discardPendingForPath(
          MaintainiacFirestoreDocumentBuilder.tripTrackingReviewPath(
            orgId: _orgId!.trim(),
            tripId: review.id,
          ),
        );
      } else if (scope == TripTrackingCloudBackupScope.personal || personal) {
        await _queueStore.discardPendingForPath(
          MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewPath(
            uid: accountUid,
            tripId: review.id,
          ),
        );
      }
    } catch (_) {
      // Queue cleanup is best effort. Consent withdrawal must still make the
      // durable local review local-only so an unsafe legacy path cannot keep
      // mileage eligible for cloud upload.
    }
  }

  MaintainiacFirestoreDocumentDraft _documentFor(
    String createdByUid,
    TripTrackingReviewRecord review,
  ) => _usesOrganizationBackup
      ? MaintainiacFirestoreDocumentBuilder.tripTrackingReviewDocument(
          orgId: _orgId ?? '',
          createdByUid: createdByUid,
          review: review,
        )
      : MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
          uid: createdByUid,
          review: review,
        );

  Future<void> _saveReviewState(TripTrackingReviewRecord review) async {
    await _localStore?.saveReview(review);
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
  }
}

bool _isSafeFirestoreUid(String value) {
  final clean = value.trim();
  return clean.isNotEmpty &&
      clean.length <= 128 &&
      RegExp(r'^[A-Za-z0-9:_-]+$').hasMatch(clean);
}
