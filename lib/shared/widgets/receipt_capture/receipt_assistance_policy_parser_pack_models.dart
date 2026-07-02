part of 'receipt_assistance_policy.dart';

class ReceiptParserPackDisclosure {
  const ReceiptParserPackDisclosure({
    required this.code,
    required this.label,
    required this.categoryCode,
    required this.availability,
    required this.targetAccuracyBand,
    required this.estimatedBytes,
    required this.requiresInternet,
  });

  final String code;
  final String label;
  final String categoryCode;
  final ReceiptParserPackAvailability availability;
  final String targetAccuracyBand;
  final int estimatedBytes;
  final bool requiresInternet;

  bool get isOptionalLocalDownload =>
      availability == ReceiptParserPackAvailability.optionalLocalDownload;

  bool get isCloudFallback =>
      availability == ReceiptParserPackAvailability.cloudFallback;

  Map<String, Object?> toPrivacySafeDiagnostics() {
    return {
      'code': code,
      'categoryCode': categoryCode,
      'availability': availability.name,
      'targetAccuracyBand': targetAccuracyBand,
      'estimatedBytes': estimatedBytes,
      'requiresInternet': requiresInternet,
    };
  }
}

class ReceiptParserPackInstallChoice {
  const ReceiptParserPackInstallChoice({
    required this.includedLocalPackCodes,
    required this.optionalLocalDownloadPackCodes,
    required this.cloudFallbackPackCodes,
    required this.optionalLocalDownloadBytes,
    required this.requiresInternetForFallback,
    required this.accuracyBands,
  });

  factory ReceiptParserPackInstallChoice.fromDisclosures(
    Iterable<ReceiptParserPackDisclosure> disclosures,
  ) {
    final includedLocal = <String>[];
    final optionalLocal = <String>[];
    final cloudFallback = <String>[];
    final accuracy = <String, String>{};
    var optionalBytes = 0;
    var requiresInternet = false;

    for (final disclosure in disclosures) {
      accuracy[disclosure.code] = disclosure.targetAccuracyBand;
      switch (disclosure.availability) {
        case ReceiptParserPackAvailability.includedLocal:
          includedLocal.add(disclosure.code);
        case ReceiptParserPackAvailability.optionalLocalDownload:
          optionalLocal.add(disclosure.code);
          optionalBytes += disclosure.estimatedBytes;
        case ReceiptParserPackAvailability.cloudFallback:
          cloudFallback.add(disclosure.code);
          requiresInternet = requiresInternet || disclosure.requiresInternet;
      }
    }

    return ReceiptParserPackInstallChoice(
      includedLocalPackCodes: List.unmodifiable(includedLocal),
      optionalLocalDownloadPackCodes: List.unmodifiable(optionalLocal),
      cloudFallbackPackCodes: List.unmodifiable(cloudFallback),
      optionalLocalDownloadBytes: optionalBytes,
      requiresInternetForFallback: requiresInternet,
      accuracyBands: Map.unmodifiable(accuracy),
    );
  }

  final List<String> includedLocalPackCodes;
  final List<String> optionalLocalDownloadPackCodes;
  final List<String> cloudFallbackPackCodes;
  final int optionalLocalDownloadBytes;
  final bool requiresInternetForFallback;
  final Map<String, String> accuracyBands;

  bool get hasOptionalLocalDownload =>
      optionalLocalDownloadPackCodes.isNotEmpty;

  bool get hasCloudFallback => cloudFallbackPackCodes.isNotEmpty;

  bool get canRunFullyOffline => !hasCloudFallback || hasOptionalLocalDownload;

  String get optionalLocalDownloadSizeLabel {
    return _formatReceiptBytes(optionalLocalDownloadBytes);
  }

  String get userFacingDownloadChoiceLabel {
    final local = hasOptionalLocalDownload
        ? 'Download about $optionalLocalDownloadSizeLabel for stronger offline receipt assistance.'
        : 'No extra local receipt-reading download is needed for this setup.';
    final cloud = hasCloudFallback
        ? 'Cloud fallback is optional, requires internet, and must be chosen by the user.'
        : 'Cloud fallback is off for this setup.';
    return '$local $cloud';
  }

  Map<String, Object?> toPrivacySafeDiagnostics() {
    return {
      'includedLocalPackCodes': includedLocalPackCodes,
      'optionalLocalDownloadPackCodes': optionalLocalDownloadPackCodes,
      'cloudFallbackPackCodes': cloudFallbackPackCodes,
      'optionalLocalDownloadBytes': optionalLocalDownloadBytes,
      'requiresInternetForFallback': requiresInternetForFallback,
      'accuracyBands': accuracyBands,
    };
  }
}
