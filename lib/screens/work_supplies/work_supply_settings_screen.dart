import 'package:flutter/material.dart';

import '../../shared/widgets/app_back_button.dart';

class WorkSupplySettingsScreen extends StatelessWidget {
  const WorkSupplySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: const [
            AppScreenHeader(title: 'Work Supplies Settings', centerTitle: true),
            SizedBox(height: 12),
            Text(
              'Supply alerts, low-stock thresholds, image compression, and receipt learning settings will live here.',
              style: TextStyle(
                color: Color(0xFFE8ECEE),
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
