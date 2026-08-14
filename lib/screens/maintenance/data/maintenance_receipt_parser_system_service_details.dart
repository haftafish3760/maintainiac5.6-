part of 'maintenance_receipt_parser.dart';

String? _fuelSystemServiceType(String text) {
  if (RegExp(r'\bthrottle body cleaning\b').hasMatch(text)) {
    return 'Throttle body cleaning';
  }
  if (RegExp(r'\binduction service\b').hasMatch(text)) {
    return 'Induction cleaning';
  }
  if (RegExp(
    r'\bfuel (?:injection service|injector cleaning)\b',
  ).hasMatch(text)) {
    return 'Fuel injector cleaning';
  }
  return null;
}

String? _airConditioningServiceType(String text) {
  if (RegExp(r'\b(?:evac(?:uate|uation)|recover)\b').hasMatch(text)) {
    return 'Evacuation and recharge';
  }
  if (RegExp(r'\b(?:recharge|refrigerant)\b').hasMatch(text)) {
    return 'Refrigerant recharge';
  }
  return 'Performance check';
}

String? _airConditioningRefrigerant(String text) {
  if (RegExp(r'\br-?1234yf\b').hasMatch(text)) return 'R-1234yf';
  if (RegExp(r'\br-?134a\b').hasMatch(text)) return 'R-134a';
  return null;
}
