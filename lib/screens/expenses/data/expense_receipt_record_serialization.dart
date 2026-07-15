part of 'expense_ledger_models.dart';

extension ExpenseReceiptRecordSerialization on ExpenseReceiptRecord {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receiptDate': receiptDate.toIso8601String(),
      'receiptTimeMinutes': receiptTimeMinutes,
      'merchantName': merchantName,
      'phone': phone,
      'street': street,
      'city': city,
      'state': state,
      'zip': zip,
      'email': email,
      'website': website,
      'notes': notes,
      'receiptNumber': receiptNumber,
      'paymentMethod': paymentMethod,
      'hasReceiptProof': hasReceiptProof,
      'attachments': [for (final attachment in attachments) attachment.toMap()],
      'rawOcrText': rawOcrText,
      'ocrReview': ocrReview.toMap(),
      'enteredSubtotal': enteredSubtotal,
      'enteredTax': enteredTax,
      'enteredTotal': enteredTotal,
      'enteredSubtotalCents': enteredSubtotalCents,
      'enteredTaxCents': enteredTaxCents,
      'enteredTotalCents': enteredTotalCents,
      'trackMaterialsInInventory': trackMaterialsInInventory,
      'vehicleId': vehicleId,
      'contextSnapshot': contextSnapshot.toMap(),
      'odometerReading': odometerReading,
      'sourceScreen': sourceScreen,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'auditEvents': auditEvents,
      'fileHashSha256': primaryFileHashSha256,
      'duplicateCheckStatus': duplicateCheckStatus.name,
      'duplicateCandidates': [
        for (final candidate in duplicateCandidates) candidate.toMap(),
      ],
      'duplicateOverride': duplicateOverride,
      'duplicateOverrideReason': duplicateOverrideReason,
      'duplicateCheckedAt': duplicateCheckedAt?.toIso8601String(),
      'lines': [for (final line in lines) line.toMap()],
    };
  }
}
