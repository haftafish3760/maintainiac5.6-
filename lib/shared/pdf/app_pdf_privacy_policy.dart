import 'dart:convert';

class AppPdfPrivacyPolicy {
  const AppPdfPrivacyPolicy._();

  static const vin = 'private_vin';
  static const licensePlate = 'private_license_plate';
  static const passengerData = 'private_passenger_data';
  static const patientData = 'private_patient_data';
  static const paymentFragment = 'private_payment_fragment';
  static const unconfirmedOcrSuggestion = 'unconfirmed_ocr_suggestion';
  static const privateSourcePath = 'private_source_path';
  static const internalId = 'internal_id';

  static List<String> issueCodesForExport({
    required List<int> bytes,
    Iterable<String> metadata = const [],
  }) {
    final text = [
      latin1.decode(bytes, allowInvalid: true),
      ...metadata,
    ].join('\n').toLowerCase();
    final issues = <String>[];
    if (_containsVin(text)) issues.add(vin);
    if (_containsLicensePlate(text)) issues.add(licensePlate);
    if (_containsPassengerData(text)) issues.add(passengerData);
    if (_containsPatientData(text)) issues.add(patientData);
    if (_containsPaymentFragment(text)) issues.add(paymentFragment);
    if (_containsUnconfirmedOcrSuggestion(text)) {
      issues.add(unconfirmedOcrSuggestion);
    }
    if (_containsPrivateSourcePath(text)) issues.add(privateSourcePath);
    if (_containsInternalId(text)) issues.add(internalId);
    return issues.toSet().toList(growable: false);
  }

  static bool _containsVin(String text) {
    return RegExp(
      r'\b(?:vin|vehicle identification number)\s*[:#-]?\s*[a-hj-npr-z0-9]{17}\b',
    ).hasMatch(text);
  }

  static bool _containsLicensePlate(String text) {
    return RegExp(
      r'\b(?:license plate|plate number|tag number)\s*[:#-]?\s*[a-z0-9][a-z0-9 -]{2,10}\b',
    ).hasMatch(text);
  }

  static bool _containsPassengerData(String text) {
    return RegExp(
      r'\b(?:passenger|rider|pickup passenger|dropoff passenger)\s+(?:name|phone|email|address)\b',
    ).hasMatch(text);
  }

  static bool _containsPatientData(String text) {
    return RegExp(
      r'\b(?:patient\s+(?:name|phone|email|address|id)|medical record|mrn|diagnosis|hipaa)\s*[:#-]?\s*[a-z0-9]',
    ).hasMatch(text);
  }

  static bool _containsPaymentFragment(String text) {
    return RegExp(
      r'\b(?:card|cc|visa|mastercard|amex|discover)\s*(?:ending|last\s*4|#|number)?\s*[:#-]?\s*(?:x{2,}|[*]{2,}|[0-9 ]{4,})\b',
    ).hasMatch(text);
  }

  static bool _containsUnconfirmedOcrSuggestion(String text) {
    return RegExp(
      r'\b(?:unconfirmed|pending|raw)\s+ocr\s+(?:suggestion|text|result|candidate)\b',
    ).hasMatch(text);
  }

  static bool _containsPrivateSourcePath(String text) {
    return RegExp(
      r'(?:/users/[^ \r\n)]+|/var/mobile/containers/[^ \r\n)]+|content://[^ \r\n)]+|file://[^ \r\n)]+|[a-z]:\\users\\[^ \r\n)]+)',
    ).hasMatch(text);
  }

  static bool _containsInternalId(String text) {
    return RegExp(
      r'\b(?:internal id|internal-id|firebase id|firestore id|hive key|record uuid|document id)\s*[:#-]?\s*[a-z0-9_-]{6,}\b',
    ).hasMatch(text);
  }
}
