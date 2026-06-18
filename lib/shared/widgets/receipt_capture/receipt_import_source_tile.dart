part of 'receipt_attachment_panel.dart';

class _ReceiptImportTile extends StatelessWidget {
  const _ReceiptImportTile({required this.source});

  final _ReceiptImportSource source;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Semantics(
        button: true,
        label: source.label,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(source.action),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1416),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: source.color, width: 1.2),
                  ),
                  child: Icon(source.icon, color: source.color, size: 27),
                ),
                const SizedBox(height: 7),
                Text(
                  source.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
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
