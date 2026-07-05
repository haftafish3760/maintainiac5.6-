import 'app_generated_pdf_models.dart';

enum AppPdfHealthOperation {
  generate,
  preview,
  share,
  print,
  archive,
  importProof,
  exportPackage,
  extractPackage,
}

enum AppPdfHealthStatus { success, warning, blocked, failed }

class AppPdfHealthEvent {
  const AppPdfHealthEvent({
    required this.operation,
    required this.status,
    required this.occurredAtUtc,
    this.kind,
    this.sourceModule = '',
    this.byteSize = 0,
    this.pageCount,
    this.issueCodes = const [],
    this.riskFlags = const [],
    this.recoveryAction = '',
  });

  factory AppPdfHealthEvent.generatedDocument({
    required AppGeneratedPdfDocument document,
    required AppPdfHealthOperation operation,
    DateTime? occurredAtUtc,
    String recoveryAction = '',
  }) {
    final validation = document.validation;
    return AppPdfHealthEvent(
      operation: operation,
      status: validation.isValid
          ? AppPdfHealthStatus.success
          : AppPdfHealthStatus.blocked,
      occurredAtUtc: (occurredAtUtc ?? document.createdAt).toUtc(),
      kind: document.kind,
      sourceModule: document.sourceModule,
      byteSize: validation.byteSize,
      issueCodes: validation.issues,
      recoveryAction: recoveryAction,
    );
  }

  final AppPdfHealthOperation operation;
  final AppPdfHealthStatus status;
  final DateTime occurredAtUtc;
  final AppGeneratedPdfKind? kind;
  final String sourceModule;
  final int byteSize;
  final int? pageCount;
  final List<String> issueCodes;
  final List<String> riskFlags;
  final String recoveryAction;

  bool get needsAttention =>
      status == AppPdfHealthStatus.blocked ||
      status == AppPdfHealthStatus.failed ||
      issueCodes.isNotEmpty ||
      riskFlags.isNotEmpty;

  Map<String, Object?> toCommandCenterMap() {
    return {
      'operation': operation.name,
      'status': status.name,
      'occurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
      if (kind != null) 'kind': kind!.name,
      if (_safeToken(sourceModule).isNotEmpty)
        'sourceModule': _safeToken(sourceModule),
      'byteSizeBucket': _byteSizeBucket(byteSize),
      if (pageCount != null) 'pageCountBucket': _pageCountBucket(pageCount!),
      if (issueCodes.isNotEmpty) 'issueCodes': _safeTokenList(issueCodes),
      if (riskFlags.isNotEmpty) 'riskFlags': _safeTokenList(riskFlags),
      if (_safeToken(recoveryAction).isNotEmpty)
        'recoveryAction': _safeToken(recoveryAction),
    };
  }
}

class AppPdfHealthSnapshot {
  const AppPdfHealthSnapshot({
    required this.generatedAtUtc,
    required this.events,
  });

  final DateTime generatedAtUtc;
  final List<AppPdfHealthEvent> events;

  int get totalEventCount => events.length;
  int get successCount => events
      .where((event) => event.status == AppPdfHealthStatus.success)
      .length;
  int get warningCount => events
      .where((event) => event.status == AppPdfHealthStatus.warning)
      .length;
  int get blockedCount => events
      .where((event) => event.status == AppPdfHealthStatus.blocked)
      .length;
  int get failedCount =>
      events.where((event) => event.status == AppPdfHealthStatus.failed).length;
  int get attentionCount =>
      events.where((event) => event.needsAttention).length;

  bool get needsAttention => blockedCount > 0 || failedCount > 0;

  String get healthLabel {
    if (totalEventCount == 0) return 'no_data';
    if (failedCount > 0 || blockedCount > 0) return 'needs_attention';
    if (warningCount > 0 || attentionCount > 0) return 'review';
    return 'healthy';
  }

  Map<String, Object?> toCommandCenterMap({int recentLimit = 12}) {
    final limitedEvents = events
        .where((event) => event.needsAttention)
        .take(recentLimit.clamp(0, 50))
        .map((event) => event.toCommandCenterMap())
        .toList(growable: false);
    return {
      'schema': 'pdf_health_diagnostics_v1',
      'generatedAtUtc': generatedAtUtc.toUtc().toIso8601String(),
      'healthLabel': healthLabel,
      'totalEventCount': totalEventCount,
      'successCount': successCount,
      'warningCount': warningCount,
      'blockedCount': blockedCount,
      'failedCount': failedCount,
      'attentionCount': attentionCount,
      'operationCounts': _countBy(events.map((event) => event.operation.name)),
      'statusCounts': _countBy(events.map((event) => event.status.name)),
      'kindCounts': _countBy(
        events.map((event) => event.kind?.name ?? 'unknown'),
      ),
      'sourceModuleCounts': _countBy(
        events.map((event) => _safeToken(event.sourceModule)),
      ),
      'issueCounts': _countBy(
        events.expand((event) => _safeTokenList(event.issueCodes)),
      ),
      'riskCounts': _countBy(
        events.expand((event) => _safeTokenList(event.riskFlags)),
      ),
      'recentAttentionEvents': limitedEvents,
    };
  }
}

Map<String, int> _countBy(Iterable<String> values) {
  final counts = <String, int>{};
  for (final value in values) {
    final token = _safeToken(value);
    if (token.isEmpty) continue;
    counts[token] = (counts[token] ?? 0) + 1;
  }
  return Map.unmodifiable(counts);
}

List<String> _safeTokenList(Iterable<String> values) {
  return values
      .map(_safeToken)
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList(growable: false)
    ..sort();
}

String _safeToken(String value) {
  final lowered = value.toLowerCase();
  if (_looksPrivate(lowered)) return 'private_signal';
  return lowered
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '')
      .replaceAll(
        RegExp(r'^(vin|plate|license_plate|patient|passenger)$'),
        'private_signal',
      )
      .replaceAll(RegExp(r'^.{65,}$'), 'long_token');
}

bool _looksPrivate(String value) {
  return value.contains(RegExp(r'[/\\]users[/\\]')) ||
      value.contains(RegExp(r'[/\\]private[/\\]')) ||
      value.contains(RegExp(r'[/\\]documents[/\\]')) ||
      value.contains(RegExp(r'\bvin\b')) ||
      value.contains(RegExp(r'\bpatient\b')) ||
      value.contains(RegExp(r'\bpassenger\b')) ||
      value.contains(RegExp(r'\blicense\s*plate\b')) ||
      value.contains(RegExp(r'\bplate\s*[:#]')) ||
      RegExp(r'\b[a-hj-npr-z0-9]{17}\b').hasMatch(value) ||
      RegExp(r'[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}').hasMatch(value);
}

String _byteSizeBucket(int bytes) {
  if (bytes <= 0) return 'empty';
  if (bytes < 100 * 1024) return 'under_100kb';
  if (bytes < 1024 * 1024) return 'under_1mb';
  if (bytes < 10 * 1024 * 1024) return 'under_10mb';
  if (bytes < appGeneratedPdfMaxBytes) return 'under_generated_pdf_limit';
  return 'over_generated_pdf_limit';
}

String _pageCountBucket(int pages) {
  if (pages <= 0) return 'unknown_or_empty';
  if (pages == 1) return 'single_page';
  if (pages <= 5) return 'two_to_five_pages';
  if (pages <= 20) return 'six_to_twenty_pages';
  return 'over_twenty_pages';
}
