import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_export.dart';

void main() {
  test('plumbing trade pack payload is measurable and compactible', () {
    final payload = buildWorkSupplyTradePackPayload('Plumbing');
    final stats = payload['stats']! as Map<String, Object?>;
    final jsonBytes = utf8.encode(jsonEncode(payload));
    final gzipBytes = gzip.encode(jsonBytes);
    final itemCount = stats['itemCount']! as int;
    final rawBytesPerItem = jsonBytes.length / itemCount;
    final gzipBytesPerItem = gzipBytes.length / itemCount;

    expect(itemCount, greaterThanOrEqualTo(10000));
    expect(stats['categoryCount'], greaterThanOrEqualTo(10));
    expect(stats['aliasCount'], greaterThanOrEqualTo(100));
    expect(gzipBytes.length, lessThan(jsonBytes.length));

    // Kept as a visible baseline when running this single test during pack work.
    // ignore: avoid_print
    print(
      [
        'PLUMBING_TRADE_PACK_SIZE',
        'items=$itemCount',
        'rawBytes=${jsonBytes.length}',
        'gzipBytes=${gzipBytes.length}',
        'rawMB=${_mb(jsonBytes.length)}',
        'gzipMB=${_mb(gzipBytes.length)}',
        'rawBytesPerItem=${rawBytesPerItem.toStringAsFixed(1)}',
        'gzipBytesPerItem=${gzipBytesPerItem.toStringAsFixed(1)}',
        'projected50kGzipMB=${_mb((gzipBytesPerItem * 50000).round())}',
        'projected100kGzipMB=${_mb((gzipBytesPerItem * 100000).round())}',
      ].join(' '),
    );
  });
}

String _mb(int bytes) {
  return (bytes / (1024 * 1024)).toStringAsFixed(2);
}
