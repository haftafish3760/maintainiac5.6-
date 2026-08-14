part of 'maintenance_receipt_parser.dart';

String? _waterPumpType(String text) {
  if (RegExp(r'\belectric (?:water |coolant )?pump\b').hasMatch(text)) {
    return 'Electric';
  }
  if (RegExp(r'\bmechanical (?:water |coolant )?pump\b').hasMatch(text)) {
    return 'Mechanical';
  }
  return null;
}

String? _thermostatTemperatureRating(String text) {
  final match = RegExp(
    r'\b(160|180|192|195|203)\s*(?:°|degrees?\s*)?f\b',
  ).firstMatch(text);
  return match == null ? null : '${match.group(1)}°F';
}
