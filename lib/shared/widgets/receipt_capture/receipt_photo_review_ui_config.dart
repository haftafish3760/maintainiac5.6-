import 'package:flutter/material.dart';

/// Presentation-only controls for receipt photo review.
///
/// Camera capture, image processing, and OCR handoff deliberately do not live
/// here. Product/UI work can change this configuration without changing those
/// behaviors.
class ReceiptPhotoReviewUiConfig {
  const ReceiptPhotoReviewUiConfig({
    this.previewBackgroundColor = const Color(0xFF050607),
    this.topBarBackgroundColor = const Color(0xFF0D1316),
    this.controlsBackgroundColor = const Color(0xFF0D1316),
    this.controlsBorderColor = const Color(0xFF344047),
    this.primaryActionColor = const Color(0xFF28A745),
    this.showTopBar = true,
    this.showDecisionGuidance = true,
    this.showSecondaryTools = true,
    this.keepControlsOutsidePreview = true,
    this.topBarBottomSpacing = 4,
    this.previewControlsSinglePhotoHeight = 156,
    this.previewControlsMultiPhotoHeight = 178,
    this.cropControlsHeight = 78,
    this.orderControlsHeight = 142,
    this.stitchControlsHeight = 164,
    this.dataSaverControlsHeight = 168,
    this.previewControlsHeightFraction = .22,
    this.photoThumbnailHeight = 58,
    this.addPhotoLabel = 'Add Another Photo',
    this.retakeLabel = 'Retake',
    this.useReceiptLabel = 'Use Receipt',
    this.cropLabel = 'Crop',
    this.proofLabel = 'Proof',
    this.matchPhotosLabel = 'Match Photos',
    this.orderPhotosLabel = 'Check Photo Order',
    this.actionLabelResolver = _defaultActionLabel,
  });

  final Color previewBackgroundColor;
  final Color topBarBackgroundColor;
  final Color controlsBackgroundColor;
  final Color controlsBorderColor;
  final Color primaryActionColor;
  final bool showTopBar;
  final bool showDecisionGuidance;
  final bool showSecondaryTools;
  final bool keepControlsOutsidePreview;
  final double topBarBottomSpacing;
  final double previewControlsSinglePhotoHeight;
  final double previewControlsMultiPhotoHeight;
  final double cropControlsHeight;
  final double orderControlsHeight;
  final double stitchControlsHeight;
  final double dataSaverControlsHeight;
  final double previewControlsHeightFraction;
  final double photoThumbnailHeight;
  final String addPhotoLabel;
  final String retakeLabel;
  final String useReceiptLabel;
  final String cropLabel;
  final String proofLabel;
  final String matchPhotosLabel;
  final String orderPhotosLabel;
  final String Function(String action, String fallback) actionLabelResolver;

  static String _defaultActionLabel(String _, String fallback) => fallback;

  String labelFor(String action, String fallback) =>
      actionLabelResolver(action, fallback);

  ReceiptPhotoReviewUiConfig copyWith({
    Color? previewBackgroundColor,
    Color? topBarBackgroundColor,
    Color? controlsBackgroundColor,
    Color? controlsBorderColor,
    Color? primaryActionColor,
    bool? showTopBar,
    bool? showDecisionGuidance,
    bool? showSecondaryTools,
    bool? keepControlsOutsidePreview,
    double? topBarBottomSpacing,
    double? previewControlsSinglePhotoHeight,
    double? previewControlsMultiPhotoHeight,
    double? cropControlsHeight,
    double? orderControlsHeight,
    double? stitchControlsHeight,
    double? dataSaverControlsHeight,
    double? previewControlsHeightFraction,
    double? photoThumbnailHeight,
    String? addPhotoLabel,
    String? retakeLabel,
    String? useReceiptLabel,
    String? cropLabel,
    String? proofLabel,
    String? matchPhotosLabel,
    String? orderPhotosLabel,
    String Function(String action, String fallback)? actionLabelResolver,
  }) {
    return ReceiptPhotoReviewUiConfig(
      previewBackgroundColor:
          previewBackgroundColor ?? this.previewBackgroundColor,
      topBarBackgroundColor:
          topBarBackgroundColor ?? this.topBarBackgroundColor,
      controlsBackgroundColor:
          controlsBackgroundColor ?? this.controlsBackgroundColor,
      controlsBorderColor: controlsBorderColor ?? this.controlsBorderColor,
      primaryActionColor: primaryActionColor ?? this.primaryActionColor,
      showTopBar: showTopBar ?? this.showTopBar,
      showDecisionGuidance: showDecisionGuidance ?? this.showDecisionGuidance,
      showSecondaryTools: showSecondaryTools ?? this.showSecondaryTools,
      keepControlsOutsidePreview:
          keepControlsOutsidePreview ?? this.keepControlsOutsidePreview,
      topBarBottomSpacing: topBarBottomSpacing ?? this.topBarBottomSpacing,
      previewControlsSinglePhotoHeight:
          previewControlsSinglePhotoHeight ??
          this.previewControlsSinglePhotoHeight,
      previewControlsMultiPhotoHeight:
          previewControlsMultiPhotoHeight ??
          this.previewControlsMultiPhotoHeight,
      cropControlsHeight: cropControlsHeight ?? this.cropControlsHeight,
      orderControlsHeight: orderControlsHeight ?? this.orderControlsHeight,
      stitchControlsHeight: stitchControlsHeight ?? this.stitchControlsHeight,
      dataSaverControlsHeight:
          dataSaverControlsHeight ?? this.dataSaverControlsHeight,
      previewControlsHeightFraction:
          previewControlsHeightFraction ?? this.previewControlsHeightFraction,
      photoThumbnailHeight: photoThumbnailHeight ?? this.photoThumbnailHeight,
      addPhotoLabel: addPhotoLabel ?? this.addPhotoLabel,
      retakeLabel: retakeLabel ?? this.retakeLabel,
      useReceiptLabel: useReceiptLabel ?? this.useReceiptLabel,
      cropLabel: cropLabel ?? this.cropLabel,
      proofLabel: proofLabel ?? this.proofLabel,
      matchPhotosLabel: matchPhotosLabel ?? this.matchPhotosLabel,
      orderPhotosLabel: orderPhotosLabel ?? this.orderPhotosLabel,
      actionLabelResolver: actionLabelResolver ?? this.actionLabelResolver,
    );
  }
}
