import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'action_tile.dart';
import 'industrial_panel.dart';

class ReceiptCaptureSection extends StatefulWidget {
  const ReceiptCaptureSection({required this.onAttachmentChanged, super.key});

  final ValueChanged<bool> onAttachmentChanged;

  @override
  State<ReceiptCaptureSection> createState() => _ReceiptCaptureSectionState();
}

class _ReceiptCaptureSectionState extends State<ReceiptCaptureSection> {
  bool _hasAttachment = false;
  int _level = 1;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attach Maintenance Receipt',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Optional: capture a photo, upload an image, or upload a PDF of your receipt.',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ActionTile(
                  label: 'Take Photo',
                  icon: '📷',
                  color: AppColors.blue,
                  height: 72,
                  onTap: _attach,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ActionTile(
                  label: 'Upload Photo',
                  icon: '🖼️',
                  color: AppColors.blue,
                  height: 72,
                  onTap: _attach,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ActionTile(
                  label: 'Upload PDF',
                  icon: '📄',
                  color: AppColors.blue,
                  height: 72,
                  onTap: _attach,
                ),
              ),
            ],
          ),
          if (_hasAttachment) ...[
            const SizedBox(height: 12),
            const Text(
              'Data Saver Preview',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _CompressionOption(
                  index: i,
                  selected: _level == i,
                  onTap: () => setState(() => _level = i),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _attach() {
    setState(() => _hasAttachment = true);
    widget.onAttachmentChanged(true);
  }
}

class _CompressionOption extends StatelessWidget {
  const _CompressionOption({
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labels = ['Original', 'Light', 'Balanced', 'Small', 'Smallest'];
    final sizes = ['1.8 MB', '920 KB', '420 KB', '240 KB', '160 KB'];
    final clarity = [0.96, 0.84, 0.72, 0.58, 0.42][index];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Ink(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: selected ? AppColors.green : Colors.white24,
          ),
        ),
        child: Row(
          children: [
            _MiniReceiptPreview(clarity: clarity),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${labels[index]} - about ${sizes[index]}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniReceiptPreview extends StatelessWidget {
  const _MiniReceiptPreview({required this.clarity});

  final double clarity;

  @override
  Widget build(BuildContext context) {
    final alpha = clarity.clamp(0.35, 1.0);
    return Container(
      width: 58,
      height: 72,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFAAB4B9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(0.8, alpha),
          const SizedBox(height: 4),
          _line(1, alpha),
          const SizedBox(height: 3),
          _line(0.65, alpha),
          const SizedBox(height: 3),
          _line(0.92, alpha),
          const Spacer(),
          _line(0.55, alpha, thick: true),
        ],
      ),
    );
  }

  Widget _line(double width, double alpha, {bool thick = false}) {
    return FractionallySizedBox(
      widthFactor: width,
      child: Container(
        height: thick ? 5 : 3,
        color: Colors.black.withValues(alpha: alpha),
      ),
    );
  }
}
