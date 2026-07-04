import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    as mlkit;

import 'receipt_photo_path_identity.dart';

enum ReceiptBarcodeScanPurpose { expense, inventory, maintenance, shared }

enum ReceiptBarcodeFormat {
  all,
  unknown,
  code128,
  code39,
  code93,
  codabar,
  dataMatrix,
  ean13,
  ean8,
  itf,
  qrCode,
  upca,
  upce,
  pdf417,
  aztec,
}

const receiptBarcodeInventoryAndQrFormats = <ReceiptBarcodeFormat>[
  ReceiptBarcodeFormat.code128,
  ReceiptBarcodeFormat.code39,
  ReceiptBarcodeFormat.code93,
  ReceiptBarcodeFormat.codabar,
  ReceiptBarcodeFormat.dataMatrix,
  ReceiptBarcodeFormat.ean13,
  ReceiptBarcodeFormat.ean8,
  ReceiptBarcodeFormat.itf,
  ReceiptBarcodeFormat.qrCode,
  ReceiptBarcodeFormat.upca,
  ReceiptBarcodeFormat.upce,
  ReceiptBarcodeFormat.pdf417,
  ReceiptBarcodeFormat.aztec,
];

class ReceiptScannedCode {
  const ReceiptScannedCode({
    required this.format,
    required this.valueType,
    required this.rawValue,
    this.displayValue = '',
  });

  final ReceiptBarcodeFormat format;
  final String valueType;
  final String rawValue;
  final String displayValue;

  bool get isQrCode => format == ReceiptBarcodeFormat.qrCode;
  bool get hasValue => normalizedValue.isNotEmpty;
  String get privacySafeValueType => _privacySafeBarcodeValueType(valueType);

  bool get isSensitivePayloadType {
    final valueTypeIsSensitive = switch (privacySafeValueType) {
      'contactInfo' ||
      'email' ||
      'phone' ||
      'sms' ||
      'wifi' ||
      'url' ||
      'sensitiveOther' ||
      'geoCoordinates' ||
      'calendarEvent' ||
      'driverLicense' => true,
      _ => false,
    };
    return valueTypeIsSensitive ||
        _looksLikeSensitiveBarcodePayload(rawValue) ||
        _looksLikeSensitiveBarcodePayload(displayValue);
  }

  String get normalizedValue {
    final source = rawValue.trim().isEmpty ? displayValue : rawValue;
    return source.replaceAll(RegExp(r'[\s-]+'), '').toUpperCase();
  }

  String? get inventoryLookupValue {
    if (isSensitivePayloadType) return null;
    final normalized = normalizedValue;
    return normalized.isEmpty ? null : normalized;
  }

  Map<String, Object?> get privacySafeSummaryMap {
    return {
      'format': format.name,
      'valueTypeBucket': privacySafeValueType,
      'isQrCode': isQrCode,
      'hasValue': hasValue,
      'isSensitivePayloadType': isSensitivePayloadType,
      'canUseForInventoryLookup': inventoryLookupValue != null,
      'normalizedLength': normalizedValue.length,
    };
  }
}

class ReceiptBarcodeScanResult {
  const ReceiptBarcodeScanResult({
    required this.imagePath,
    required this.purpose,
    required this.codes,
    this.warnings = const [],
  });

  final String imagePath;
  final ReceiptBarcodeScanPurpose purpose;
  final List<ReceiptScannedCode> codes;
  final List<String> warnings;

  bool get hasCodes => codes.isNotEmpty;
  int get qrCodeCount => codes.where((code) => code.isQrCode).length;
  int get inventoryLookupCandidateCount =>
      codes.where((code) => code.inventoryLookupValue != null).length;

  List<String> get inventoryLookupValues {
    final seen = <String>{};
    return [
      for (final code in codes)
        if (code.inventoryLookupValue case final value?)
          if (seen.add(value)) value,
    ];
  }

  Map<String, Object?> get privacySafeSummaryMap {
    final formatCounts = <String, int>{};
    final typeCounts = <String, int>{};
    for (final code in codes) {
      formatCounts[code.format.name] =
          (formatCounts[code.format.name] ?? 0) + 1;
      final type = code.privacySafeValueType;
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }
    return {
      'purpose': purpose.name,
      'codeCount': codes.length,
      'qrCodeCount': qrCodeCount,
      'inventoryLookupCandidateCount': inventoryLookupCandidateCount,
      'formatCounts': Map.unmodifiable(formatCounts),
      'valueTypeCounts': Map.unmodifiable(typeCounts),
      'warningBuckets': List.unmodifiable(
        warnings.map(_privacySafeBarcodeWarning).toSet(),
      ),
    };
  }
}

class ReceiptBarcodeBatchScanResult {
  const ReceiptBarcodeBatchScanResult({
    required this.purpose,
    required this.imageResults,
    this.warnings = const [],
  });

  final ReceiptBarcodeScanPurpose purpose;
  final List<ReceiptBarcodeScanResult> imageResults;
  final List<String> warnings;

  int get imageCount => imageResults.length;
  int get scannedImageCount {
    return imageResults.where((result) => result.imagePath.isNotEmpty).length;
  }

  int get warningImageCount {
    return imageResults.where((result) => result.warnings.isNotEmpty).length;
  }

  int get invalidImageCount {
    return imageResults.where((result) {
      return result.warnings
          .map(_privacySafeBarcodeWarning)
          .contains('barcode_scan_invalid_source_path');
    }).length;
  }

  int get codeCount => imageResults.fold(0, (sum, result) {
    return sum + result.codes.length;
  });
  int get qrCodeCount => imageResults.fold(0, (sum, result) {
    return sum + result.qrCodeCount;
  });

  List<String> get inventoryLookupValues {
    final seen = <String>{};
    return [
      for (final result in imageResults)
        for (final value in result.inventoryLookupValues)
          if (seen.add(value)) value,
    ];
  }

  Map<String, Object?> get privacySafeSummaryMap {
    final formatCounts = <String, int>{};
    final typeCounts = <String, int>{};
    for (final result in imageResults) {
      for (final code in result.codes) {
        formatCounts[code.format.name] =
            (formatCounts[code.format.name] ?? 0) + 1;
        final type = code.privacySafeValueType;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
    }
    return {
      'purpose': purpose.name,
      'imageCount': imageCount,
      'scannedImageCount': scannedImageCount,
      'warningImageCount': warningImageCount,
      'invalidImageCount': invalidImageCount,
      'codeCount': codeCount,
      'qrCodeCount': qrCodeCount,
      'inventoryLookupCandidateCount': inventoryLookupValues.length,
      'formatCounts': Map.unmodifiable(formatCounts),
      'valueTypeCounts': Map.unmodifiable(typeCounts),
      'imageWarningBuckets': {
        for (final result in imageResults)
          ...result.warnings.map(_privacySafeBarcodeWarning),
      }.toList(growable: false),
      'batchWarningBuckets': {
        for (final warning in warnings) _privacySafeBarcodeWarning(warning),
      }.toList(growable: false),
    };
  }
}

String _privacySafeBarcodeValueType(String valueType) {
  final token = valueType.trim();
  if (token.isEmpty) return 'unknown';
  final normalized = token.replaceAll(RegExp(r'[\s_-]+'), '').toLowerCase();
  final knownType = switch (normalized) {
    'contactinfo' => 'contactInfo',
    'email' => 'email',
    'phone' => 'phone',
    'sms' => 'sms',
    'wifi' => 'wifi',
    'geocoordinates' => 'geoCoordinates',
    'calendarevent' => 'calendarEvent',
    'driverlicense' => 'driverLicense',
    'product' => 'product',
    'text' => 'text',
    'url' => 'url',
    'isbn' => 'isbn',
    _ => null,
  };
  if (knownType != null) return knownType;
  return _looksLikeSensitiveBarcodeValueType(normalized)
      ? 'sensitiveOther'
      : 'other';
}

bool _looksLikeSensitiveBarcodeValueType(String normalized) {
  return normalized.contains('private') ||
      normalized.contains('customer') ||
      normalized.contains('client') ||
      normalized.contains('email') ||
      normalized.contains('phone') ||
      normalized.contains('driver') ||
      normalized.contains('license') ||
      normalized.contains('password') ||
      normalized.contains('secret') ||
      normalized.contains('token') ||
      normalized.contains('auth') ||
      normalized.contains('session') ||
      normalized.contains('account') ||
      normalized.contains('member') ||
      normalized.contains('patient');
}

bool _looksLikeSensitiveBarcodePayload(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  if (normalized.startsWith('http://') ||
      normalized.startsWith('https://') ||
      normalized.startsWith('www.') ||
      normalized.startsWith('wifi:') ||
      normalized.startsWith('mailto:') ||
      normalized.startsWith('tel:') ||
      normalized.startsWith('sms:') ||
      normalized.startsWith('geo:') ||
      normalized.startsWith('otpauth:') ||
      normalized.startsWith('mecard:') ||
      normalized.startsWith('begin:vcard') ||
      normalized.startsWith('begin:vevent') ||
      normalized.startsWith('begin:vcalendar')) {
    return true;
  }
  return RegExp(
    r'(^|[?&;:_\-/\s#])(customer|client|patient|password|passwd|pwd|secret|token|auth|session|account|member|email|phone|license|driver)(=|:|/|_|-|\s|#|\d|$)',
  ).hasMatch(normalized);
}

String _privacySafeBarcodeWarning(String warning) {
  final normalized = warning.trim().toLowerCase();
  return switch (normalized) {
    'barcode_scan_invalid_source_path' => 'barcode_scan_invalid_source_path',
    'barcode_scan_platform_failed' => 'barcode_scan_platform_failed',
    'barcode_scan_failed' => 'barcode_scan_failed',
    'barcode_scan_batch_image_limit' => 'barcode_scan_batch_image_limit',
    'barcode_scan_duplicate_image_skipped' =>
      'barcode_scan_duplicate_image_skipped',
    _ => 'barcode_scan_warning',
  };
}

abstract interface class ReceiptBarcodeImageDecoder {
  Future<List<ReceiptScannedCode>> scanImageFile(
    String imagePath, {
    required List<ReceiptBarcodeFormat> formats,
  });
}

class GoogleMlKitReceiptBarcodeImageDecoder
    implements ReceiptBarcodeImageDecoder {
  const GoogleMlKitReceiptBarcodeImageDecoder();

  @override
  Future<List<ReceiptScannedCode>> scanImageFile(
    String imagePath, {
    required List<ReceiptBarcodeFormat> formats,
  }) async {
    final scanner = mlkit.BarcodeScanner(formats: _mlkitFormatsFor(formats));
    try {
      final image = mlkit.InputImage.fromFilePath(imagePath);
      final barcodes = await scanner.processImage(image);
      return [
        for (final barcode in barcodes)
          ReceiptScannedCode(
            format: _formatFromMlKit(barcode.format),
            valueType: barcode.type.name,
            rawValue: barcode.rawValue?.trim() ?? '',
            displayValue: barcode.displayValue?.trim() ?? '',
          ),
      ];
    } finally {
      await scanner.close();
    }
  }
}

class ReceiptBarcodeScannerService {
  const ReceiptBarcodeScannerService({
    this.decoder = const GoogleMlKitReceiptBarcodeImageDecoder(),
  });

  final ReceiptBarcodeImageDecoder decoder;

  Future<ReceiptBarcodeScanResult> scanImageFile(
    String imagePath, {
    ReceiptBarcodeScanPurpose purpose = ReceiptBarcodeScanPurpose.shared,
    List<ReceiptBarcodeFormat> formats = receiptBarcodeInventoryAndQrFormats,
  }) async {
    final normalizedPath = _normalizedBarcodeImagePath(imagePath);
    if (normalizedPath == null) {
      return ReceiptBarcodeScanResult(
        imagePath: '',
        purpose: purpose,
        codes: const [],
        warnings: const ['barcode_scan_invalid_source_path'],
      );
    }
    try {
      final decoded = await decoder.scanImageFile(
        normalizedPath,
        formats: formats,
      );
      return ReceiptBarcodeScanResult(
        imagePath: normalizedPath,
        purpose: purpose,
        codes: _dedupeScannedCodes(decoded),
      );
    } on PlatformException {
      return ReceiptBarcodeScanResult(
        imagePath: normalizedPath,
        purpose: purpose,
        codes: const [],
        warnings: const ['barcode_scan_platform_failed'],
      );
    } catch (_) {
      return ReceiptBarcodeScanResult(
        imagePath: normalizedPath,
        purpose: purpose,
        codes: const [],
        warnings: const ['barcode_scan_failed'],
      );
    }
  }

  Future<ReceiptBarcodeBatchScanResult> scanImageFiles(
    Iterable<String> imagePaths, {
    ReceiptBarcodeScanPurpose purpose = ReceiptBarcodeScanPurpose.shared,
    List<ReceiptBarcodeFormat> formats = receiptBarcodeInventoryAndQrFormats,
    int maxImageCount = 12,
  }) async {
    final safeMax = maxImageCount < 1 ? 1 : maxImageCount;
    final results = <ReceiptBarcodeScanResult>[];
    final seenImagePaths = <String>{};
    var skippedByLimit = false;
    var skippedDuplicate = false;
    for (final imagePath in imagePaths) {
      final normalizedPath = _normalizedBarcodeImagePath(imagePath);
      if (normalizedPath != null && !seenImagePaths.add(normalizedPath)) {
        skippedDuplicate = true;
        continue;
      }
      if (results.length >= safeMax) {
        skippedByLimit = true;
        continue;
      }
      results.add(
        await scanImageFile(
          normalizedPath ?? imagePath,
          purpose: purpose,
          formats: formats,
        ),
      );
    }
    return ReceiptBarcodeBatchScanResult(
      purpose: purpose,
      imageResults: List.unmodifiable(results),
      warnings: [
        if (skippedByLimit) 'barcode_scan_batch_image_limit',
        if (skippedDuplicate) 'barcode_scan_duplicate_image_skipped',
      ],
    );
  }
}

String? _normalizedBarcodeImagePath(String imagePath) {
  final normalized = normalizedReceiptPhotoPath(imagePath);
  if (normalized == null || normalized.contains('\u0000')) return null;
  if (!normalized.startsWith('/')) return null;
  final lower = normalized.toLowerCase();
  const imageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif'];
  return imageExtensions.any(lower.endsWith) ? normalized : null;
}

List<ReceiptScannedCode> _dedupeScannedCodes(List<ReceiptScannedCode> codes) {
  final seen = <String>{};
  return List.unmodifiable([
    for (final code in codes)
      if (code.hasValue &&
          seen.add('${code.format.name}:${code.normalizedValue}'))
        code,
  ]);
}

List<mlkit.BarcodeFormat> _mlkitFormatsFor(List<ReceiptBarcodeFormat> formats) {
  if (formats.isEmpty) return const [mlkit.BarcodeFormat.all];
  return List.unmodifiable(formats.map(_formatToMlKit));
}

mlkit.BarcodeFormat _formatToMlKit(ReceiptBarcodeFormat format) {
  return switch (format) {
    ReceiptBarcodeFormat.all => mlkit.BarcodeFormat.all,
    ReceiptBarcodeFormat.unknown => mlkit.BarcodeFormat.unknown,
    ReceiptBarcodeFormat.code128 => mlkit.BarcodeFormat.code128,
    ReceiptBarcodeFormat.code39 => mlkit.BarcodeFormat.code39,
    ReceiptBarcodeFormat.code93 => mlkit.BarcodeFormat.code93,
    ReceiptBarcodeFormat.codabar => mlkit.BarcodeFormat.codabar,
    ReceiptBarcodeFormat.dataMatrix => mlkit.BarcodeFormat.dataMatrix,
    ReceiptBarcodeFormat.ean13 => mlkit.BarcodeFormat.ean13,
    ReceiptBarcodeFormat.ean8 => mlkit.BarcodeFormat.ean8,
    ReceiptBarcodeFormat.itf => mlkit.BarcodeFormat.itf,
    ReceiptBarcodeFormat.qrCode => mlkit.BarcodeFormat.qrCode,
    ReceiptBarcodeFormat.upca => mlkit.BarcodeFormat.upca,
    ReceiptBarcodeFormat.upce => mlkit.BarcodeFormat.upce,
    ReceiptBarcodeFormat.pdf417 => mlkit.BarcodeFormat.pdf417,
    ReceiptBarcodeFormat.aztec => mlkit.BarcodeFormat.aztec,
  };
}

ReceiptBarcodeFormat _formatFromMlKit(mlkit.BarcodeFormat format) {
  return switch (format) {
    mlkit.BarcodeFormat.all => ReceiptBarcodeFormat.all,
    mlkit.BarcodeFormat.unknown => ReceiptBarcodeFormat.unknown,
    mlkit.BarcodeFormat.code128 => ReceiptBarcodeFormat.code128,
    mlkit.BarcodeFormat.code39 => ReceiptBarcodeFormat.code39,
    mlkit.BarcodeFormat.code93 => ReceiptBarcodeFormat.code93,
    mlkit.BarcodeFormat.codabar => ReceiptBarcodeFormat.codabar,
    mlkit.BarcodeFormat.dataMatrix => ReceiptBarcodeFormat.dataMatrix,
    mlkit.BarcodeFormat.ean13 => ReceiptBarcodeFormat.ean13,
    mlkit.BarcodeFormat.ean8 => ReceiptBarcodeFormat.ean8,
    mlkit.BarcodeFormat.itf => ReceiptBarcodeFormat.itf,
    mlkit.BarcodeFormat.qrCode => ReceiptBarcodeFormat.qrCode,
    mlkit.BarcodeFormat.upca => ReceiptBarcodeFormat.upca,
    mlkit.BarcodeFormat.upce => ReceiptBarcodeFormat.upce,
    mlkit.BarcodeFormat.pdf417 => ReceiptBarcodeFormat.pdf417,
    mlkit.BarcodeFormat.aztec => ReceiptBarcodeFormat.aztec,
  };
}
