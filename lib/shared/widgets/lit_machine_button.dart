import 'package:flutter/material.dart';

class LitMachineButton extends StatelessWidget {
  const LitMachineButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.compact = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 92 : 104,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFF1F4F4),
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: compact ? 4 : 5),
              Container(
                width: compact ? 58 : 66,
                height: compact ? 58 : 66,
                padding: EdgeInsets.all(compact ? 4 : 5),
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    center: Alignment(-0.36, -0.38),
                    radius: 1,
                    colors: [
                      Color(0xFFE2E6E7),
                      Color(0xFF838C8F),
                      Color(0xFF333A3D),
                    ],
                    stops: [0, 0.5, 1],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xAA000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.35, -0.36),
                          radius: 0.95,
                          colors: [
                            Color.lerp(color, Colors.white, 0.58)!,
                            color,
                            Color.lerp(color, Colors.black, 0.32)!,
                          ],
                          stops: const [0, 0.62, 1],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: compact ? 36 : 42,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
