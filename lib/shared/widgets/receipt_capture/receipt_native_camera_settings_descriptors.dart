part of 'receipt_native_camera_contract.dart';

const _receiptNativeCameraSettingDescriptors = <ReceiptNativeCameraSettingDescriptor>[
  ReceiptNativeCameraSettingDescriptor(
    id: 'assisted_receipt_fill',
    label: 'Help fill my receipt',
    description:
        'Maintainiac reads the receipt and opens the review form for you.',
    group: ReceiptNativeSettingGroup.capture,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'review_depth',
    label: 'Receipt review detail',
    description:
        'Choose prices-only for fast review or detailed lines for more fields.',
    group: ReceiptNativeSettingGroup.review,
    type: ReceiptNativeSettingType.segmented,
    defaultValueLabel: 'Prices only',
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'auto_capture',
    label: 'Automatic photo capture',
    description:
        'Optional and off by default. Maintainiac waits for several steady, readable receipt frames before taking a photo. The shutter button still works anytime.',
    group: ReceiptNativeSettingGroup.capture,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: false,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'tap_focus',
    label: 'Advanced focus assist',
    description:
        'Off by default. Continuous autofocus stays primary; enable only on devices where a manual focus tap genuinely helps fuzzy receipt text.',
    group: ReceiptNativeSettingGroup.cameraControl,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: false,
    requiresNativeSupport: true,
    advanced: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'pinch_zoom',
    label: 'Pinch to zoom',
    description: 'Use two fingers to zoom while taking receipt photos.',
    group: ReceiptNativeSettingGroup.cameraControl,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: true,
    requiresNativeSupport: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'exposure_slider',
    label: 'Brightness slider',
    description:
        'Quickly brighten or darken a receipt without leaving the camera.',
    group: ReceiptNativeSettingGroup.cameraControl,
    type: ReceiptNativeSettingType.slider,
    defaultEnabled: true,
    requiresNativeSupport: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'exposure_reset',
    label: 'Reset brightness',
    description:
        'Return the receipt camera to its native brightness baseline after manual adjustment.',
    group: ReceiptNativeSettingGroup.cameraControl,
    type: ReceiptNativeSettingType.action,
    defaultEnabled: true,
    requiresNativeSupport: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'auto_exposure_assist',
    label: 'Auto brightness assist',
    description:
        'Make small safe brightness corrections when the receipt preview is clearly too dark or has glare.',
    group: ReceiptNativeSettingGroup.cameraControl,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: true,
    requiresNativeSupport: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'focus_lock',
    label: 'Lock focus when sharp',
    description: 'Stop focus hunting after the receipt text is clear.',
    group: ReceiptNativeSettingGroup.cameraControl,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: true,
    requiresNativeSupport: true,
    advanced: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'exposure_lock',
    label: 'Lock brightness when readable',
    description:
        'Stop brightness from jumping after the receipt text is readable.',
    group: ReceiptNativeSettingGroup.cameraControl,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: true,
    requiresNativeSupport: true,
    advanced: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'white_balance_lock',
    label: 'Lock receipt color',
    description:
        'Keep the paper tone stable after the receipt looks readable so cleanup and OCR see consistent contrast.',
    group: ReceiptNativeSettingGroup.cameraControl,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: true,
    requiresNativeSupport: true,
    advanced: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'receipt_light',
    label: 'Receipt light',
    description:
        'Use the device light only when needed for readable receipt text.',
    group: ReceiptNativeSettingGroup.cameraControl,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: false,
    requiresNativeSupport: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'edge_detection',
    label: 'Find receipt edges',
    description:
        'Show receipt edges and use them for crop and perspective correction.',
    group: ReceiptNativeSettingGroup.receiptGuidance,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'readability_warnings',
    label: 'Receipt readability warnings',
    description:
        'Warn about blur, glare, low light, shadows, tiny text, or missing receipt sections.',
    group: ReceiptNativeSettingGroup.receiptGuidance,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'dirty_lens_warning',
    label: 'Dirty lens warning',
    description:
        'Warn when the camera view looks hazy enough that receipt text may not read clearly.',
    group: ReceiptNativeSettingGroup.receiptGuidance,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: true,
    advanced: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'long_receipt_mode',
    label: 'Long receipt photos',
    description:
        'Capture receipts in sections with overlap guidance and section order review.',
    group: ReceiptNativeSettingGroup.longReceipt,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'image_cleanup',
    label: 'Clean receipt image',
    description:
        'Prepare a cleaner OCR source using crop, straighten, contrast, grayscale, and shadow cleanup.',
    group: ReceiptNativeSettingGroup.cleanup,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'safe_capture_queue',
    label: 'Protect captured photos',
    description:
        'Save accepted receipt photos locally right away in case a call, crash, or app switch interrupts the flow.',
    group: ReceiptNativeSettingGroup.storage,
    type: ReceiptNativeSettingType.automatic,
    defaultEnabled: true,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'save_space_preview',
    label: 'Space-saving proof size',
    description:
        'Preview the smaller proof copy used for storage after receipt assistance uses the clearest source.',
    group: ReceiptNativeSettingGroup.storage,
    type: ReceiptNativeSettingType.segmented,
    defaultValueLabel: 'Normal 200-300 KB',
  ),
];
