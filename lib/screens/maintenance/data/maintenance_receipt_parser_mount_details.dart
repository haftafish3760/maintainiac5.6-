part of 'maintenance_receipt_parser.dart';

String? _engineMountType(String text) {
  if (RegExp(r'\bactive (?:engine |motor )?mounts?\b').hasMatch(text)) {
    return 'Active';
  }
  if (RegExp(r'\bhydraulic (?:engine |motor )?mounts?\b').hasMatch(text)) {
    return 'Hydraulic';
  }
  if (RegExp(
    r'\b(?:rubber|solid) (?:engine |motor )?mounts?\b',
  ).hasMatch(text)) {
    return 'Rubber';
  }
  if (RegExp(r'\b(?:engine|motor) mounts?\b').hasMatch(text)) return 'Other';
  return null;
}
