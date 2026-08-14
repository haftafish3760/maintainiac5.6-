/// Durable local inbox for GPS App Assistant evidence candidates.
///
/// Owns candidate persistence, deduplication, and revision-safe user decisions.
/// It does not own location samples, active tracking sessions, odometer history,
/// or final trips. Consumed by the review inbox; every accepted candidate remains
/// an editable review and cannot create a confirmed record by itself.
library;

import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import 'automatic_evidence_capture_allowance_policy.dart';
import 'trip_automatic_evidence_candidate.dart';

class TripAutomaticEvidenceCandidateStore {
  /// Candidate storage cannot change physical odometer truth.
  static const bool odometerIsGlobalTruth = true;

  TripAutomaticEvidenceCandidateStore._(this._box) : _available = true;
  TripAutomaticEvidenceCandidateStore.memory() : _box = null, _available = true;
  TripAutomaticEvidenceCandidateStore.unavailable()
    : _box = null,
      _available = false;

  static const boxName = 'trip_automatic_evidence_candidate_inbox';
  static const schemaVersion = 1;
  static const pendingRetention = Duration(days: 90);
  static const resolvedRetention = Duration(days: 365);
  static const maximumResolvedCandidates = 1000;

  final Box<dynamic>? _box;
  final bool _available;
  final Map<String, Map<String, Object?>> _memory = {};
  Future<void> _writeTail = Future<void>.value();

  static Future<TripAutomaticEvidenceCandidateStore> create() async =>
      TripAutomaticEvidenceCandidateStore._(
        await Hive.openBox<dynamic>(boxName),
      );

  List<TripAutomaticEvidenceCandidate> get candidates {
    final source = _box == null ? _memory.values : _box.values;
    final result = source
        .map(_tryRead)
        .whereType<TripAutomaticEvidenceCandidate>()
        .toList(growable: false);
    result.sort(
      (left, right) => right.detectedAtUtc.compareTo(left.detectedAtUtc),
    );
    return List<TripAutomaticEvidenceCandidate>.unmodifiable(result);
  }

  List<TripAutomaticEvidenceCandidate> get reviewNeeded =>
      List<TripAutomaticEvidenceCandidate>.unmodifiable(
        candidates
            .where((item) => item.requiresUserReview)
            .toList(growable: false),
      );

  int acceptedFreeUsesInPeriod(String periodKey) => candidates
      .where(
        (item) =>
            item.state ==
                TripAutomaticEvidenceCandidateState.approvedForEditableReview &&
            item.consumesFreeUseIfAccepted &&
            item.allowancePeriodKey == periodKey,
      )
      .length;

  int acceptedFreeUsesAt(DateTime occurredAt) =>
      acceptedFreeUsesInPeriod(automaticEvidenceCapturePeriodKey(occurredAt));

  TripAutomaticEvidenceCandidate? candidateForId(String candidateId) {
    if (!_isSafeCandidateId(candidateId)) return null;
    return _tryRead(
      _box == null ? _memory[candidateId] : _box.get(candidateId),
    );
  }

  Future<void> propose(TripAutomaticEvidenceCandidate candidate) =>
      _enqueue(() async {
        _ensureAvailable();
        final existing = candidateForId(candidate.id);
        if (existing != null) return;
        await _write(candidate);
      });

  Future<TripAutomaticEvidenceCandidate> decide({
    required String candidateId,
    required int expectedRevision,
    required bool approved,
    required DateTime decidedAt,
  }) => _enqueue(() async {
    _ensureAvailable();
    final current = candidateForId(candidateId);
    if (current == null) {
      throw StateError('Automatic evidence candidate is unavailable.');
    }
    if (current.revision != expectedRevision) {
      throw StateError(
        'Automatic evidence candidate changed. Reload before deciding.',
      );
    }
    if (approved && current.requiresPaidEntitlementOnAcceptance) {
      throw StateError(
        'This App Assistant review requires paid access. No trip or mileage was changed.',
      );
    }
    if (approved && current.consumesFreeUseIfAccepted) {
      final periodKey = current.allowancePeriodKey;
      final limit = current.freeUseLimitAtDetection;
      if (periodKey == null ||
          limit <= 0 ||
          acceptedFreeUsesInPeriod(periodKey) >= limit) {
        throw StateError(
          'The free App Assistant review allowance for this month has been used. No trip or mileage was changed.',
        );
      }
    }
    final decided = current.resolve(approved: approved, decidedAt: decidedAt);
    await _write(decided);
    return decided;
  });

  /// Applies the explicit privacy/storage retention rule. Unreviewed evidence
  /// is first marked expired with an audit entry; only already resolved or
  /// expired advisory evidence is later removed. Confirmed trips and odometer
  /// records are outside this store and can never be deleted here.
  Future<void> maintainRetention({required DateTime nowUtc}) =>
      _enqueue(() async {
        _ensureAvailable();
        final now = nowUtc.toUtc();
        final pendingCutoff = now.subtract(pendingRetention);
        for (final candidate in candidates) {
          if (candidate.requiresUserReview &&
              candidate.detectedAtUtc.isBefore(pendingCutoff)) {
            await _write(candidate.expire(expiredAt: now));
          }
        }

        final resolved =
            candidates
                .where((item) => !item.requiresUserReview)
                .toList(growable: false)
              ..sort((left, right) {
                final leftAt = left.auditHistory.last.recordedAtUtc;
                final rightAt = right.auditHistory.last.recordedAtUtc;
                return rightAt.compareTo(leftAt);
              });
        final resolvedCutoff = now.subtract(resolvedRetention);
        for (var index = 0; index < resolved.length; index += 1) {
          final candidate = resolved[index];
          if (index >= maximumResolvedCandidates ||
              candidate.auditHistory.last.recordedAtUtc.isBefore(
                resolvedCutoff,
              )) {
            await _delete(candidate.id);
          }
        }
      });

  Future<void> _write(TripAutomaticEvidenceCandidate candidate) async {
    if (!_isSafeCandidateId(candidate.id)) {
      throw ArgumentError.value(candidate.id, 'candidate.id');
    }
    final value = <String, Object?>{
      'schemaVersion': schemaVersion,
      'candidateId': candidate.id,
      'candidate': candidate.toMap(),
    };
    if (_box == null) {
      _memory[candidate.id] = value;
    } else {
      await _box.put(candidate.id, value);
    }
  }

  Future<void> _delete(String candidateId) async {
    if (_box == null) {
      _memory.remove(candidateId);
    } else {
      await _box.delete(candidateId);
    }
  }

  TripAutomaticEvidenceCandidate? _tryRead(Object? value) {
    if (value is! Map ||
        value['schemaVersion'] != schemaVersion ||
        value['candidate'] is! Map) {
      return null;
    }
    final candidate = TripAutomaticEvidenceCandidate.fromMap(
      value['candidate'],
    );
    if (candidate == null || value['candidateId'] != candidate.id) {
      return null;
    }
    return candidate;
  }

  void _ensureAvailable() {
    if (!_available) {
      throw StateError('Automatic evidence candidate storage is unavailable.');
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _writeTail = _writeTail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}

bool _isSafeCandidateId(String value) {
  final clean = value.trim();
  return clean.length <= 160 &&
      RegExp(r'^automatic-evidence-[a-f0-9]{32}$').hasMatch(clean);
}
