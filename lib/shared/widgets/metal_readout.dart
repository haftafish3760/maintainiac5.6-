import 'package:flutter/material.dart';

class MetalReadout extends StatelessWidget {
  const MetalReadout({
    required this.label,
    required this.value,
    required this.color,
    this.helper,
    this.onTapLabel,
    this.compact = false,
    super.key,
  });

  final String label;
  final String value;
  final Color color;
  final String? helper;
  final String? onTapLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTapLabel != null,
      label: onTapLabel,
      child: Container(
        padding: compact
            ? const EdgeInsets.fromLTRB(7, 5, 7, 6)
            : const EdgeInsets.fromLTRB(8, 7, 8, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF2F5F5), Color(0xFFB9C1C4), Color(0xFF737D81)],
            stops: [0, 0.55, 1],
          ),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFF090B0C), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF101418),
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: compact ? 3 : 5),
            Container(
              height: compact ? 32 : 38,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF18200F), Color(0xFF050806)],
                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF2B3524), width: 1.1),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 23 : 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 0,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (helper != null) ...[
              const SizedBox(height: 6),
              Text(
                helper!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF111416),
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
