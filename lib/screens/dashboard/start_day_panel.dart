import 'package:flutter/material.dart';

class PreDayStartContent extends StatelessWidget {
  const PreDayStartContent({super.key, required this.onStartDay});

  final VoidCallback onStartDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StartMyDayPanel(onStartDay: onStartDay),
        const SizedBox(height: 8),
        const _WeeklyRecapPanel(),
      ],
    );
  }
}

class _WeeklyRecapPanel extends StatelessWidget {
  const _WeeklyRecapPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
        decoration: BoxDecoration(
          color: const Color(0xFF242C30),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF566269)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 9,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(child: _SectionPlateTitle('Weekly recap')),
                Text(
                  'May 18-24',
                  style: TextStyle(
                    color: Color(0xFFC6D0D4),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            const Row(
              children: [
                Expanded(
                  child: _CompactRecapReadout(
                    label: 'Gross',
                    value: r'$2,184',
                    color: Color(0xFF27D56B),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: _CompactRecapReadout(
                    label: 'Expenses',
                    value: r'$421',
                    color: Color(0xFFFF3B30),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: _CompactRecapReadout(
                    label: 'Profit',
                    value: r'$1,763',
                    color: Color(0xFF27D56B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Row(
              children: [
                Expanded(
                  child: _CompactRecapReadout(
                    label: 'Miles',
                    value: '386.4',
                    color: Color(0xFF34A9E8),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: _CompactRecapReadout(
                    label: 'Pay/Hr',
                    value: r'$44.80',
                    color: Color(0xFF27D56B),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: _CompactRecapReadout(
                    label: 'Pay/Mi',
                    value: r'$4.56',
                    color: Color(0xFF27D56B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StartMyDayPanel extends StatelessWidget {
  const _StartMyDayPanel({required this.onStartDay});

  final VoidCallback onStartDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF20282C),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF536068)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PanelTitle('Ready to track'),
                  SizedBox(height: 4),
                  Text(
                    'Start the work day when you are ready to log miles, stops, fuel, and expenses.',
                    style: TextStyle(
                      color: Color(0xFFCAD2D5),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _RoundStartDayButton(onPressed: onStartDay),
          ],
        ),
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
    final buttonSize = (MediaQuery.sizeOf(context).width * 0.24).clamp(
      92.0,
      108.0,
    );
    final innerSize = buttonSize - 12;

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
            if (!mounted) {
              return;
            }
            setState(() => _pressed = false);
            widget.onPressed();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              width: buttonSize,
              height: buttonSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pressed
                    ? const Color(0xFF0A0D0E)
                    : const Color(0xFF121719),
                border: Border.all(color: const Color(0xFFE3E8EA), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xCC000000),
                    blurRadius: _pressed ? 5 : 14,
                    offset: Offset(0, _pressed ? 2 : 6),
                  ),
                ],
              ),
              child: Container(
                width: innerSize,
                height: innerSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pressed
                      ? const Color(0xFF101416)
                      : const Color(0xFF171D20),
                  border: Border.all(color: const Color(0xFF20F060), width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xAA20F060),
                      blurRadius: _pressed ? 5 : 12,
                      spreadRadius: _pressed ? 0 : 1,
                    ),
                    BoxShadow(
                      color: const Color(0xAA000000),
                      blurRadius: _pressed ? 3 : 5,
                      offset: Offset(0, _pressed ? 1 : 3),
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(8, 11, 8, 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StartButtonText(
                        'START',
                        color: Color(0xFFF2F6F7),
                        fontSize: 18,
                      ),
                      SizedBox(height: 3),
                      _StartButtonText(
                        'DAY',
                        color: Color(0xFF20F060),
                        fontSize: 20,
                      ),
                    ],
                  ),
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
      textScaler: TextScaler.noScaling,
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

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: const Color(0xFFE2E8EA),
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _SectionPlateTitle extends StatelessWidget {
  const _SectionPlateTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFFE2E8EA),
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _CompactRecapReadout extends StatelessWidget {
  const _CompactRecapReadout({
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
      height: 50,
      padding: const EdgeInsets.fromLTRB(5, 4, 5, 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2023),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF4D5960)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF050806),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF26331E), width: 1.1),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 0,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.38),
                        blurRadius: 7,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
