part of 'maintenance_receipt_parser.dart';

String? _wheelAlignmentType(String text) {
  if (RegExp(r'\bfour[- ]wheel alignment\b').hasMatch(text)) {
    return 'Four-wheel';
  }
  if (RegExp(r'\bfront[- ]end alignment\b').hasMatch(text)) {
    return 'Front-end';
  }
  return null;
}

String? _wheelBalancingType(String text) {
  if (RegExp(r'\broad force balanc(?:e|ing)\b').hasMatch(text)) {
    return 'Road force';
  }
  if (RegExp(r'\bcomputer(?:ized)? balanc(?:e|ing)\b').hasMatch(text)) {
    return 'Computerized';
  }
  return null;
}
