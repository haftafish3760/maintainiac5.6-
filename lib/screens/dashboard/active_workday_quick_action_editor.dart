import 'package:flutter/material.dart';

import '../../shared/widgets/app_back_button.dart';
import 'active_workday_actions.dart';

class ActiveWorkdayQuickActionEditor extends StatelessWidget {
  const ActiveWorkdayQuickActionEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final layoutController = WorkdayQuickActionLayoutScope.maybeOf(context);
    final activeLayout =
        layoutController?.layout ?? WorkdayQuickActionLayout.defaults();
    final availableActions = availableWorkdayQuickActions
        .where((action) => !activeLayout.activeKinds.contains(action.kind))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),

      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
          children: [
            const AppScreenHeader(title: 'Edit Quick Actions'),
            const SizedBox(height: 12),
            const _EditorIntroPanel(),
            const SizedBox(height: 14),
            const _EditorSectionTitle('ACTIVE BUTTONS'),
            const SizedBox(height: 8),
            _QuickActionGrid(actions: activeLayout.activeActions, active: true),
            const SizedBox(height: 18),
            const _EditorSectionTitle('AVAILABLE BUTTONS'),
            const SizedBox(height: 8),
            _QuickActionGrid(actions: availableActions, active: false),
          ],
        ),
      ),
    );
  }
}

class _EditorIntroPanel extends StatelessWidget {
  const _EditorIntroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFAAB4B9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF101416), width: 1.3),
      ),
      child: const Text(
        'Choose the quick actions you want on the active workday screen. Later this screen will support long-press reorder, remove, and add behavior.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF2F383D),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          height: 1.24,
        ),
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions, required this.active});

  final List<WorkdayQuickActionSpec> actions;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 540 ? 4 : 3;
        const spacing = 9.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 10,
          children: [
            for (final action in actions)
              SizedBox(
                width: width,
                child: _EditorActionTile(action: action, active: active),
              ),
          ],
        );
      },
    );
  }
}

class _EditorActionTile extends StatelessWidget {
  const _EditorActionTile({required this.action, required this.active});

  final WorkdayQuickActionSpec action;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF151B1E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF3E4A50)),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Icon(
              active ? Icons.remove_circle_rounded : Icons.add_circle_rounded,
              color: active ? const Color(0xFFFF5A4D) : const Color(0xFF35B86B),
              size: 18,
            ),
          ),
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: action.color,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: action.color.withValues(alpha: 0.35),
                  blurRadius: 7,
                ),
              ],
            ),
            child: Text(
              action.emoji,
              style: const TextStyle(fontSize: 24, height: 1),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            action.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (action.requiresOdometer)
            const Text(
              'Odometer',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFD166),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class _EditorSectionTitle extends StatelessWidget {
  const _EditorSectionTitle(this.label);

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
