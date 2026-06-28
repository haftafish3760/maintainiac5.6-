import 'package:flutter/material.dart';

import 'dashboard_shortcuts.dart';

class PreDayStartContent extends StatelessWidget {
  const PreDayStartContent({super.key, required this.onStartDay});

  final VoidCallback onStartDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DashboardTitleBand(),
          const SizedBox(height: 10),
          const _TopReadouts(),
          const SizedBox(height: 12),
          const Text(
            'READY TO TRACK',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Center(child: _RoundStartDayButton(onPressed: onStartDay)),
          const SizedBox(height: 14),
          const FastRecordGrid(),
          const SizedBox(height: 12),
          const WeeklyDetailLinks(),
        ],
      ),
    );
  }
}

class _DashboardTitleBand extends StatelessWidget {
  const _DashboardTitleBand();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5B6A70), width: 1.2),
      ),
      child: const Row(
        children: [
          Icon(Icons.person_pin_circle_rounded, color: _blue, size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Independent Dashboard',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFFE2E8EA),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            'Solo workday',
            style: TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopReadouts extends StatelessWidget {
  const _TopReadouts();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _MetricReadout(
            label: 'Profit',
            value: r'$1,763',
            color: _green,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MetricReadout(label: 'Pay', value: r'$2,184', color: _green),
        ),
      ],
    );
  }
}

class _MetricReadout extends StatelessWidget {
  const _MetricReadout({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141A1D),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF627077), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1,
                shadows: [
                  Shadow(color: color.withValues(alpha: 0.45), blurRadius: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundStartDayButton extends StatefulWidget {
  const _RoundStartDayButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_RoundStartDayButton> createState() => _RoundStartDayButtonState();
}

class _RoundStartDayButtonState extends State<_RoundStartDayButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final buttonSize = (MediaQuery.sizeOf(context).width * 0.3).clamp(
      116.0,
      138.0,
    );
    final innerSize = buttonSize - 16;

    return Semantics(
      button: true,
      label: 'Start day',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) async {
            setState(() => _pressed = true);
            await Future<void>.delayed(const Duration(milliseconds: 120));
            if (!mounted) return;
            setState(() => _pressed = false);
            widget.onPressed();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              width: buttonSize,
              height: buttonSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF121719),
                border: Border.all(color: const Color(0xFFE3E8EA), width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xCC000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                width: innerSize,
                height: innerSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF171D20),
                  border: Border.all(color: _green, width: 5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xAA20F060),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StartButtonText(
                      'START',
                      color: Color(0xFFF2F6F7),
                      fontSize: 20,
                    ),
                    SizedBox(height: 4),
                    _StartButtonText('DAY', color: _green, fontSize: 23),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartButtonText extends StatelessWidget {
  const _StartButtonText(
    this.text, {
    required this.color,
    required this.fontSize,
  });

  final String text;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        height: 1,
        letterSpacing: 0,
        shadows: [
          Shadow(color: color, offset: const Offset(0.38, 0)),
          Shadow(color: color, offset: const Offset(-0.38, 0)),
          Shadow(color: color, offset: const Offset(0, 0.28)),
        ],
      ),
    );
  }
}

const _green = Color(0xFF20F060);
const _blue = Color(0xFF34A9E8);
