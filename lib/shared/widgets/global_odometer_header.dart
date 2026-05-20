import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';
import 'industrial_panel.dart';

class GlobalOdometerHeader extends StatelessWidget {
  const GlobalOdometerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: IndustrialPanel(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Row(
          children: [
            const Icon(Icons.menu_rounded, size: 28, color: AppColors.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ODOMETER',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _OdometerReadout(value: state.odometer),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Edit odometer',
              onPressed: () => _showEditOdometer(context, state),
              icon: const Icon(Icons.edit_rounded, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditOdometer(
    BuildContext context,
    AppStateController state,
  ) async {
    final controller = TextEditingController(text: state.odometer.toString());
    final value = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Odometer',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Current odometer',
                ),
                onSubmitted: (_) =>
                    Navigator.pop(context, int.tryParse(controller.text)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Cancel',
                    tone: AppButtonTone.destructive,
                    compact: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  AppButton(
                    label: 'Save',
                    tone: AppButtonTone.commit,
                    compact: true,
                    onPressed: () =>
                        Navigator.pop(context, int.tryParse(controller.text)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (value != null) state.updateOdometer(value);
  }
}

class _OdometerReadout extends StatelessWidget {
  const _OdometerReadout({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final digits = value.toString().padLeft(7, '0');
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final char in digits.characters)
            Container(
              width: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFB8B8B8), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: Colors.black87, width: 0.7),
              ),
              child: Text(
                char,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
