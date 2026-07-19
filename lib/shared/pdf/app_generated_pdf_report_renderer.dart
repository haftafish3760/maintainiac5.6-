import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'app_generated_pdf_export_request.dart';
import 'app_generated_pdf_export_verifier.dart';
import 'app_generated_pdf_image_loader.dart';
import 'app_generated_pdf_models.dart';
import 'app_generated_pdf_receipt_sections.dart';

class AppGeneratedPdfReportData {
  const AppGeneratedPdfReportData({
    required this.generatedAt,
    this.activeProfileName = '',
    this.vehicleNickname = '',
    this.odometerRange = '',
    this.totalMiles,
    this.businessMiles,
    this.personalMiles,
    this.paidMiles,
    this.unpaidMiles,
    this.totalIncome,
    this.totalExpenses,
    this.netAmount,
    this.maintenanceCost,
    this.fuelCost,
    this.trips = const [],
    this.expenses = const [],
    this.maintenance = const [],
    this.receiptImages = const [],
  });

  final DateTime generatedAt;
  final String activeProfileName;
  final String vehicleNickname;
  final String odometerRange;
  final double? totalMiles;
  final double? businessMiles;
  final double? personalMiles;
  final double? paidMiles;
  final double? unpaidMiles;
  final double? totalIncome;
  final double? totalExpenses;
  final double? netAmount;
  final double? maintenanceCost;
  final double? fuelCost;
  final List<AppGeneratedPdfReportTrip> trips;
  final List<AppGeneratedPdfReportExpense> expenses;
  final List<AppGeneratedPdfReportMaintenance> maintenance;
  final List<AppGeneratedPdfReceiptImageReference> receiptImages;
}

class AppGeneratedPdfReportTrip {
  const AppGeneratedPdfReportTrip({
    required this.date,
    this.startTime = '',
    this.endTime = '',
    this.startOdometer = '',
    this.endOdometer = '',
    this.miles,
    this.pay,
    this.notes = '',
  });

  final DateTime date;
  final String startTime;
  final String endTime;
  final String startOdometer;
  final String endOdometer;
  final double? miles;
  final double? pay;
  final String notes;
}

class AppGeneratedPdfReportExpense {
  const AppGeneratedPdfReportExpense({
    required this.date,
    required this.category,
    this.merchant = '',
    this.amount,
    this.paymentMethod = '',
    this.receiptAttached = false,
  });

  final DateTime date;
  final String category;
  final String merchant;
  final double? amount;
  final String paymentMethod;
  final bool receiptAttached;
}

class AppGeneratedPdfReportMaintenance {
  const AppGeneratedPdfReportMaintenance({
    required this.date,
    required this.serviceType,
    this.vehicleNickname = '',
    this.odometer = '',
    this.cost,
    this.notes = '',
  });

  final DateTime date;
  final String serviceType;
  final String vehicleNickname;
  final String odometer;
  final double? cost;
  final String notes;
}

class AppGeneratedPdfReportRenderer {
  const AppGeneratedPdfReportRenderer();

  Future<AppGeneratedPdfDocument> build({
    required AppGeneratedPdfExportRequest request,
    required AppGeneratedPdfReportData data,
    String sourceModule = '',
    String sourceRecordId = '',
    AppGeneratedPdfImageResolver? imageResolver,
    bool allowFullImageDownload = false,
  }) async {
    if (!request.isReport || !request.isValid) {
      throw const AppGeneratedPdfReportException('invalid_report_request');
    }
    final receiptImageSections = await AppGeneratedPdfReceiptSections.build(
      references: data.receiptImages,
      mode: request.mode,
      imageResolver: imageResolver,
      allowFullImageDownload: allowFullImageDownload,
    );
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(34),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Text(
              'Maintaniac is a record-keeping app only. This report is not tax, legal, or financial advice.',
              style: const pw.TextStyle(fontSize: 7),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 7),
            ),
          ],
        ),
        build: (context) => [
          _header(request, data),
          pw.SizedBox(height: 12),
          _summary(data),
          if (data.trips.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _sectionTitle('Trips'),
            _trips(data.trips),
          ],
          if (data.expenses.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _sectionTitle('Expenses'),
            _expenses(data.expenses),
          ],
          if (data.maintenance.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _sectionTitle('Maintenance'),
            _maintenance(data.maintenance),
          ],
          if (receiptImageSections.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _sectionTitle('Receipt Images'),
            pw.SizedBox(height: 8),
            ...receiptImageSections,
          ],
        ],
      ),
    );
    final bytes = await pdf.save();
    AppGeneratedPdfExportVerification.inspect(bytes).throwIfInvalid();
    return AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.activityReport,
      title: 'Maintainiac ${_reportLabel(request.type)}',
      fileName:
          'maintainiac_${request.type.name}_${_fileDate(request.startDate!)}_to_${_fileDate(request.endDate!)}.pdf',
      bytes: bytes,
      createdAt: data.generatedAt,
      sourceModule: sourceModule,
      sourceRecordId: sourceRecordId,
    );
  }

  pw.Widget _header(
    AppGeneratedPdfExportRequest request,
    AppGeneratedPdfReportData data,
  ) {
    final details = <String>[
      'Range: ${_date(request.startDate!)} - ${_date(request.endDate!)}',
      'Generated: ${_dateTime(data.generatedAt)}',
      if (data.activeProfileName.trim().isNotEmpty)
        'Profile: ${data.activeProfileName.trim()}',
      if (data.vehicleNickname.trim().isNotEmpty)
        'Vehicle: ${data.vehicleNickname.trim()}',
      if (data.odometerRange.trim().isNotEmpty)
        'Odometer: ${data.odometerRange.trim()}',
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Maintainiac',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          _reportLabel(request.type),
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        for (final detail in details)
          pw.Text(detail, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  pw.Widget _summary(AppGeneratedPdfReportData data) {
    final values = <List<String>>[
      ['Total miles', _number(data.totalMiles)],
      ['Business miles', _number(data.businessMiles)],
      ['Personal miles', _number(data.personalMiles)],
      ['Paid miles', _number(data.paidMiles)],
      ['Unpaid miles', _number(data.unpaidMiles)],
      ['Total income', _money(data.totalIncome)],
      ['Total expenses', _money(data.totalExpenses)],
      ['Net amount', _money(data.netAmount)],
      ['Maintenance cost', _money(data.maintenanceCost)],
      ['Fuel cost', _money(data.fuelCost)],
    ].where((entry) => entry.last.isNotEmpty).toList(growable: false);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Summary'),
        if (values.isEmpty)
          pw.Text('No summary totals were available.')
        else
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(width: .3),
            cellStyle: const pw.TextStyle(fontSize: 9),
            data: values,
          ),
      ],
    );
  }

  pw.Widget _trips(List<AppGeneratedPdfReportTrip> values) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(width: .3),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 7),
      headers: const [
        'Date',
        'Start',
        'End',
        'Start odo',
        'End odo',
        'Miles',
        'Pay',
        'Notes',
      ],
      data: [
        for (final value in values)
          [
            _date(value.date),
            value.startTime,
            value.endTime,
            value.startOdometer,
            value.endOdometer,
            _number(value.miles),
            _money(value.pay),
            value.notes,
          ],
      ],
    );
  }

  pw.Widget _expenses(List<AppGeneratedPdfReportExpense> values) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(width: .3),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 7),
      headers: const [
        'Date',
        'Category',
        'Merchant',
        'Amount',
        'Payment',
        'Receipt',
      ],
      data: [
        for (final value in values)
          [
            _date(value.date),
            value.category,
            value.merchant,
            _money(value.amount),
            value.paymentMethod,
            value.receiptAttached ? 'Yes' : 'No',
          ],
      ],
    );
  }

  pw.Widget _maintenance(List<AppGeneratedPdfReportMaintenance> values) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(width: .3),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 7),
      headers: const [
        'Date',
        'Vehicle',
        'Service',
        'Odometer',
        'Cost',
        'Notes',
      ],
      data: [
        for (final value in values)
          [
            _date(value.date),
            value.vehicleNickname,
            value.serviceType,
            value.odometer,
            _money(value.cost),
            value.notes,
          ],
      ],
    );
  }

  pw.Widget _sectionTitle(String value) {
    return pw.Text(
      value,
      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
    );
  }
}

class AppGeneratedPdfReportException implements Exception {
  const AppGeneratedPdfReportException(this.reasonCode);

  final String reasonCode;
}

String _reportLabel(AppGeneratedPdfExportType type) => switch (type) {
  AppGeneratedPdfExportType.dailyReport => 'Daily Report',
  AppGeneratedPdfExportType.dateRangeReport => 'Date Range Report',
  AppGeneratedPdfExportType.monthlyReport => 'Monthly Report',
  AppGeneratedPdfExportType.yearToDateReport => 'Year-to-Date Report',
  AppGeneratedPdfExportType.expenseExport => 'Expense Report',
  AppGeneratedPdfExportType.inventoryReport => 'Inventory Report',
  AppGeneratedPdfExportType.maintenanceReport => 'Maintenance Report',
  _ => 'Activity Report',
};

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _dateTime(DateTime value) =>
    '${_date(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _fileDate(DateTime value) => _date(value);

String _number(double? value) => value == null ? '' : value.toStringAsFixed(1);

String _money(double? value) =>
    value == null ? '' : '\$${value.toStringAsFixed(2)}';
