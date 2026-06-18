import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'expense_export_models.dart';
import 'expense_ledger_models.dart';

class ExpenseExportRecord {
  const ExpenseExportRecord({
    required this.id,
    required this.exportedAt,
    required this.rangeStart,
    required this.rangeEnd,
    required this.categoryFilter,
    required this.receiptCount,
    required this.lineCount,
    required this.total,
    required this.fileNames,
    this.source = ExpenseExportSource.localDevice,
    this.destination = ExpenseExportDestination.share,
    this.outputDirectory,
  });

  factory ExpenseExportRecord.fromMap(Map<dynamic, dynamic> map) {
    return ExpenseExportRecord(
      id: map['id'] as String? ?? '',
      exportedAt:
          DateTime.tryParse(map['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      rangeStart:
          DateTime.tryParse(map['rangeStart'] as String? ?? '') ??
          DateTime.now(),
      rangeEnd:
          DateTime.tryParse(map['rangeEnd'] as String? ?? '') ?? DateTime.now(),
      categoryFilter: ExpenseExportCategoryFilter.values.firstWhere(
        (value) => value.name == map['categoryFilter'],
        orElse: () => ExpenseExportCategoryFilter.all,
      ),
      receiptCount: (map['receiptCount'] as num?)?.toInt() ?? 0,
      lineCount: (map['lineCount'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      source: ExpenseExportSource.values.firstWhere(
        (value) => value.name == map['source'],
        orElse: () => ExpenseExportSource.localDevice,
      ),
      destination: ExpenseExportDestination.values.firstWhere(
        (value) => value.name == map['destination'],
        orElse: () => ExpenseExportDestination.share,
      ),
      outputDirectory: map['outputDirectory'] as String?,
      fileNames:
          (map['fileNames'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
    );
  }

  final String id;
  final DateTime exportedAt;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final ExpenseExportCategoryFilter categoryFilter;
  final int receiptCount;
  final int lineCount;
  final double total;
  final List<String> fileNames;
  final ExpenseExportSource source;
  final ExpenseExportDestination destination;
  final String? outputDirectory;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exportedAt': exportedAt.toIso8601String(),
      'rangeStart': rangeStart.toIso8601String(),
      'rangeEnd': rangeEnd.toIso8601String(),
      'categoryFilter': categoryFilter.name,
      'receiptCount': receiptCount,
      'lineCount': lineCount,
      'total': total,
      'fileNames': fileNames,
      'source': source.name,
      'destination': destination.name,
      'outputDirectory': outputDirectory,
    };
  }
}

class ExpenseExportController extends ChangeNotifier {
  ExpenseExportController._(this._box);
  ExpenseExportController.memory() : _box = null;

  static const boxName = 'expense_export_history';

  final Box<dynamic>? _box;
  final _memoryRecords = <String, ExpenseExportRecord>{};

  static Future<ExpenseExportController> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return ExpenseExportController._(box);
  }

  List<ExpenseExportRecord> get exports {
    final source = _box == null ? _memoryRecords.values : _box.values;
    final records = <ExpenseExportRecord>[];
    for (final value in source) {
      if (value is ExpenseExportRecord) {
        records.add(value);
      } else if (value is Map) {
        records.add(ExpenseExportRecord.fromMap(value));
      }
    }
    records.sort((a, b) => b.exportedAt.compareTo(a.exportedAt));
    return records;
  }

  ExpenseExportRecord? get lastExport {
    final records = exports;
    return records.isEmpty ? null : records.first;
  }

  int exportsUsedInMonth(DateTime day, {ExpenseExportSource? source}) {
    return exports.where((record) {
      final sameMonth =
          record.exportedAt.year == day.year &&
          record.exportedAt.month == day.month;
      if (!sameMonth) return false;
      return source == null || record.source == source;
    }).length;
  }

  int cloudExportsUsedInMonth(DateTime day) {
    return exportsUsedInMonth(day, source: ExpenseExportSource.cloudBackup);
  }

  bool hasFreeCloudExportAvailable(DateTime day) {
    return cloudExportsUsedInMonth(day) < 1;
  }

  bool canRunExport(ExpenseExportSnapshot snapshot, DateTime day) {
    if (!snapshot.source.usesBackendReads) return true;
    return hasFreeCloudExportAvailable(day);
  }

  Future<ExpenseExportRecord> markExported(
    ExpenseExportSnapshot snapshot, {
    String? outputDirectory,
    List<String>? fileNames,
  }) async {
    final record = ExpenseExportRecord(
      id: 'EXP-EXPORT-${snapshot.exportedAt.microsecondsSinceEpoch}',
      exportedAt: snapshot.exportedAt,
      rangeStart: snapshot.range.start,
      rangeEnd: snapshot.range.end,
      categoryFilter: snapshot.categoryFilter,
      receiptCount: snapshot.receiptCount,
      lineCount: snapshot.lineCount,
      total: snapshot.total,
      fileNames: fileNames ?? snapshot.fileNames,
      source: snapshot.source,
      destination: snapshot.destination,
      outputDirectory: outputDirectory,
    );
    if (_box == null) {
      _memoryRecords[record.id] = record;
    } else {
      await _box.put(record.id, record.toMap());
    }
    notifyListeners();
    return record;
  }
}

class ExpenseExportScope extends InheritedNotifier<ExpenseExportController> {
  const ExpenseExportScope({
    super.key,
    required ExpenseExportController controller,
    required super.child,
  }) : super(notifier: controller);

  static ExpenseExportController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ExpenseExportScope>();
    assert(scope != null, 'ExpenseExportScope is missing above this context.');
    return scope!.notifier!;
  }

  static ExpenseExportController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ExpenseExportScope>()
        ?.notifier;
  }
}

ExpenseDateRange rangeSinceLastExport({
  required ExpenseExportRecord? lastExport,
  required DateTime fallbackStart,
  required DateTime end,
}) {
  final start = lastExport == null
      ? DateTime(fallbackStart.year, fallbackStart.month, fallbackStart.day)
      : DateTime(
          lastExport.exportedAt.year,
          lastExport.exportedAt.month,
          lastExport.exportedAt.day,
        );
  return ExpenseDateRange(
    start: start,
    end: DateTime(end.year, end.month, end.day),
  );
}
