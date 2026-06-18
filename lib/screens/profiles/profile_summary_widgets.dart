import 'package:flutter/material.dart';

import '../../shared/profiles/user_profile_models.dart';
import '../../shared/theme/app_action_colors.dart';

class ProfileStatusCard extends StatelessWidget {
  const ProfileStatusCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppActionColors.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFAAB4B9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF101416), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF2F383D),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF101416),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PermissionWrap extends StatelessWidget {
  const PermissionWrap({super.key, required this.permissions});

  final Iterable<UserPermission> permissions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final permission in permissions)
          Chip(
            label: Text(permission.label),
            backgroundColor: const Color(0xFF303A3F),
            labelStyle: const TextStyle(
              color: Color(0xFFEAF2F5),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            side: const BorderSide(color: Color(0xFF6D7980)),
          ),
      ],
    );
  }
}

class ContractorActionButton extends StatelessWidget {
  const ContractorActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.detail,
    required this.onPressed,
    this.color = AppActionColors.primary,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
