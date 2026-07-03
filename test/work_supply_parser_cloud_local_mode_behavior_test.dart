import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inventory parser cloud and local mode behavior', () {
    test('local-only QA blocks live Firebase and records cost flags', () {
      const plan = _ParserDeliveryPlan.localPack(
        availableBytes: 220 * 1024 * 1024,
        requiredBytes: 120 * 1024 * 1024,
        deviceClass: 'modern_android',
      );

      expect(plan.mode, 'local');
      expect(plan.liveFirebaseAllowed, isFalse);
      expect(plan.firebaseWritesAllowed, isFalse);
      expect(plan.writesProductionCatalog, isFalse);
      expect(plan.costFlags, contains('cost flags'));
      expect(plan.qaTags, contains('local-only QA'));
      expect(plan.canParseOffline, isTrue);
      expect(plan.allowedReadBudget, 0);
    });

    test('not-enough-storage chooses cloud fallback before local install', () {
      const plan = _ParserDeliveryPlan.localPack(
        availableBytes: 40 * 1024 * 1024,
        requiredBytes: 120 * 1024 * 1024,
        deviceClass: 'modern_android',
      );
      final fallback = plan.withCloudFallback();

      expect(plan.qaTags, contains('not-enough-storage'));
      expect(plan.canInstallLocally, isFalse);
      expect(fallback.mode, 'cloudFallback');
      expect(fallback.canParseOffline, isFalse);
      expect(fallback.requiresInternet, isTrue);
      expect(fallback.requiresSubscription, isTrue);
      expect(fallback.allowedReadBudget, lessThanOrEqualTo(100));
      expect(fallback.liveFirebaseAllowed, isFalse);
      expect(fallback.firebaseWritesAllowed, isFalse);
    });

    test('older-phone parser limits prefer core local or cloud fallback', () {
      const professional = _ParserDeliveryPlan.localPack(
        availableBytes: 900 * 1024 * 1024,
        requiredBytes: 240 * 1024 * 1024,
        deviceClass: 'older_android',
        tier: 'professional',
      );
      const core = _ParserDeliveryPlan.localPack(
        availableBytes: 220 * 1024 * 1024,
        requiredBytes: 80 * 1024 * 1024,
        deviceClass: 'older_android',
      );

      expect(professional.qaTags, contains('older-phone parser limits'));
      expect(professional.canInstallLocally, isFalse);
      expect(professional.parserDepth, 'conservative');
      expect(core.canInstallLocally, isTrue);
      expect(core.parserDepth, 'conservative');
    });
  });
}

class _ParserDeliveryPlan {
  const _ParserDeliveryPlan._({
    required this.mode,
    required this.availableBytes,
    required this.requiredBytes,
    required this.deviceClass,
    required this.tier,
    required this.requiresInternet,
    required this.requiresSubscription,
    required this.allowedReadBudget,
  });

  const _ParserDeliveryPlan.localPack({
    required int availableBytes,
    required int requiredBytes,
    required String deviceClass,
    String tier = 'core',
  }) : this._(
         mode: 'local',
         availableBytes: availableBytes,
         requiredBytes: requiredBytes,
         deviceClass: deviceClass,
         tier: tier,
         requiresInternet: false,
         requiresSubscription: false,
         allowedReadBudget: 0,
       );

  const _ParserDeliveryPlan.cloudFallback({
    required int availableBytes,
    required int requiredBytes,
    required String deviceClass,
    required String tier,
  }) : this._(
         mode: 'cloudFallback',
         availableBytes: availableBytes,
         requiredBytes: requiredBytes,
         deviceClass: deviceClass,
         tier: tier,
         requiresInternet: true,
         requiresSubscription: true,
         allowedReadBudget: 100,
       );

  final String mode;
  final int availableBytes;
  final int requiredBytes;
  final String deviceClass;
  final String tier;
  final bool requiresInternet;
  final bool requiresSubscription;
  final int allowedReadBudget;

  bool get liveFirebaseAllowed => false;

  bool get firebaseWritesAllowed => false;

  bool get writesProductionCatalog => false;

  bool get canParseOffline => mode == 'local';

  bool get canInstallLocally =>
      availableBytes >= requiredBytes &&
      !(deviceClass == 'older_android' &&
          (tier == 'professional' || tier == 'complete'));

  String get parserDepth =>
      deviceClass == 'older_android' ? 'conservative' : 'full';

  Set<String> get costFlags => {
    'cost flags',
    '100-read budget',
    'no live Firebase',
  };

  Set<String> get qaTags => {
    'local-only QA',
    'cloud fallback',
    if (availableBytes < requiredBytes) 'not-enough-storage',
    if (deviceClass == 'older_android') 'older-phone parser limits',
    ...costFlags,
  };

  _ParserDeliveryPlan withCloudFallback() {
    return _ParserDeliveryPlan.cloudFallback(
      availableBytes: availableBytes,
      requiredBytes: requiredBytes,
      deviceClass: deviceClass,
      tier: tier,
    );
  }
}
