part of 'receipt_layout_intelligence.dart';

final _datePattern = RegExp(
  r'\b(?:\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}[/-]\d{1,2}[/-]\d{1,2})\b',
);
final _timePattern = RegExp(
  r'\b\d{1,2}:\d{2}(?::\d{2})?\s*(?:am|pm)?\b',
  caseSensitive: false,
);
final _moneyPattern = RegExp(
  r'(?:^|[\s:])(?:-|\()?[$]?\d{1,5}(?:,\d{3})*[.]\d{2}\)?\b',
);
final _phonePattern = RegExp(r'\b(?:\(?\d{3}\)?[-.\s])?\d{3}[-.\s]\d{4}\b');
final _addressPattern = RegExp(
  r'\b\d{2,6}\s+[a-z0-9 .#-]+\s+(?:st|street|rd|road|ave|avenue|blvd|lane|ln|drive|dr|hwy|highway|pkwy|parkway)\b',
  caseSensitive: false,
);
final _transactionPattern = RegExp(
  r'\b(?:sale|sales[#:]?|trans(?:action)?[#:]?|terminal|store[#:]?|invoice|auth(?:code)?|approval|order[#:]?|receipt[#:]?|cashier|register)\b',
);
final _subtotalPattern = RegExp(
  r'\b(?:subtotal|sub total|sub-total|merchandise total|item total|items total|pre[- ]?tax total)\b',
);
final _taxPattern = RegExp(
  r'\b(?:sales tax|tax|state tax|local tax|county tax|city tax)\b',
);
final _totalPattern = RegExp(
  r'\b(?:total|grand total|order total|purchase total|amount paid|balance due)\b',
);
final _paymentPattern = RegExp(
  r'\b(?:visa|mastercard|amex|discover|debit|credit|cash|card|gift card|tender|payment|change due|authcode|approval)\b',
);
final _barcodePattern = RegExp(
  r'\b(?:barcode|bar code|upc|ean|gtin|qr code)\b',
);
final _footerPattern = RegExp(
  r'\b(?:thank you|return policy|survey|customer service|store manager|price promise|visit|www\.|\.com|coupon|rewards)\b',
);
final _administrativeHeaderPattern = RegExp(
  r'\b(?:sale|receipt|invoice|terminal|transaction|trans|store|cashier|register)\b',
);
final _merchantTextPattern = RegExp(r'[A-Za-z]{2,}');
