import 'package:flutter/material.dart';

import '../../shared/state/app_state.dart';

class VehicleProfilePreview {
  const VehicleProfilePreview({
    this.id = '',
    required this.nickname,
    required this.year,
    required this.make,
    required this.model,
    required this.odometer,
    required this.status,
    this.usage = VehicleUsage.businessPersonal,
    this.tireSizeStatus = VehicleTireSizeStatus.unknown,
    this.speedometerCalibrationStatus =
        VehicleSpeedometerCalibrationStatus.unknown,
    this.tireConfigurationRevision = 0,
    this.tireConfigurationUpdatedAt,
  });

  final String id;
  final String nickname;
  final String year;
  final String make;
  final String model;
  final String odometer;
  final String status;
  final VehicleUsage usage;
  final VehicleTireSizeStatus tireSizeStatus;
  final VehicleSpeedometerCalibrationStatus speedometerCalibrationStatus;
  final int tireConfigurationRevision;
  final DateTime? tireConfigurationUpdatedAt;
}

class VehicleFormBackground extends StatelessWidget {
  const VehicleFormBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _VehicleFormBackgroundPainter(),
      child: child,
    );
  }
}

class VehicleProfilePanel extends StatelessWidget {
  const VehicleProfilePanel({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF172023),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF607783), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF234454),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFEAF2F5),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .45,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class SavedVehicleButton extends StatelessWidget {
  const SavedVehicleButton({
    super.key,
    required this.vehicle,
    required this.selected,
    required this.onSelect,
  });

  final VehicleProfilePreview vehicle;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFAAB4B9) : const Color(0xFF8F9BA1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: selected ? const Color(0xFF101416) : const Color(0xFF7D888E),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: const Color(0xFF101416),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      vehicle.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF101416),
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2F383D),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.usage.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF455157),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.touch_app_rounded,
                color: Color(0xFF101416),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VehicleUsageSelector extends StatelessWidget {
  const VehicleUsageSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Null only while a new vehicle profile is awaiting the driver's choice.
  /// Persisted vehicle profiles always carry an explicit usage classification.
  final VehicleUsage? value;
  final ValueChanged<VehicleUsage> onChanged;

  @override
  Widget build(BuildContext context) {
    return VehicleProfilePanel(
      label: 'VEHICLE USAGE',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What do you use this vehicle for?',
              style: TextStyle(
                color: Color(0xFFEAF2F5),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Choose one. This controls only suggested tracking and review behavior; you always confirm mileage.',
              style: TextStyle(
                color: Color(0xFFC9D9E0),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            for (final usage in VehicleUsage.values) ...[
              _VehicleUsageOption(
                usage: usage,
                selected: usage == value,
                onTap: () => onChanged(usage),
              ),
              if (usage != VehicleUsage.values.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _VehicleUsageOption extends StatelessWidget {
  const _VehicleUsageOption({
    required this.usage,
    required this.selected,
    required this.onTap,
  });

  final VehicleUsage usage;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFDCE8EF) : const Color(0xFFC4CDD1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(
          color: selected ? const Color(0xFF2E6FA8) : const Color(0xFF7D888E),
          width: selected ? 1.8 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? const Color(0xFF1B5D8E)
                    : const Color(0xFF3C474D),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usage.label,
                      style: const TextStyle(
                        color: Color(0xFF101416),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usage.setupDescription,
                      style: const TextStyle(
                        color: Color(0xFF3B474D),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(height: 5),
                      Text(
                        usage.odometerPrompt,
                        style: const TextStyle(
                          color: Color(0xFF1B5D8E),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          height: 1.16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VehicleField extends StatelessWidget {
  const VehicleField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction,
    this.keyboardType,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      decoration: BoxDecoration(
        color: const Color(0xFF172023),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF607783), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF234454),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFEAF2F5),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.35,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 5),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onSubmitted: (value) {
                if (nextFocusNode != null) {
                  nextFocusNode!.requestFocus();
                  return;
                }
                onSubmitted?.call(value);
              },
              style: const TextStyle(
                color: Color(0xFFEAF2F5),
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFFC9D9E0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleSectionPlateTitle extends StatelessWidget {
  const VehicleSectionPlateTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF101416),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF59636A)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFE2E8EA),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class VehicleHelperText extends StatelessWidget {
  const VehicleHelperText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD7DFE2),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}

class _VehicleFormBackgroundPainter extends CustomPainter {
  const _VehicleFormBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2528), Color(0xFF263034), Color(0xFF171D20)],
        ).createShader(rect),
    );

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..strokeWidth = 1;

    for (var y = -size.width; y < size.height + size.width; y += 14) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + size.width * 0.18),
        highlight,
      );
      canvas.drawLine(
        Offset(0, y + 3),
        Offset(size.width, y + 3 + size.width * 0.18),
        shadow,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VehicleFormBackgroundPainter oldDelegate) =>
      false;
}
