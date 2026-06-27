import 'package:flutter/material.dart';

import '../../../shared/widgets/industrial_panel.dart';
import 'contractor_dashboard_models.dart';
import 'contractor_dashboard_tiles.dart';

class ContractorOperationsPulse extends StatelessWidget {
  const ContractorOperationsPulse({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: BorderLabel(
        label: 'Operations Pulse',
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 2.55,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final item in contractorOperationsPulse)
              ContractorMetricTile(metric: item),
          ],
        ),
      ),
    );
  }
}
