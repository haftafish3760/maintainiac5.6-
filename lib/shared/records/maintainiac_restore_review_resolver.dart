import 'maintainiac_durable_record_store.dart';
import 'maintainiac_restore_applier.dart';
import 'maintainiac_restore_review_store.dart';

class MaintainiacRestoreReviewResolver {
  const MaintainiacRestoreReviewResolver({
    required MaintainiacDurableRecordStore records,
    required MaintainiacRestoreReviewStore reviews,
  }) : _records = records,
       _reviews = reviews;

  final MaintainiacDurableRecordStore _records;
  final MaintainiacRestoreReviewStore _reviews;

  Future<MaintainiacRestoreReviewIssue> resolve({
    required String issueId,
    required MaintainiacRestoreResolution resolution,
    DateTime? nowUtc,
  }) async {
    final issue = _reviews.issueById(issueId);
    if (issue == null) throw StateError('Restore review issue does not exist.');
    if (issue.state == MaintainiacRestoreReviewState.resolved) {
      if (issue.resolution == resolution) return issue;
      throw StateError('Restore review issue already has another resolution.');
    }
    if (issue.type != MaintainiacRestoreReviewType.conflict) {
      if (resolution != MaintainiacRestoreResolution.keepLocal) {
        throw StateError('An unsafe cloud record cannot replace local data.');
      }
      return _reviews.resolve(issue.id, resolution, nowUtc: nowUtc);
    }
    final expectedLocal = issue.local!;
    final current = _records.recordFor(issue.module, issue.recordId);
    if (current == null) {
      throw StateError('The local conflict record is no longer available.');
    }
    switch (resolution) {
      case MaintainiacRestoreResolution.keepLocal:
        if (_matches(current, expectedLocal)) {
          await _records.preserveLocalAfterConflict(
            module: issue.module,
            id: issue.recordId,
            expectedRevision: current.lifecycle.revision,
            now: nowUtc,
          );
        } else if (current.lifecycle.revision <=
            issue.remote.record.lifecycle.revision) {
          throw StateError('The local conflict changed and needs new review.');
        }
        break;
      case MaintainiacRestoreResolution.applyRemote:
        if (!_matches(current, issue.remote)) {
          if (!_matches(current, expectedLocal)) {
            throw StateError(
              'The local conflict changed and needs new review.',
            );
          }
          await _records.applyRemoteAfterConflict(
            issue.remote.record,
            expectedLocalRevision: current.lifecycle.revision,
          );
        }
        break;
    }
    return _reviews.resolve(issue.id, resolution, nowUtc: nowUtc);
  }

  bool _matches(
    MaintainiacDurableRecord record,
    MaintainiacRestoreReviewRecord expected,
  ) =>
      record.lifecycle.revision == expected.record.lifecycle.revision &&
      MaintainiacRestoreApplier.contentSha256For(
            record,
            accountScopeId: expected.accountScopeId,
          ) ==
          expected.contentSha256;
}
