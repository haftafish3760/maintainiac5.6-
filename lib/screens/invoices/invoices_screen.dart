import 'package:flutter/material.dart';

import '../../shared/widgets/action_tile.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../../shared/widgets/industrial_panel.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.invoices,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          const IndustrialPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice Workspace',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6),
                Text(
                  'Invoice, estimate, signature, and payment workflows will be built step by step.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.85,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ActionTile(label: 'Create Estimate', icon: '📋', onTap: () {}),
              ActionTile(label: 'Create Invoice', icon: '🧾', onTap: () {}),
              ActionTile(label: 'Record Payment', icon: '💵', onTap: () {}),
              ActionTile(label: 'Sign Document', icon: '✍️', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}
