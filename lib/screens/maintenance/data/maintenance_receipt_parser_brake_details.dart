part of 'maintenance_receipt_parser.dart';

String? _brakeAxle(String text) {
  final axleMatch = RegExp(
    r'\b(front|rear)\b[^\n]{0,32}\b(?:brake|pads?|rotors?|shoes?|drums?)\b',
  ).firstMatch(text);
  final axle = axleMatch?.group(1);
  if (axle == null) return null;
  return axle == 'front' ? 'Front' : 'Rear';
}

String? _brakeFrictionMaterial(String text) {
  if (RegExp(r'\bsemi[- ]?metallic\b').hasMatch(text)) {
    return 'Semi-metallic';
  }
  if (RegExp(r'\bceramic\b').hasMatch(text)) return 'Ceramic';
  if (RegExp(r'\borganic\b').hasMatch(text)) return 'Organic';
  return null;
}

String? _brakeHardwareServiceType(String text) {
  if (RegExp(r'\b(?:rebuilt|remanufactured)\b').hasMatch(text)) {
    return 'Rebuilt';
  }
  if (RegExp(
    r'\b(?:resurfac(?:e|ed|ing)|machin(?:e|ed|ing)|turned)\b',
  ).hasMatch(text)) {
    return 'Resurfaced';
  }
  if (RegExp(r'\b(?:replac(?:e|ed|ement)|installed)\b').hasMatch(text)) {
    return 'Replacement';
  }
  return null;
}
