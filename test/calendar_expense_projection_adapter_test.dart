import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/shared/calendar/calendar_expense_projection_adapter.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';

void main() {
  test('late expense entry remains on its receipt business date', () {
    final event = CalendarExpenseProjectionAdapter.fromReceipt(
      _receipt(
        receiptDate: DateTime(2026, 7, 22),
        createdAt: DateTime(2026, 7, 28, 9),
        updatedAt: DateTime(2026, 7, 28, 10),
      ),
    );

    expect(event.timing.eventDate, DateTime(2026, 7, 22));
    expect(event.timing.timeSource, CalendarTimeSource.unknown);
    expect(event.timing.displayTimeLabel, 'Time not recorded');
    expect(event.timing.recordedAt, DateTime(2026, 7, 28, 10));
  });

  test(
    'receipt time becomes actual event time without changing recorded time',
    () {
      final event = CalendarExpenseProjectionAdapter.fromReceipt(
        _receipt(
          receiptDate: DateTime(2026, 7, 22),
          receiptTimeMinutes: 8 * 60 + 35,
          createdAt: DateTime(2026, 7, 28, 9),
        ),
      );

      expect(event.timing.timeSource, CalendarTimeSource.actual);
      expect(event.timing.actualAt, DateTime(2026, 7, 22, 8, 35));
      expect(event.timing.recordedAt, DateTime(2026, 7, 28, 9));
    },
  );

  test('OCR review remains a review-required calendar state', () {
    final event = CalendarExpenseProjectionAdapter.fromReceipt(
      _receipt(
        receiptDate: DateTime(2026, 7, 22),
        ocrReview: const ExpenseReceiptOcrReview(
          severity: 'review',
          primaryWarningLabelOverride: 'Date confidence is low.',
        ),
      ),
    );

    expect(event.state, CalendarProjectionState.needsReview);
    expect(event.deepLink.target, CalendarDeepLinkTarget.expenseDetail);
    expect(event.evidence.explanation, contains('Review the receipt proof'));
  });

  test('active projection suppresses inactive expense records', () {
    final events = CalendarExpenseProjectionAdapter.eventsFromReceipts([
      _receipt(receiptDate: DateTime(2026, 7, 22)),
    ]);

    expect(events, hasLength(1));
    expect(events.single.vehicleIds, ['truck-1']);
    expect(events.single.workProfileId, 'contractor');
    expect(
      events.single.businessClassification,
      CalendarBusinessClassification.business,
    );
  });

  test(
    'expense projection preserves personal, mixed, and unclassified use',
    () {
      expect(
        CalendarExpenseProjectionAdapter.fromReceipt(
          _receipt(
            receiptDate: DateTime(2026, 7, 22),
            lines: [_line(use: ExpenseLineUse.personal)],
          ),
        ).businessClassification,
        CalendarBusinessClassification.personal,
      );
      expect(
        CalendarExpenseProjectionAdapter.fromReceipt(
          _receipt(
            receiptDate: DateTime(2026, 7, 22),
            lines: [
              _line(use: ExpenseLineUse.business),
              _line(id: 'personal-line', use: ExpenseLineUse.personal),
            ],
          ),
        ).businessClassification,
        CalendarBusinessClassification.mixed,
      );
      expect(
        CalendarExpenseProjectionAdapter.fromReceipt(
          _receipt(
            receiptDate: DateTime(2026, 7, 22),
            lines: [_line(use: ExpenseLineUse.unclassified)],
          ),
        ).businessClassification,
        CalendarBusinessClassification.unclassified,
      );
    },
  );
}

ExpenseReceiptRecord _receipt({
  required DateTime receiptDate,
  DateTime? createdAt,
  DateTime? updatedAt,
  int? receiptTimeMinutes,
  ExpenseReceiptOcrReview ocrReview = const ExpenseReceiptOcrReview(),
  List<ExpenseReceiptLineRecord>? lines,
}) => ExpenseReceiptRecord(
  id: 'receipt-1',
  receiptDate: receiptDate,
  receiptTimeMinutes: receiptTimeMinutes,
  merchantName: 'Fuel Stop',
  vehicleId: 'truck-1',
  workProfileId: 'contractor',
  createdAt: createdAt,
  updatedAt: updatedAt,
  ocrReview: ocrReview,
  lines: lines ?? [_line()],
);

ExpenseReceiptLineRecord _line({
  String id = 'fuel-line',
  ExpenseLineUse use = ExpenseLineUse.business,
}) => ExpenseReceiptLineRecord(
  id: id,
  description: 'Fuel',
  category: 'Fuel',
  use: use,
  quantity: 1,
  unitsPerPackage: 1,
  unit: 'each',
  subtotal: 50,
);
