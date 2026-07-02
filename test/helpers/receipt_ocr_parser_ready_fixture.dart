import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

ReceiptOcrResult parserReadyLowesReceiptResult() {
  const result = ReceiptOcrResult(
    rawText: '''
  LOWE'S HOME CENTERS, LLC
  6400 BRODIE LANE
  AUSTIN, TX 78745
  07/09/21 13:14:57
  23536 OATEY 14-OZ PLUMBERS PUTT        2.99
  SUBTOTAL:                              2.99
  TAX:                                   0.25
  INVOICE 18934 TOTAL:                   3.24
  MERCH/GIFT CARDS :                     3.24
  MERCH/GIFT CARD 5715 AUTHCODE 370
  THANK YOU FOR SHOPPING LOWE'S.
  ''',
    parserText: '''
  LOWE'S HOME CENTERS, LLC
  6400 BRODIE LANE
  AUSTIN, TX 78745
  07/09/21 13:14:57
  23536 OATEY 14-OZ PLUMBERS PUTT        2.99
  SUBTOTAL:                              2.99
  TAX:                                   0.25
  INVOICE 18934 TOTAL:                   3.24
  MERCH/GIFT CARDS :                     3.24
  MERCH/GIFT CARD 5715 AUTHCODE 370
  THANK YOU FOR SHOPPING LOWE'S.
  ''',
    textByAttachmentId: {'photo-1': 'LOWES'},
    source: ReceiptProcessingSource.photo,
  );

  return result;
}
