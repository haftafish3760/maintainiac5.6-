part of 'receipt_native_camera_contract.dart';

const _receiptNativeCameraSettingDescriptors = <ReceiptNativeCameraSettingDescriptor>[
  ReceiptNativeCameraSettingDescriptor(
    id: 'assisted_receipt_fill',
    label: 'Help fill my receipt',
    description:
        'Optional. Maintainiac reads the receipt and opens the review form after you turn Receipt Assist on.',
    group: ReceiptNativeSettingGroup.capture,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: false,
  ),
  ReceiptNativeCameraSettingDescriptor(
    id: 'auto_capture',
    label: 'Automatic photo capture',
    description:
        'Optional and off by default. Maintainiac waits for several steady, well-framed receipt views before taking a photo. The shutter button still works anytime.',
    group: ReceiptNativeSettingGroup.capture,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: false,
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
        'Show receipt edges for crop guidance and safe straightening checks.',
    group: ReceiptNativeSettingGroup.receiptGuidance,
    type: ReceiptNativeSettingType.toggle,
    defaultEnabled: true,
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
        'Prepare a cleaner receipt photo using crop, straighten, contrast, grayscale, and shadow cleanup.',
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
];
