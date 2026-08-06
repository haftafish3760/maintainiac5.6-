part of 'active_workday_screen.dart';

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF101416),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF59636A)),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFF50F77A),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action, required this.onTap});

  final WorkdayQuickActionSpec action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF151B1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: action.color.withValues(alpha: .8)),
            boxShadow: [
              BoxShadow(
                color: action.color.withValues(alpha: .16),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: action.color, size: 28),
              const SizedBox(height: 5),
              Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE2E8EA),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionActivityList extends StatelessWidget {
  const _SessionActivityList({
    required this.events,
    required this.pendingGpsStopReviews,
    required this.onReviewGpsStops,
  });

  final List<ActiveWorkdayEvent> events;
  final int pendingGpsStopReviews;
  final VoidCallback onReviewGpsStops;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionLabel('CURRENT SESSION ACTIVITY'),
        const SizedBox(height: 8),
        if (pendingGpsStopReviews > 0)
          _SessionRow(
            time: 'GPS',
            text:
                '$pendingGpsStopReviews possible ${pendingGpsStopReviews == 1 ? 'stop is' : 'stops are'} ready for review',
            onTap: onReviewGpsStops,
          ),
        if (events.isEmpty)
          const _SessionRow(time: 'Now', text: 'Workday started')
        else
          for (final event in events.reversed)
            _SessionRow(time: event.timeLabel, text: event.displayText),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.time, required this.text, this.onTap});

  final String time;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: const BoxConstraints(minHeight: 42),
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF151B1E),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF3E4A50)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              time,
              style: const TextStyle(
                color: Color(0xFF50F77A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFE2E8EA),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: text,
      child: GestureDetector(onTap: onTap, child: content),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFE2E8EA),
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

String _plainCapabilityLabel(TripTrackingCapabilityReadiness readiness) {
  return switch (readiness) {
    TripTrackingCapabilityReadiness.unavailable => 'Location unavailable',
    TripTrackingCapabilityReadiness.locationOnly ||
    TripTrackingCapabilityReadiness.foregroundReady => 'Location ready',
    TripTrackingCapabilityReadiness.backgroundReady =>
      'Screen-lock tracking ready',
    TripTrackingCapabilityReadiness.motionReady => 'Stop suggestions available',
    TripTrackingCapabilityReadiness.fullSafetyAssist =>
      'Location and stop suggestions ready',
  };
}
