import 'package:flutter/material.dart';

enum AppSignatureRole { owner, customer }

class AppSignatureStroke {
  const AppSignatureStroke(this.points);

  final List<Offset> points;

  bool get isEmpty => points.isEmpty;
}

class AppSignatureResult {
  const AppSignatureResult({
    required this.role,
    required this.strokes,
    required this.signedAt,
  });

  final AppSignatureRole role;
  final List<AppSignatureStroke> strokes;
  final DateTime signedAt;

  bool get hasInk {
    return strokes.any((stroke) => stroke.points.length > 1);
  }
}

Map<String, dynamic> appSignatureToMap(AppSignatureResult signature) {
  return {
    'role': signature.role.name,
    'signedAt': signature.signedAt.toIso8601String(),
    'strokes': [
      for (final stroke in signature.strokes)
        [
          for (final point in stroke.points) {'x': point.dx, 'y': point.dy},
        ],
    ],
  };
}

AppSignatureResult? appSignatureFromMap(Object? value) {
  if (value is! Map) return null;
  final roleName = value['role'];
  final signedAtValue = value['signedAt'];
  final strokesValue = value['strokes'];
  if (roleName is! String || signedAtValue is! String) return null;
  final role = AppSignatureRole.values
      .where((item) => item.name == roleName)
      .firstOrNull;
  final signedAt = DateTime.tryParse(signedAtValue);
  if (role == null || signedAt == null || strokesValue is! List) return null;
  final strokes = <AppSignatureStroke>[];
  for (final strokeValue in strokesValue) {
    if (strokeValue is! List) continue;
    final points = <Offset>[];
    for (final pointValue in strokeValue) {
      if (pointValue is! Map) continue;
      final x = _readDouble(pointValue['x']);
      final y = _readDouble(pointValue['y']);
      if (x == null || y == null) continue;
      points.add(Offset(x, y));
    }
    if (points.isNotEmpty) {
      strokes.add(AppSignatureStroke(List<Offset>.unmodifiable(points)));
    }
  }
  return AppSignatureResult(
    role: role,
    strokes: List<AppSignatureStroke>.unmodifiable(strokes),
    signedAt: signedAt,
  );
}

double? _readDouble(Object? value) {
  if (value is int) return value.toDouble();
  if (value is double) return value;
  return null;
}
