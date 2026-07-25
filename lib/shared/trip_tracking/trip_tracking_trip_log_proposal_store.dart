// odometerIsGlobalTruth: true.
import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import 'trip_tracking_session_store.dart';
import 'trip_tracking_trip_log_proposal.dart';

/// Local, coordinate-free inbox between GPS assistance and the future TripLog
/// owner. Saving here never confirms mileage or changes the global odometer.
class TripTrackingTripLogProposalStore
    implements TripTrackingTripLogProposalSink {
  TripTrackingTripLogProposalStore._(this._box) : _available = true;
  TripTrackingTripLogProposalStore.memory() : _box = null, _available = true;
  TripTrackingTripLogProposalStore.unavailable()
    : _box = null,
      _available = false;

  static const boxName = 'trip_tracking_trip_log_proposal_inbox';
  static const schemaVersion = 1;

  final Box<dynamic>? _box;
  final bool _available;
  final Map<String, Map<String, Object?>> _memory = {};
  Future<void> _writeTail = Future<void>.value();

  static Future<TripTrackingTripLogProposalStore> create() async =>
      TripTrackingTripLogProposalStore._(await Hive.openBox<dynamic>(boxName));

  List<TripTrackingTripLogProposal> get proposals {
    final source = _box == null ? _memory.values : _box.values;
    final result = <TripTrackingTripLogProposal>[];
    for (final value in source) {
      final proposal = _tryRead(value);
      if (proposal != null) result.add(proposal);
    }
    result.sort((left, right) => right.finishedAt.compareTo(left.finishedAt));
    return List<TripTrackingTripLogProposal>.unmodifiable(result);
  }

  TripTrackingTripLogProposal? proposalForId(String proposalId) {
    if (!_isSafeId(proposalId)) return null;
    final value = _box == null ? _memory[proposalId] : _box.get(proposalId);
    return _tryRead(value);
  }

  @override
  Future<void> propose(TripTrackingTripLogProposal proposal) =>
      _enqueue(() async {
        if (!_available) {
          throw StateError('TripLog proposal storage is unavailable.');
        }
        final id = proposal.proposalId;
        if (!_isSafeId(id) || !proposal.review.hasValidTimeline) {
          throw ArgumentError.value(
            id,
            'proposal.proposalId',
            'TripLog proposals require a valid local review.',
          );
        }
        final existing = proposalForId(id);
        if (existing != null &&
            existing.reviewRevision >= proposal.reviewRevision) {
          return;
        }
        final value = <String, Object?>{
          'schemaVersion': schemaVersion,
          'proposalId': id,
          'review': proposal.review.toMap(),
        };
        if (_box == null) {
          _memory[id] = value;
        } else {
          await _box.put(id, value);
        }
      });

  TripTrackingTripLogProposal? _tryRead(Object? value) {
    if (value is! Map ||
        value['schemaVersion'] != schemaVersion ||
        value['review'] is! Map) {
      return null;
    }
    final review = TripTrackingReviewRecord.fromMap(value['review'] as Map);
    if (!_isSafeId(review.id) ||
        value['proposalId'] != review.id ||
        !review.hasValidTimeline) {
      return null;
    }
    return TripTrackingTripLogProposal.fromReview(review);
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

bool _isSafeId(String value) {
  final trimmed = value.trim();
  return trimmed.isNotEmpty &&
      trimmed.length <= 160 &&
      RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(trimmed);
}
