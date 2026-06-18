part of 'maintenance_screen.dart';

class _MaintenanceActionGrid extends StatelessWidget {
  const _MaintenanceActionGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionSpec(
        'Set Up Item',
        '🧰',
        AppActionColors.positive,
        () => Navigator.of(context).push(
          appNativeRoute<void>(context, const MaintenanceWorkSourceScreen()),
        ),
      ),
      _ActionSpec('Log Service', '🔧', AppActionColors.primary, () {}),
      _ActionSpec('Log Receipt', '🧾', AppActionColors.primary, () {}),
      _ActionSpec('Quick Service', '⚡', AppActionColors.primary, () {}),
      _ActionSpec('Supplies', '📦', AppActionColors.primary, () {}),
      _ActionSpec('History', '📋', AppActionColors.primary, () {}),
    ];

    return _Panel(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 46,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _FlowButton(
            label: action.label,
            emoji: action.emoji,
            color: action.color,
            onPressed: action.onPressed,
          );
        },
      ),
    );
  }
}

class _FlowButton extends StatelessWidget {
  const _FlowButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 19, height: 1)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(10, 10, 10, 11),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFAAB4B9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF78858B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            offset: Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ActionSpec {
  const _ActionSpec(this.label, this.emoji, this.color, this.onPressed);

  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onPressed;
}
