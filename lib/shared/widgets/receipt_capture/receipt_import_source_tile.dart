part of 'receipt_attachment_panel.dart';

class _ReceiptImportTile extends StatelessWidget {
  const _ReceiptImportTile({required this.source});

  final _ReceiptImportSource source;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: source.label,
      hint: source.detail,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(source.action),
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF0E1416),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: source.color.withValues(alpha: .75)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: source.color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: source.color.withValues(alpha: .65),
                      ),
                    ),
                    child: Icon(source.icon, color: source.color, size: 22),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        source.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC8D0D3),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          height: 1.12,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
