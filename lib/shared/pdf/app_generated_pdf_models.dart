import 'dart:typed_data';

enum AppGeneratedPdfKind {
  estimate,
  invoice,
  expenseExport,
  inventoryReport,
  maintenanceReport,
  customerStatement,
}

class AppGeneratedPdfDocument {
  const AppGeneratedPdfDocument({
    required this.kind,
    required this.title,
    required this.fileName,
    required this.bytes,
    required this.createdAt,
    this.sourceModule = '',
    this.sourceRecordId = '',
    this.shareSubject = '',
    this.shareText = '',
  });

  final AppGeneratedPdfKind kind;
  final String title;
  final String fileName;
  final Uint8List bytes;
  final DateTime createdAt;
  final String sourceModule;
  final String sourceRecordId;
  final String shareSubject;
  final String shareText;

  String get kindLabel {
    return switch (kind) {
      AppGeneratedPdfKind.estimate => 'Estimate',
      AppGeneratedPdfKind.invoice => 'Invoice',
      AppGeneratedPdfKind.expenseExport => 'Expense Export',
      AppGeneratedPdfKind.inventoryReport => 'Inventory Report',
      AppGeneratedPdfKind.maintenanceReport => 'Maintenance Report',
      AppGeneratedPdfKind.customerStatement => 'Customer Statement',
    };
  }

  String get safeFileName {
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) return 'maintaniac-document.pdf';
    return trimmed.toLowerCase().endsWith('.pdf') ? trimmed : '$trimmed.pdf';
  }

  int get byteSize => bytes.lengthInBytes;
}

class AppGeneratedPdfFile {
  const AppGeneratedPdfFile({
    required this.document,
    required this.path,
    required this.byteSize,
  });

  final AppGeneratedPdfDocument document;
  final String path;
  final int byteSize;
}
