part of 'maintenance_receipt_parser.dart';

String? _suspensionServicePosition(String text) {
  final match = RegExp(
    r'\b(front|rear)\b[^\n]{0,36}\b(?:shocks?|struts?|ball joints?|tie rods?|sway bar|stabilizer bar|wheel bearings?|wheel hub|cv axles?|drive axles?)\b',
  ).firstMatch(text);
  final position = match?.group(1);
  if (position == null) return null;
  return position == 'front' ? 'Front' : 'Rear';
}

String? _cvAxleType(String text) {
  if (RegExp(r'\bremanufactured (?:cv |drive )?axles?\b').hasMatch(text)) {
    return 'Remanufactured';
  }
  if (RegExp(r'\b(?:cv |drive )axles?\b').hasMatch(text)) return 'New';
  return null;
}

String? _shockAndStrutComponent(String text) {
  final hasShock = RegExp(r'\b(?:shock absorbers?|shocks?)\b').hasMatch(text);
  final hasStrut = RegExp(r'\bstruts?\b').hasMatch(text);
  if (hasShock && hasStrut) return 'Shocks and struts';
  if (hasStrut) return 'Struts';
  if (hasShock) return 'Shocks';
  return null;
}

String? _ballJointPosition(String text) {
  if (RegExp(r'\blower ball joints?\b').hasMatch(text)) return 'Lower';
  if (RegExp(r'\bupper ball joints?\b').hasMatch(text)) return 'Upper';
  return null;
}

String? _tieRodPosition(String text) {
  if (RegExp(r'\bouter tie rod').hasMatch(text)) return 'Outer';
  if (RegExp(r'\binner tie rod').hasMatch(text)) return 'Inner';
  return null;
}

String? _wheelBearingComponent(String text) {
  if (RegExp(r'\b(?:hub bearing|wheel hub) assembl').hasMatch(text)) {
    return 'Hub assembly';
  }
  if (RegExp(r'\bwheel bearings?\b').hasMatch(text)) return 'Bearing';
  return null;
}
