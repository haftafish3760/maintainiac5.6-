import 'package:flutter/material.dart';

import 'app_signature_models.dart';

class AppSignatureCaptureSheet extends StatefulWidget {
  const AppSignatureCaptureSheet({
    required this.role,
    required this.title,
    super.key,
  });

  final AppSignatureRole role;
  final String title;

  @override
  State<AppSignatureCaptureSheet> createState() =>
      _AppSignatureCaptureSheetState();
}

class _AppSignatureCaptureSheetState extends State<AppSignatureCaptureSheet> {
  final _strokes = <AppSignatureStroke>[];
  var _activePoints = <Offset>[];

  bool get _hasInk {
    return _strokes.any((stroke) => stroke.points.length > 1) ||
        _activePoints.length > 1;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          MediaQuery.viewInsetsOf(context).bottom + 14,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use your finger or stylus to sign inside the box.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _SignatureCanvas(
              strokes: _strokes,
              activePoints: _activePoints,
              onStart: _startStroke,
              onUpdate: _appendPoint,
              onEnd: _finishStroke,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _hasInk ? _clear : null,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _hasInk ? _save : null,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save Signature'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startStroke(Offset point) {
    setState(() => _activePoints = [point]);
  }

  void _appendPoint(Offset point) {
    setState(() => _activePoints = [..._activePoints, point]);
  }

  void _finishStroke() {
    if (_activePoints.isEmpty) return;
    setState(() {
      _strokes.add(
        AppSignatureStroke(List<Offset>.unmodifiable(_activePoints)),
      );
      _activePoints = [];
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _activePoints = [];
    });
  }

  void _save() {
    final allStrokes = [
      ..._strokes,
      if (_activePoints.isNotEmpty)
        AppSignatureStroke(List<Offset>.unmodifiable(_activePoints)),
    ];
    Navigator.of(context).pop(
      AppSignatureResult(
        role: widget.role,
        strokes: List<AppSignatureStroke>.unmodifiable(allStrokes),
        signedAt: DateTime.now(),
      ),
    );
  }
}

class _SignatureCanvas extends StatelessWidget {
  const _SignatureCanvas({
    required this.strokes,
    required this.activePoints,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  final List<AppSignatureStroke> strokes;
  final List<Offset> activePoints;
  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.45,
      child: LayoutBuilder(
        builder: (context, constraints) {
          Offset localPoint(Offset globalPosition) {
            final box = context.findRenderObject()! as RenderBox;
            final local = box.globalToLocal(globalPosition);
            return Offset(
              local.dx.clamp(0, constraints.maxWidth),
              local.dy.clamp(0, constraints.maxHeight),
            );
          }

          return GestureDetector(
            key: const Key('app-signature-canvas'),
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) =>
                onStart(localPoint(details.globalPosition)),
            onPanUpdate: (details) =>
                onUpdate(localPoint(details.globalPosition)),
            onPanEnd: (_) => onEnd(),
            child: Semantics(
              label: 'Signature drawing area',
              child: CustomPaint(
                painter: _SignaturePainter(
                  strokes: strokes,
                  activePoints: activePoints,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({required this.strokes, required this.activePoints});

  final List<AppSignatureStroke> strokes;
  final List<Offset> activePoints;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFE7ECEF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(5)),
      background,
    );
    final border = Paint()
      ..color = const Color(0xFF101416)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(5)),
      border,
    );
    final guide = Paint()
      ..color = const Color(0x552E3A40)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * .08, size.height * .72),
      Offset(size.width * .92, size.height * .72),
      guide,
    );
    final ink = Paint()
      ..color = const Color(0xFF101416)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, ink);
    }
    _drawStroke(canvas, activePoints, ink);
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.activePoints != activePoints;
  }
}
