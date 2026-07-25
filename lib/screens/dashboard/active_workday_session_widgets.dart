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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: action.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: action.color.withValues(alpha: 0.42),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(action.icon, color: Colors.white, size: 29),
          ),
          const SizedBox(height: 4),
          Text(
            action.label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionActivityList extends StatelessWidget {
  const _SessionActivityList({required this.events});

  final List<ActiveWorkdayEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionLabel('CURRENT SESSION ACTIVITY'),
        const SizedBox(height: 8),
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
  const _SessionRow({required this.time, required this.text});

  final String time;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
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
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
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
