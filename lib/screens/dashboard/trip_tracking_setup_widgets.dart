part of 'trip_tracking_setup_sheet.dart';

class _SetupPage extends StatelessWidget {
  const _SetupPage({
    super.key,
    required this.title,
    required this.body,
    required this.children,
  });

  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFF3F6F7),
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: const TextStyle(
            color: Color(0xFFE2E8EA),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _WorkTypeChoice extends StatelessWidget {
  const _WorkTypeChoice({
    required this.title,
    required this.body,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final String body;
  final _WorkType value;
  final bool selected;
  final ValueChanged<_WorkType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _SelectionTile(
        title: title,
        body: body,
        selected: selected,
        onTap: () => onChanged(value),
      ),
    );
  }
}

class _SamplingChoice extends StatelessWidget {
  const _SamplingChoice({
    required this.title,
    required this.body,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final String body;
  final TripTrackingSamplingPreset value;
  final bool selected;
  final ValueChanged<TripTrackingSamplingPreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _SelectionTile(
        title: title,
        body: body,
        selected: selected,
        onTap: () => onChanged(value),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ChoiceSurface(
      selected: selected,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF101416),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xFF273237),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected
                  ? const Color(0xFF087A45)
                  : const Color(0xFF526168),
            ),
          ],
        ),
      ),
    );
  }
}

class _BinaryChoice extends StatelessWidget {
  const _BinaryChoice({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ChoiceSurface(
      selected: selected,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF075F35)
                  : const Color(0xFF273237),
              size: 25,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF101416),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xFF273237),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected
                  ? const Color(0xFF087A45)
                  : const Color(0xFF526168),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceSurface extends StatelessWidget {
  const _ChoiceSurface({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFB9DCC8) : const Color(0xFFAAB4B9),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? const Color(0xFF087A45)
                  : const Color(0xFF7C898F),
              width: selected ? 2 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SetupSwitch extends StatelessWidget {
  const _SetupSwitch({
    required this.title,
    required this.body,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFAAB4B9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF7C898F)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF101416),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF273237),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryEnabled = true,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final bool primaryEnabled;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (secondaryLabel != null) ...[
          TextButton(
            onPressed: onSecondary,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE2E8EA),
            ),
            child: Text(secondaryLabel!),
          ),
          const SizedBox(width: 8),
        ],
        FilledButton(
          onPressed: primaryEnabled ? onPrimary : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppActionColors.positive,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF657279),
          ),
          child: Text(primaryLabel),
        ),
      ],
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice();

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final message = isApple
        ? 'iPhone will ask for location next. Choose Allow While Using App '
              'and keep Precise Location on. Screen-locked tracking may also '
              'ask for Always Allow. Stop suggestions may ask for Motion & Fitness.'
        : 'Android will ask for location next. Choose Precise and allow '
              'location while using the app. Screen-locked tracking also '
              'requires Allow all the time. Stop suggestions may ask for '
              'Physical activity.';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5B6A70)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFE2E8EA),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}
