const expectedExpenseTelemetryOcrFailureSourceBuckets = {
  'photo',
  'pdf',
  'importedtext',
  'mixed',
  'none',
  'unknown',
};

const expectedExpenseTelemetryDrilldownOcrFailureSourceBuckets = {
  ...expectedExpenseTelemetryOcrFailureSourceBuckets,
  'not_ocr',
};
