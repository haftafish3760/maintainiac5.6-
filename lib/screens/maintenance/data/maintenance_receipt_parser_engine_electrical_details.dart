part of 'maintenance_receipt_parser.dart';

String? _engineElectricalComponentType(String text) {
  if (RegExp(r'\b(?:remanufactured|reman|rebuilt)\b').hasMatch(text)) {
    return 'Remanufactured';
  }
  if (RegExp(r'\bnew\b').hasMatch(text)) return 'New';
  return null;
}
