import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/signatures/app_signature_guard.dart';

void main() {
  const signed = SignedDocumentFingerprint(
    subtotalCents: 10000,
    discountCents: 0,
    taxCents: 530,
    totalCents: 10530,
    lineItemFingerprint: 'labor:1:7500|materials:1:2500',
  );

  test('unchanged invoice keeps customer signature valid', () {
    expect(
      shouldInvalidateCustomerSignature(
        signedFingerprint: signed,
        currentFingerprint: signed,
      ),
      isFalse,
    );
  });

  test('price increase invalidates customer signature', () {
    const changed = SignedDocumentFingerprint(
      subtotalCents: 11000,
      discountCents: 0,
      taxCents: 583,
      totalCents: 11583,
      lineItemFingerprint: 'labor:1:8500|materials:1:2500',
    );

    expect(
      shouldInvalidateCustomerSignature(
        signedFingerprint: signed,
        currentFingerprint: changed,
      ),
      isTrue,
    );
  });

  test('price decrease invalidates customer signature', () {
    const changed = SignedDocumentFingerprint(
      subtotalCents: 9000,
      discountCents: 0,
      taxCents: 477,
      totalCents: 9477,
      lineItemFingerprint: 'labor:1:6500|materials:1:2500',
    );

    expect(
      shouldInvalidateCustomerSignature(
        signedFingerprint: signed,
        currentFingerprint: changed,
      ),
      isTrue,
    );
  });

  test('line item change invalidates customer signature', () {
    const changed = SignedDocumentFingerprint(
      subtotalCents: 10000,
      discountCents: 0,
      taxCents: 530,
      totalCents: 10530,
      lineItemFingerprint: 'labor:1:7500|materials:2:1250',
    );

    expect(
      shouldInvalidateCustomerSignature(
        signedFingerprint: signed,
        currentFingerprint: changed,
      ),
      isTrue,
    );
    expect(
      customerSignatureInvalidationMessage(),
      contains('customer signature must be collected again'),
    );
  });
}
