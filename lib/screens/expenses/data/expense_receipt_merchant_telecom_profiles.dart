part of 'expense_receipt_parser.dart';

final _telecomMerchantProfiles = [
  _MerchantProfile(
    displayName: 'Verizon Wireless',
    pattern: RegExp(r'\b(verizon|vzw)\b'),
    defaultCategory: 'Cell Phone',
  ),
  _MerchantProfile(
    displayName: 'T-Mobile',
    pattern: RegExp(r'\b(t-mobile|tmobile)\b'),
    defaultCategory: 'Cell Phone',
  ),
  _MerchantProfile(
    displayName: 'AT&T',
    pattern: RegExp(r'\b(at&t|att wireless|att)\b'),
    defaultCategory: 'Cell Phone',
  ),
];
