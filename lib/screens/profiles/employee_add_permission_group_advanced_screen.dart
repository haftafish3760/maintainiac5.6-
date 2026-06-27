import 'package:flutter/material.dart';

import '../../shared/widgets/app_screen_shell.dart';
import 'employee_add_permission_setup_models.dart';
import 'employee_profile_widgets.dart';

class EmployeeAddPermissionGroupAdvancedScreen extends StatefulWidget {
  const EmployeeAddPermissionGroupAdvancedScreen({
    super.key,
    required this.group,
    required this.enabled,
    required this.roles,
    required this.employees,
    required this.onChanged,
  });

  final AddCrewPermissionGroup group;
  final Set<String> enabled;
  final Map<String, Set<String>> roles;
  final Map<String, Set<String>> employees;
  final VoidCallback onChanged;

  @override
  State<EmployeeAddPermissionGroupAdvancedScreen> createState() =>
      _EmployeeAddPermissionGroupAdvancedScreenState();
}

class _EmployeeAddPermissionGroupAdvancedScreenState
    extends State<EmployeeAddPermissionGroupAdvancedScreen> {
  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.dashboard,
      maxWidth: 680,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 18),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () {
                    widget.onChanged();
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${widget.group.title} Advanced',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF5F8F9),
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ProfileSection(
            title: 'Only This Category',
            child: Text(
              widget.group.detail,
              style: const TextStyle(
                color: Color(0xFFCAD2D5),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          for (final rule in widget.group.rules)
            _AdvancedRuleCard(
              rule: rule,
              enabled: widget.enabled,
              roles: widget.roles,
              employees: widget.employees,
              onChanged: () {
                setState(() {});
                widget.onChanged();
              },
            ),
        ],
      ),
    );
  }
}

class _AdvancedRuleCard extends StatelessWidget {
  const _AdvancedRuleCard({
    required this.rule,
    required this.enabled,
    required this.roles,
    required this.employees,
    required this.onChanged,
  });

  final AddPermissionRule rule;
  final Set<String> enabled;
  final Map<String, Set<String>> roles;
  final Map<String, Set<String>> employees;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: rule.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            rule.description,
            style: const TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _AdvancedScopeRow(
            label: 'Their own / assigned records',
            rule: rule,
            scope: 'own',
            enabled: enabled,
            roles: roles,
            employees: employees,
            onChanged: onChanged,
          ),
          const SizedBox(height: 8),
          _AdvancedScopeRow(
            label: 'Other employees / team records',
            rule: rule,
            scope: 'other',
            enabled: enabled,
            roles: roles,
            employees: employees,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _AdvancedScopeRow extends StatelessWidget {
  const _AdvancedScopeRow({
    required this.label,
    required this.rule,
    required this.scope,
    required this.enabled,
    required this.roles,
    required this.employees,
    required this.onChanged,
  });

  final String label;
  final AddPermissionRule rule;
  final String scope;
  final Set<String> enabled;
  final Map<String, Set<String>> roles;
  final Map<String, Set<String>> employees;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFEAF0F2),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            for (final action in AddPermissionAction.values) ...[
              Expanded(
                child: _AdvancedActionButton(
                  action: action,
                  selected: rule.hasAction(enabled, scope, action),
                  onTap: () => _toggle(action),
                ),
              ),
              if (action != AddPermissionAction.values.last)
                const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }

  void _toggle(AddPermissionAction action) {
    final selected = rule.hasAction(enabled, scope, action);
    if (!selected) {
      rule.addAction(enabled, scope, AddPermissionAction.view);
      rule.addAction(enabled, scope, action);
    } else if (action == AddPermissionAction.view) {
      rule.removeScope(enabled, scope, roles, employees);
    } else {
      rule.removeAction(enabled, scope, action);
    }
    onChanged();
  }
}

class _AdvancedActionButton extends StatelessWidget {
  const _AdvancedActionButton({
    required this.action,
    required this.selected,
    required this.onTap,
  });

  final AddPermissionAction action;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        selected ? Icons.check_box_rounded : Icons.check_box_outline_blank,
        size: 18,
      ),
      label: Text(action.label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? const Color(0xFF101416) : Colors.white,
        backgroundColor: selected
            ? const Color(0xFFE9F0F2)
            : const Color(0xFF11181B),
        side: BorderSide(
          color: selected ? const Color(0xFFE9F0F2) : const Color(0xFF65757C),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}
