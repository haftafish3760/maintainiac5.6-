import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/action_tile.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../../shared/widgets/industrial_panel.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('Fuel', '⛽'),
      ('Maintenance', '🛠️'),
      ('Supplies', '📦'),
      ('Meals', '🍽️'),
      ('Parking', '🅿️'),
      ('Tolls', '🛣️'),
      ('Insurance', '🛡️'),
      ('Other', '🧾'),
    ];
    return AppScreenShell(
      section: AppSection.expenses,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          const IndustrialPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense Center',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6),
                Text(
                  'Log business or personal vehicle costs, attach receipts, and keep records tied to the right date and vehicle.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 82,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: categories.length,
            itemBuilder: (_, index) => ActionTile(
              label: categories[index].$1,
              icon: categories[index].$2,
              color: index == 0 ? AppColors.red : AppColors.blue,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
