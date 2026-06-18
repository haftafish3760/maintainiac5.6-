import 'package:flutter/material.dart';

class ReceiptFormPanel extends StatelessWidget {
  const ReceiptFormPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    this.accentColor = const Color(0xFFFFD166),
    this.trailing,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final Color accentColor;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C363B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF657279), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 3, color: accentColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 31,
                        height: 31,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF11181B),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFF56666E)),
                        ),
                        child: Icon(icon, color: accentColor, size: 18),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE8ECEE),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing!,
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Color(0xFFC7D0D4),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.18,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
