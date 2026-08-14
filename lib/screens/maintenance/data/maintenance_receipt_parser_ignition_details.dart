part of 'maintenance_receipt_parser.dart';

String? _ignitionCoilType(String text) {
  if (RegExp(r'\bcoil-on-plug\b').hasMatch(text)) return 'Coil-on-plug';
  if (RegExp(r'\bcoil packs?\b').hasMatch(text)) return 'Coil pack';
  if (RegExp(r'\bignition coils?\b').hasMatch(text)) return 'Individual coil';
  return null;
}

String? _sparkPlugWireType(String text) {
  if (RegExp(
    r'\bperformance (?:spark plug |ignition )?wires?\b',
  ).hasMatch(text)) {
    return 'Performance';
  }
  if (RegExp(r'\b(?:spark plug wires?|ignition wire sets?)\b').hasMatch(text)) {
    return 'Standard';
  }
  return null;
}
