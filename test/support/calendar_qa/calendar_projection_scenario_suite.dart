// Calendar QA scenario suite. Uses the shared generic QA harness without
// importing inventory/work-supplies domains or changing their behavior.

import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';

import '../qa_harness/qa_harness.dart';

class CalendarProjectionScenarioSuite extends QaSuite {
  const CalendarProjectionScenarioSuite()
    : super('calendar.projection_scenarios');

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final count = context.maxGeneratedCases.clamp(100, 5000).toInt();
    final first = _events(count, seed: 731);
    final second = _events(count, seed: 731).reversed.toList(growable: false);
    final normalized = CalendarProjectionTimeline.normalize(first);
    final replay = CalendarProjectionTimeline.normalize(second);
    if (!_sameIds(normalized, replay)) {
      failures.add(
        const QaFailure(
          suite: 'calendar.projection_scenarios',
          id: 'deterministic_replay_failed',
          message: 'Identical generated input produced a different timeline.',
          severity: QaSeverity.critical,
        ),
      );
    }
    if (!_ordered(normalized)) {
      failures.add(
        const QaFailure(
          suite: 'calendar.projection_scenarios',
          id: 'chronological_order_failed',
          message:
              'Normalized calendar timeline is not chronologically ordered.',
          severity: QaSeverity.critical,
        ),
      );
    }
    final states = normalized.map((event) => event.state).toSet();
    if (states.length < CalendarProjectionState.values.length) {
      failures.add(
        const QaFailure(
          suite: 'calendar.projection_scenarios',
          id: 'state_coverage_incomplete',
          message: 'Generated scenarios did not cover every calendar state.',
          severity: QaSeverity.error,
        ),
      );
    }
    return timer.finish(
      suite: name,
      checked: count * 4,
      failures: failures,
      metrics: {
        'generatedEvents': first.length,
        'normalizedEvents': normalized.length,
        'scenarioSeed': 731,
        'allStatesCovered':
            states.length == CalendarProjectionState.values.length,
      },
    );
  }
}

List<CalendarProjectionEvent> _events(int count, {required int seed}) {
  final events = <CalendarProjectionEvent>[];
  for (var index = 0; index < count; index++) {
    final source = CalendarProjectionSource
        .values[index % CalendarProjectionSource.values.length];
    final state = CalendarProjectionState
        .values[index % CalendarProjectionState.values.length];
    final day = DateTime.utc(
      2024 + (index % 4),
      1 + (index * 7 % 12),
      1 + (index * 11 % 27),
    );
    final id = 'scenario:$seed:${index ~/ 2}';
    events.add(
      _event(
        id: id,
        source: source,
        state: state,
        time: day.add(Duration(minutes: (index * 37) % 1440)),
        revision: index.isEven ? 1 : 2,
      ),
    );
    if (index.isEven) {
      events.add(
        _event(
          id: id,
          source: source,
          state: state,
          time: day.add(Duration(minutes: (index * 37) % 1440)),
          revision: 2,
        ),
      );
    }
  }
  return events;
}

CalendarProjectionEvent _event({
  required String id,
  required CalendarProjectionSource source,
  required CalendarProjectionState state,
  required DateTime time,
  required int revision,
}) => CalendarProjectionEvent(
  eventId: id,
  source: source,
  sourceRecordId: id,
  timing: CalendarProjectionTiming(
    eventDate: time,
    recordedAt: time,
    timeSource: CalendarTimeSource.recorded,
  ),
  title: 'Scenario $id',
  conciseDetail: 'Generated calendar scenario',
  state: state,
  sourceRecordStatus: state.name,
  revision: revision,
  deepLink: CalendarProjectionDeepLink(
    target: CalendarDeepLinkTarget.reminderDetail,
    sourceRecordId: id,
  ),
);

bool _sameIds(
  List<CalendarProjectionEvent> left,
  List<CalendarProjectionEvent> right,
) =>
    left.length == right.length &&
    Iterable.generate(
      left.length,
    ).every((index) => left[index].eventId == right[index].eventId);

bool _ordered(List<CalendarProjectionEvent> events) =>
    Iterable.generate(events.length - 1).every(
      (index) =>
          events[index].timing.chronologicalTime.compareTo(
            events[index + 1].timing.chronologicalTime,
          ) <=
          0,
    );
