import 'dart:io';

const _receiptCaptureRoot = 'lib/shared/widgets/receipt_capture';

const _requiredGuards = <String, List<String>>{
  'lib/shared/widgets/receipt_capture/receipt_image_processor.dart': [
    'static Future<Uint8List?> _readFileBytes',
    'static img.Image? _decodeImage',
    'decodeReceiptImageBytes',
  ],
  'lib/shared/widgets/receipt_capture/receipt_ocr_service_pdf_read.dart': [
    'Future<Uint8List?> _readPdfRasterBytes',
    '_ReceiptPdfRasterReadException',
  ],
  'lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart':
      [
        'ReceiptImageProcessor.decodeReceiptImageBytes(bytes)',
        'on FileSystemException',
      ],
  'lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_api.dart':
      [
        'ReceiptImageProcessor._readFileBytes',
        'ReceiptImageProcessor._decodeImage',
      ],
};

const _forbiddenProductionSnippets = <String>[
  'File(attachment.path).readAsBytes()',
  'img.decodeImage(bytes)',
  'img.decodeImage(await',
];

const _allowedProductionReadSnippets = <String, List<String>>{
  'lib/shared/widgets/receipt_capture/receipt_image_processor.dart': [
    'return await File(path).readAsBytes();',
  ],
  'lib/shared/widgets/receipt_capture/receipt_ocr_service_pdf_read.dart': [
    'return await File(path).readAsBytes();',
  ],
  'lib/shared/widgets/receipt_capture/receipt_pdf_inspector_bytes.dart': [
    'return _ReceiptPdfInspectionBytes(await file.readAsBytes());',
    'final stream = file.openRead(0, 1024);',
    'await for (final chunk in file.openRead(start, end)) {',
  ],
  'lib/shared/widgets/receipt_capture/receipt_pdf_viewer_preview_async.dart': [
    'bytes = await file.readAsBytes();',
  ],
  'lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart':
      ['bytes = await File(photoPath).readAsBytes();'],
  'lib/shared/widgets/receipt_capture/receipt_proof_storage_helpers.dart': [
    'return (await sha256.bind(file.openRead()).first).toString();',
  ],
  'lib/shared/widgets/receipt_capture/receipt_scanner_service.dart': [
    'return await file.readAsBytes();',
  ],
};

const _allowedDecodeImageFile =
    'lib/shared/widgets/receipt_capture/receipt_image_processor.dart';

void main(List<String> args) {
  final problems = <String>[];
  _checkRequiredGuards(problems);
  _checkForbiddenProductionSnippets(problems);
  _checkProductionReadsAreAllowed(problems);

  if (problems.isNotEmpty) {
    stderr.writeln('Receipt camera I/O guard failed:');
    for (final problem in problems) {
      stderr.writeln('- $problem');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Receipt camera I/O guard passed.');
}

void _checkRequiredGuards(List<String> problems) {
  for (final entry in _requiredGuards.entries) {
    final file = File(entry.key);
    if (!file.existsSync()) {
      problems.add('${entry.key}: required guard file is missing.');
      continue;
    }
    final source = file.readAsStringSync();
    for (final token in entry.value) {
      if (!source.contains(token)) {
        problems.add('${entry.key}: missing required guard `$token`.');
      }
    }
  }
}

void _checkForbiddenProductionSnippets(List<String> problems) {
  final root = Directory(_receiptCaptureRoot);
  if (!root.existsSync()) {
    problems.add('$_receiptCaptureRoot: receipt capture root is missing.');
    return;
  }

  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final source = entity.readAsStringSync();
    final relativePath = entity.path;
    for (final snippet in _forbiddenProductionSnippets) {
      if (!_snippetAllowed(relativePath, snippet) && source.contains(snippet)) {
        problems.add('$relativePath: forbidden raw I/O snippet `$snippet`.');
      }
    }
  }
}

void _checkProductionReadsAreAllowed(List<String> problems) {
  final root = Directory(_receiptCaptureRoot);
  if (!root.existsSync()) return;

  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final source = entity.readAsStringSync();
    final relativePath = entity.path;
    final allowed = _allowedProductionReadSnippets[relativePath] ?? const [];
    _checkReadFamily(
      problems: problems,
      relativePath: relativePath,
      source: source,
      allowed: allowed,
      pattern: RegExp(r'[^\n]*readAsBytes\([^\n]*'),
      label: 'readAsBytes',
    );
    _checkReadFamily(
      problems: problems,
      relativePath: relativePath,
      source: source,
      allowed: allowed,
      pattern: RegExp(r'[^\n]*openRead\([^\n]*'),
      label: 'openRead',
    );
  }
}

void _checkReadFamily({
  required List<String> problems,
  required String relativePath,
  required String source,
  required List<String> allowed,
  required RegExp pattern,
  required String label,
}) {
  for (final match in pattern.allMatches(source)) {
    final snippet = match.group(0)?.trim();
    if (snippet == null || snippet.isEmpty) continue;
    if (allowed.contains(snippet)) continue;
    problems.add(
      '$relativePath: unapproved production $label site `$snippet`.',
    );
  }
}

bool _snippetAllowed(String path, String snippet) {
  if (path == _allowedDecodeImageFile && snippet == 'img.decodeImage(bytes)') {
    return true;
  }
  return false;
}
