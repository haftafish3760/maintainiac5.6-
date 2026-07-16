import 'dart:io';

const _scriptPath = 'docs/receipt_real_device_test_script.md';

const _requiredPhrases = <String>[
  'Galaxy S9 Plus class device',
  'Galaxy S24/S25 class device',
  'iPhone SE class device',
  'Add Receipt',
  'Capture Photo',
  'Upload Photos',
  'Upload PDF/File',
  'Paste/Text',
  'Receipt Assist question',
  'camera opens immediately after the choice',
  'full-screen photo review',
  'settings gear',
  'phone owns focus, light, zoom, and shutter controls',
  'bright indoor light',
  'dim room',
  'direct glare',
  'shadow across the receipt',
  'truck cab or vehicle interior',
  'short receipt',
  'long receipt',
  'normal continuous autofocus behavior',
  'No unsupported quality warning',
  'ghost/overlap guide',
  'Save-space proof size',
  'business, personal, mixed',
  'Help Improve Receipt Camera',
  'default off',
  'owner-visible diagnostics stay metadata-only',
  'receipt images and receipt text are not owner-visible',
  'Draft recovery survives app interruption',
  'No compressed saved copy is used as the OCR source',
  'Failure Report Format',
];

const _forbiddenPhrases = <String>[
  'tap to focus',
  'tap-to-focus',
  'tap-focus',
  'ocr reads original first',
  'original receipt images are source truth',
  'preserve full-size originals by default',
  '## Flow 7: PDF Receipt Import',
  'Purpose:\n- Prove PDF receipts are handled safely.',
];

void main() {
  final file = File(_scriptPath);
  if (!file.existsSync()) {
    _fail('Missing real-device receipt camera script: $_scriptPath');
  }
  final text = file.readAsStringSync();
  final lower = text.toLowerCase();
  final missing = [
    for (final phrase in _requiredPhrases)
      if (!lower.contains(phrase.toLowerCase())) phrase,
  ];
  final forbidden = [
    for (final phrase in _forbiddenPhrases)
      if (lower.contains(phrase)) phrase,
  ];
  if (missing.isNotEmpty || forbidden.isNotEmpty) {
    final details = [
      if (missing.isNotEmpty) 'Missing: ${missing.join(', ')}',
      if (forbidden.isNotEmpty) 'Forbidden: ${forbidden.join(', ')}',
    ].join('\n');
    _fail('Receipt real-device matrix gate failed.\n$details');
  }
  stdout.writeln(
    'Receipt real-device matrix gate: required=${_requiredPhrases.length} '
    'forbidden=${_forbiddenPhrases.length}',
  );
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
