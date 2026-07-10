import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inventory parser admin privacy rollup behavior', () {
    test('admin rollup exposes allowed parser health fields only', () {
      const event = _ParserHealthEvent(
        deviceClass: 'modern flagship',
        deviceModel: 'Galaxy S24 Ultra',
        osVersion: 'Android 15',
        appVersion: '5.6.0',
        parserVersion: 'parser-2026.07.02',
        packVersion: 'plumbing-core-en-us-2026.07',
        trade: 'Plumbing',
        itemId: 'PLUMBING-PEX-CRIMP-90-1-2',
        failureCategory: 'ambiguous_match',
        candidateCount: 3,
        reviewStatus: 'needsReview',
        merchantType: 'big_box',
        rawReceiptText: 'LOWES VISA 1111 JOHN SMITH 1/2 PEX CRMP ELL',
        cardNumber: '4111111111111111',
        lastFour: '1111',
        customerName: 'John Smith',
        email: 'john@example.com',
        phone: '804-555-1212',
        address: '123 Main Street',
        gpsCoordinates: '37.5407,-77.4360',
        photoPath: '/private/receipt.jpg',
        receiptImageBytes: 2048,
      );

      final rollup = _adminRollupFor(event);

      expect(rollup.keys.toSet(), _allowedRollupFields);
      expect(rollup['device class'], 'modern flagship');
      expect(rollup['device model'], 'Galaxy S24 Ultra');
      expect(rollup['os version'], 'Android 15');
      expect(rollup['app version'], '5.6.0');
      expect(rollup['parser version'], 'parser-2026.07.02');
      expect(rollup['pack version'], 'plumbing-core-en-us-2026.07');
      expect(rollup['trade'], 'Plumbing');
      expect(rollup['item id'], 'PLUMBING-PEX-CRIMP-90-1-2');
      expect(rollup['failure category'], 'ambiguous_match');
      expect(rollup['candidate count'], 3);
      expect(rollup['review status'], 'needsReview');
      expect(rollup['merchant type'], 'big_box');
    });

    test('admin rollup blocks private receipt and user fields', () {
      final rollup = _adminRollupFor(_privateEvent);

      for (final blocked in _blockedAdminFields) {
        expect(
          rollup.containsKey(blocked),
          isFalse,
          reason: 'blocked admin field leaked: $blocked',
        );
      }
      final serialized = rollup.toString();
      for (final privateValue in _privateValues) {
        expect(
          serialized.contains(privateValue),
          isFalse,
          reason: 'private value leaked into admin rollup: $privateValue',
        );
      }
    });

    test('admin diagnostics are aggregate-first by failure trade device and pack',
        () {
      final summary = _aggregateAdminRollups([
        _privateEvent,
        _privateEvent.copyWith(
          trade: 'Electrical',
          failureCategory: 'unknown_item',
          packVersion: 'electrical-core-en-us-2026.07',
          deviceClass: 'older phone',
        ),
        _privateEvent.copyWith(
          failureCategory: 'ambiguous_match',
          itemId: 'PLUMBING-PVC-90-3-4',
        ),
      ]);

      expect(summary.totalEvents, 3);
      expect(summary.byFailureCategory, {
        'ambiguous_match': 2,
        'unknown_item': 1,
      });
      expect(summary.byTrade, {'Plumbing': 2, 'Electrical': 1});
      expect(summary.byDeviceClass, {'modern flagship': 2, 'older phone': 1});
      expect(summary.byPackVersion, {
        'plumbing-core-en-us-2026.07': 2,
        'electrical-core-en-us-2026.07': 1,
      });
      expect(summary.rawEventsStored, isFalse);
    });

    test('admin rollup read and write budgets stay under daily cap', () {
      const policy = _AdminRollupBudgetPolicy(
        syncIntervalHours: 8,
        maxReadsPerSync: 18,
        maxWritesPerSync: 10,
        manualRefreshReads: 12,
        manualRefreshWrites: 4,
        maxManualRefreshesPerDay: 1,
      );

      expect(policy.dailyReadBudget, 66);
      expect(policy.dailyWriteBudget, 34);
      expect(policy.withinHundredReadsWritesPerDay, isTrue);
      expect(policy.realTimeRequired, isFalse);
    });

    test('major incident alert is summarized without raw receipt content', () {
      final alert = _majorIncidentAlert([
        _privateEvent,
        _privateEvent.copyWith(deviceModel: 'Galaxy S25 Ultra'),
        _privateEvent.copyWith(
          trade: 'HVAC',
          failureCategory: 'parser_exception',
        ),
      ]);

      expect(alert['severity'], 'major');
      expect(alert['event count'], 3);
      expect(alert['top failure category'], 'ambiguous_match');
      expect(alert['affected device models'], {
        'Galaxy S24 Ultra',
        'Galaxy S25 Ultra',
      });
      expect(alert.containsKey('raw receipt text'), isFalse);
      expect(alert.toString(), isNot(contains('LOWES VISA')));
      expect(alert.toString(), isNot(contains('4111111111111111')));
    });
  });
}

const _allowedRollupFields = {
  'device class',
  'device model',
  'os version',
  'app version',
  'parser version',
  'pack version',
  'trade',
  'item id',
  'failure category',
  'candidate count',
  'review status',
  'merchant type',
};

const _blockedAdminFields = {
  'raw receipt text',
  'card number',
  'last four',
  'customer name',
  'email',
  'phone',
  'address',
  'GPS coordinates',
  'photo',
  'receipt image',
};

const _privateValues = {
  'LOWES VISA',
  '4111111111111111',
  '1111',
  'John Smith',
  'john@example.com',
  '804-555-1212',
  '123 Main Street',
  '37.5407,-77.4360',
  '/private/receipt.jpg',
};

const _privateEvent = _ParserHealthEvent(
  deviceClass: 'modern flagship',
  deviceModel: 'Galaxy S24 Ultra',
  osVersion: 'Android 15',
  appVersion: '5.6.0',
  parserVersion: 'parser-2026.07.02',
  packVersion: 'plumbing-core-en-us-2026.07',
  trade: 'Plumbing',
  itemId: 'PLUMBING-PEX-CRIMP-90-1-2',
  failureCategory: 'ambiguous_match',
  candidateCount: 3,
  reviewStatus: 'needsReview',
  merchantType: 'big_box',
  rawReceiptText: 'LOWES VISA 1111 JOHN SMITH 1/2 PEX CRMP ELL',
  cardNumber: '4111111111111111',
  lastFour: '1111',
  customerName: 'John Smith',
  email: 'john@example.com',
  phone: '804-555-1212',
  address: '123 Main Street',
  gpsCoordinates: '37.5407,-77.4360',
  photoPath: '/private/receipt.jpg',
  receiptImageBytes: 2048,
);

Map<String, Object?> _adminRollupFor(_ParserHealthEvent event) {
  return {
    'device class': event.deviceClass,
    'device model': event.deviceModel,
    'os version': event.osVersion,
    'app version': event.appVersion,
    'parser version': event.parserVersion,
    'pack version': event.packVersion,
    'trade': event.trade,
    'item id': event.itemId,
    'failure category': event.failureCategory,
    'candidate count': event.candidateCount,
    'review status': event.reviewStatus,
    'merchant type': event.merchantType,
  };
}

_AdminAggregateSummary _aggregateAdminRollups(
  List<_ParserHealthEvent> events,
) {
  return _AdminAggregateSummary(
    totalEvents: events.length,
    byFailureCategory: _countBy(events, (event) => event.failureCategory),
    byTrade: _countBy(events, (event) => event.trade),
    byDeviceClass: _countBy(events, (event) => event.deviceClass),
    byPackVersion: _countBy(events, (event) => event.packVersion),
    rawEventsStored: false,
  );
}

Map<String, Object?> _majorIncidentAlert(List<_ParserHealthEvent> events) {
  final byFailure = _countBy(events, (event) => event.failureCategory);
  final topFailure = byFailure.entries
      .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  return {
    'severity': events.length >= 3 ? 'major' : 'watch',
    'event count': events.length,
    'top failure category': topFailure.first.key,
    'affected device models': {
      for (final event in events) event.deviceModel,
    },
  };
}

Map<String, int> _countBy(
  List<_ParserHealthEvent> events,
  String Function(_ParserHealthEvent event) keyFor,
) {
  final counts = <String, int>{};
  for (final event in events) {
    counts.update(keyFor(event), (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

class _AdminRollupBudgetPolicy {
  const _AdminRollupBudgetPolicy({
    required this.syncIntervalHours,
    required this.maxReadsPerSync,
    required this.maxWritesPerSync,
    required this.manualRefreshReads,
    required this.manualRefreshWrites,
    required this.maxManualRefreshesPerDay,
  });

  final int syncIntervalHours;
  final int maxReadsPerSync;
  final int maxWritesPerSync;
  final int manualRefreshReads;
  final int manualRefreshWrites;
  final int maxManualRefreshesPerDay;

  int get automaticSyncsPerDay => 24 ~/ syncIntervalHours;

  int get dailyReadBudget =>
      automaticSyncsPerDay * maxReadsPerSync +
      maxManualRefreshesPerDay * manualRefreshReads;

  int get dailyWriteBudget =>
      automaticSyncsPerDay * maxWritesPerSync +
      maxManualRefreshesPerDay * manualRefreshWrites;

  bool get withinHundredReadsWritesPerDay =>
      dailyReadBudget <= 100 && dailyWriteBudget <= 100;

  bool get realTimeRequired => false;
}

class _AdminAggregateSummary {
  const _AdminAggregateSummary({
    required this.totalEvents,
    required this.byFailureCategory,
    required this.byTrade,
    required this.byDeviceClass,
    required this.byPackVersion,
    required this.rawEventsStored,
  });

  final int totalEvents;
  final Map<String, int> byFailureCategory;
  final Map<String, int> byTrade;
  final Map<String, int> byDeviceClass;
  final Map<String, int> byPackVersion;
  final bool rawEventsStored;
}

class _ParserHealthEvent {
  const _ParserHealthEvent({
    required this.deviceClass,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
    required this.parserVersion,
    required this.packVersion,
    required this.trade,
    required this.itemId,
    required this.failureCategory,
    required this.candidateCount,
    required this.reviewStatus,
    required this.merchantType,
    required this.rawReceiptText,
    required this.cardNumber,
    required this.lastFour,
    required this.customerName,
    required this.email,
    required this.phone,
    required this.address,
    required this.gpsCoordinates,
    required this.photoPath,
    required this.receiptImageBytes,
  });

  final String deviceClass;
  final String deviceModel;
  final String osVersion;
  final String appVersion;
  final String parserVersion;
  final String packVersion;
  final String trade;
  final String itemId;
  final String failureCategory;
  final int candidateCount;
  final String reviewStatus;
  final String merchantType;
  final String rawReceiptText;
  final String cardNumber;
  final String lastFour;
  final String customerName;
  final String email;
  final String phone;
  final String address;
  final String gpsCoordinates;
  final String photoPath;
  final int receiptImageBytes;

  _ParserHealthEvent copyWith({
    String? deviceClass,
    String? deviceModel,
    String? packVersion,
    String? trade,
    String? itemId,
    String? failureCategory,
  }) {
    return _ParserHealthEvent(
      deviceClass: deviceClass ?? this.deviceClass,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion,
      appVersion: appVersion,
      parserVersion: parserVersion,
      packVersion: packVersion ?? this.packVersion,
      trade: trade ?? this.trade,
      itemId: itemId ?? this.itemId,
      failureCategory: failureCategory ?? this.failureCategory,
      candidateCount: candidateCount,
      reviewStatus: reviewStatus,
      merchantType: merchantType,
      rawReceiptText: rawReceiptText,
      cardNumber: cardNumber,
      lastFour: lastFour,
      customerName: customerName,
      email: email,
      phone: phone,
      address: address,
      gpsCoordinates: gpsCoordinates,
      photoPath: photoPath,
      receiptImageBytes: receiptImageBytes,
    );
  }
}
