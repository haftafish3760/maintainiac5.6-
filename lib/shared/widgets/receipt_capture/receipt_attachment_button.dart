part of 'receipt_attachment_panel.dart';

class _ReceiptButton extends StatelessWidget {
  const _ReceiptButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: FittedBox(child: Text(label)),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF1976B9),
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}
