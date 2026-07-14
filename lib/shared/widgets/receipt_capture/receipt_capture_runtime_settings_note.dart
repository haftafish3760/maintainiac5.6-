part of 'receipt_attachment_panel.dart';

class _ReceiptSettingsNote extends StatelessWidget {
  const _ReceiptSettingsNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161D20),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF3D4A50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFFD166), size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
