import '../widgets/receipt_capture/receipt_capture_models.dart';

enum AppDocumentKind {
  otherDocument('Other Document', 'documents'),
  jobContractorDocument('Job / Contractor Document', 'jobs'),
  invoiceDocument('Invoice / Estimate Document', 'invoices'),
  maintenanceRecord('Maintenance Record', 'maintenance');

  const AppDocumentKind(this.label, this.storageModule);

  final String label;
  final String storageModule;

  static AppDocumentKind fromName(String? name) {
    return AppDocumentKind.values.firstWhere(
      (value) => value.name == name,
      orElse: () => AppDocumentKind.otherDocument,
    );
  }
}

class AppDocumentRecord {
  const AppDocumentRecord({
    required this.id,
    required this.kind,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
    this.title = '',
    this.importedText = '',
    this.notes = '',
    this.sourceLabel = '',
  });

  factory AppDocumentRecord.fromMap(Map<dynamic, dynamic> map) {
    final created = DateTime.tryParse(map['createdAt'] as String? ?? '');
    final updated = DateTime.tryParse(map['updatedAt'] as String? ?? '');
    return AppDocumentRecord(
      id: map['id'] as String? ?? '',
      kind: AppDocumentKind.fromName(map['kind'] as String?),
      title: map['title'] as String? ?? '',
      importedText: map['importedText'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      sourceLabel: map['sourceLabel'] as String? ?? '',
      createdAt: created ?? DateTime.now(),
      updatedAt: updated ?? created ?? DateTime.now(),
      attachments:
          (map['attachments'] as List?)
              ?.whereType<Map>()
              .map(ReceiptAttachmentRecord.fromMap)
              .toList(growable: false) ??
          const [],
    );
  }

  final String id;
  final AppDocumentKind kind;
  final String title;
  final String importedText;
  final String notes;
  final String sourceLabel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ReceiptAttachmentRecord> attachments;

  String get displayTitle {
    final clean = title.trim();
    if (clean.isNotEmpty) return clean;
    if (attachments.isNotEmpty) return attachments.first.label;
    return kind.label;
  }

  bool get hasProof => attachments.isNotEmpty || importedText.trim().isNotEmpty;

  AppDocumentRecord copyWith({
    String? title,
    String? importedText,
    String? notes,
    String? sourceLabel,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ReceiptAttachmentRecord>? attachments,
  }) {
    return AppDocumentRecord(
      id: id,
      kind: kind,
      title: title ?? this.title,
      importedText: importedText ?? this.importedText,
      notes: notes ?? this.notes,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kind': kind.name,
      'title': title,
      'importedText': importedText,
      'notes': notes,
      'sourceLabel': sourceLabel,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'attachments': [for (final attachment in attachments) attachment.toMap()],
    };
  }
}
