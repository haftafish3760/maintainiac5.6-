class SignedDocumentFingerprint {
  const SignedDocumentFingerprint({
    required this.subtotalCents,
    required this.discountCents,
    required this.taxCents,
    required this.totalCents,
    required this.lineItemFingerprint,
  });

  final int subtotalCents;
  final int discountCents;
  final int taxCents;
  final int totalCents;
  final String lineItemFingerprint;

  @override
  bool operator ==(Object other) {
    return other is SignedDocumentFingerprint &&
        other.subtotalCents == subtotalCents &&
        other.discountCents == discountCents &&
        other.taxCents == taxCents &&
        other.totalCents == totalCents &&
        other.lineItemFingerprint == lineItemFingerprint;
  }

  @override
  int get hashCode {
    return Object.hash(
      subtotalCents,
      discountCents,
      taxCents,
      totalCents,
      lineItemFingerprint,
    );
  }
}

bool shouldInvalidateCustomerSignature({
  required SignedDocumentFingerprint signedFingerprint,
  required SignedDocumentFingerprint currentFingerprint,
}) {
  return signedFingerprint != currentFingerprint;
}

String customerSignatureInvalidationMessage() {
  return 'Invoice totals or line items changed. The customer signature must be collected again.';
}
