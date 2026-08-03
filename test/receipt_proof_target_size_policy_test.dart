import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('five saved-proof choices have conservative 100 MB planning estimates', () {
    const expectedCapacities = {
      ReceiptDataSaverLevel.light: 111,
      ReceiptDataSaverLevel.balanced: 176,
      ReceiptDataSaverLevel.strong: 389,
      ReceiptDataSaverLevel.economy: 778,
      ReceiptDataSaverLevel.maximum: 1297,
    };

    for (final entry in expectedCapacities.entries) {
      final policy = entry.key.proofTargetSizePolicy;
      expect(policy.maxBytes, lessThanOrEqualTo(1000 * 1024));
      expect(policy.earlyAccessProofCapacity, entry.value);
      expect(
        policy.earlyAccessProofCapacityLabel,
        'About ${entry.value} saved proofs per 100 MB plan',
      );
    }
  });

  test('original receipt files are not presented as a backup-plan estimate', () {
    final policy = ReceiptDataSaverLevel.original.proofTargetSizePolicy;

    expect(policy.earlyAccessProofCapacity, 0);
    expect(policy.earlyAccessProofCapacityLabel, 'Kept on this device only');
  });
}
