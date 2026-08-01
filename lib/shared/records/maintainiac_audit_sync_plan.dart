import 'maintainiac_audit_chain.dart';

/// A bounded transport plan for one record's immutable audit evidence.
///
/// It deliberately does not decide when a user may sync. The shared upload
/// coordinator owns that decision; this plan only guarantees that one
/// authorized sync can be split into resumable, independently verifiable
/// pages without creating unbounded Firestore root documents.
class MaintainiacAuditSyncPlan {
  factory MaintainiacAuditSyncPlan.fromEvents(
    Iterable<String> events, {
    int maximumEventsPerPage = defaultMaximumEventsPerPage,
  }) {
    if (maximumEventsPerPage < 1 ||
        maximumEventsPerPage > defaultMaximumEventsPerPage) {
      throw ArgumentError.value(maximumEventsPerPage, 'maximumEventsPerPage');
    }
    final values = List<String>.unmodifiable(events);
    final target = MaintainiacAuditChain.fromEvents(values);
    final pages = <MaintainiacAuditSyncPage>[];
    var before = MaintainiacAuditChainState.empty();
    for (
      var offset = 0;
      offset < values.length;
      offset += maximumEventsPerPage
    ) {
      final end = (offset + maximumEventsPerPage).clamp(0, values.length);
      final pageEvents = List<String>.unmodifiable(values.sublist(offset, end));
      final after = before.appendAll(pageEvents);
      pages.add(
        MaintainiacAuditSyncPage(
          firstOrdinal: before.eventCount + 1,
          events: pageEvents,
          previousChainSha256: before.chainSha256,
          resultingChainSha256: after.chainSha256,
        ),
      );
      before = after;
    }
    return MaintainiacAuditSyncPlan._(
      target: target,
      pages: List.unmodifiable(pages),
    );
  }

  const MaintainiacAuditSyncPlan._({required this.target, required this.pages});

  static const defaultMaximumEventsPerPage = 250;

  final MaintainiacAuditChainState target;
  final List<MaintainiacAuditSyncPage> pages;

  /// Returns the remaining pages after a server-confirmed archive count.
  List<MaintainiacAuditSyncPage> pagesAfter(int archivedEventCount) {
    if (archivedEventCount < 0 || archivedEventCount > target.eventCount) {
      throw ArgumentError.value(archivedEventCount, 'archivedEventCount');
    }
    if (archivedEventCount == target.eventCount) return const [];
    final page = pages.indexWhere(
      (candidate) =>
          archivedEventCount >= candidate.firstOrdinal - 1 &&
          archivedEventCount < candidate.lastOrdinal,
    );
    if (page < 0) {
      throw StateError('Audit checkpoint does not align with the sync plan.');
    }
    final current = pages[page];
    if (archivedEventCount == current.firstOrdinal - 1) {
      return List.unmodifiable(pages.sublist(page));
    }
    final consumed = archivedEventCount - current.firstOrdinal + 1;
    final prefix = current.events.take(consumed);
    final remainder = MaintainiacAuditSyncPage(
      firstOrdinal: archivedEventCount + 1,
      events: List.unmodifiable(current.events.skip(consumed)),
      previousChainSha256: current.chainAfter(prefix).chainSha256,
      resultingChainSha256: current.resultingChainSha256,
    );
    return List.unmodifiable([remainder, ...pages.sublist(page + 1)]);
  }
}

class MaintainiacAuditSyncPage {
  const MaintainiacAuditSyncPage({
    required this.firstOrdinal,
    required this.events,
    required this.previousChainSha256,
    required this.resultingChainSha256,
  }) : assert(firstOrdinal > 0),
       assert(
         events.length <= MaintainiacAuditSyncPlan.defaultMaximumEventsPerPage,
       );

  final int firstOrdinal;
  final List<String> events;
  final String previousChainSha256;
  final String resultingChainSha256;

  int get lastOrdinal => firstOrdinal + events.length - 1;

  MaintainiacAuditChainState chainAfter(Iterable<String> prefix) {
    var state = MaintainiacAuditChainState(
      eventCount: firstOrdinal - 1,
      chainSha256: previousChainSha256,
    );
    return state.appendAll(prefix);
  }
}
