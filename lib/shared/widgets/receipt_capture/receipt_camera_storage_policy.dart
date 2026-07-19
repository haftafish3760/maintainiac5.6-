part of 'receipt_assistance_policy.dart';

enum ReceiptCameraStorageBand { unknown, red, orange, yellow, green }

class ReceiptCameraStoragePolicy {
  const ReceiptCameraStoragePolicy._({
    required this.band,
    required this.freeStorageMb,
  });

  const ReceiptCameraStoragePolicy.unknown()
    : this._(band: ReceiptCameraStorageBand.unknown, freeStorageMb: null);

  factory ReceiptCameraStoragePolicy.forFreeStorageMb(int? freeStorageMb) {
    if (freeStorageMb == null) {
      return const ReceiptCameraStoragePolicy.unknown();
    }
    final safeMb = freeStorageMb < 0 ? 0 : freeStorageMb;
    final band = switch (safeMb) {
      <= 250 => ReceiptCameraStorageBand.red,
      < 500 => ReceiptCameraStorageBand.orange,
      < 1024 => ReceiptCameraStorageBand.yellow,
      _ => ReceiptCameraStorageBand.green,
    };
    return ReceiptCameraStoragePolicy._(band: band, freeStorageMb: safeMb);
  }

  final ReceiptCameraStorageBand band;
  final int? freeStorageMb;

  bool get captureCompletionAllowed => true;
  bool get isBelowSupportedFloor =>
      freeStorageMb != null && freeStorageMb! < 250;
  bool get cloudReliefRecommended =>
      band == ReceiptCameraStorageBand.red ||
      band == ReceiptCameraStorageBand.orange;
  bool get reduceTemporaryWork => band != ReceiptCameraStorageBand.green;

  String get policyCode => switch (band) {
    ReceiptCameraStorageBand.green => 'green_1gb_or_more',
    ReceiptCameraStorageBand.yellow => 'yellow_500mb_to_1gb',
    ReceiptCameraStorageBand.orange => 'orange_250mb_to_500mb',
    ReceiptCameraStorageBand.red => 'red_250mb_or_less',
    ReceiptCameraStorageBand.unknown => 'unknown_never_block_capture',
  };

  String get completionPolicyCode => isBelowSupportedFloor
      ? 'below_250mb_emergency_completion_never_block'
      : 'receipt_task_completion_always_allowed_for_storage';
}
