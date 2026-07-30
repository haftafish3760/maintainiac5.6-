# Local Real-Receipt OCR Benchmark Intake

This is a local-only measurement workflow. It does not upload receipt photos,
receipt text, merchant data, or customer data. Keep the working JSON and any
photos under `build/local_receipt_benchmark/`, which is already ignored by Git.
Do not commit real receipts or labeled receipt text.

## What counts as one sample

One anonymous `sourceId` represents one physical receipt. For a long receipt,
the complete ordered photo set and its reconstructed result are still one
sample. A source can have more than one honest condition tag—for example,
`thermal` and `fuel`—but it can appear only once in a benchmark run.

Use three different real receipt sources for every required condition:

- `thermal`, `faded`, `glare`, `shadow`, `rotated`, `perspective`
- `tiny_print`, `low_light`, `high_light`
- `fuel`, `inventory`, `mixed`, `unsupported`, `screenshot`
- `long_receipt_reconstructed`

The same condition may be covered by more than three sources. Do not relabel
or duplicate one receipt to meet the count.

## One OCR version at a time

Every real case in a release run must use the same `engine` and
`processingVersion`. Run a new benchmark for each OCR build or configuration.
Mixing versions measures neither one honestly, so the release gate rejects it.

## Local result format

Create a local JSON file such as
`build/local_receipt_benchmark/2026-07-30-local-v1.json`:

```json
{
  "cases": [
    {
      "id": "local-001",
      "provenance": {
        "sourceId": "receipt-set-001",
        "sourceKind": "camera",
        "engine": "on_device_mlkit",
        "processingVersion": "receipt_ocr_v1",
        "scenarioTags": ["thermal", "long_receipt_reconstructed"]
      },
      "expected": {
        "text": "locally labeled receipt text",
        "merchant": "locally labeled merchant",
        "date": "2026-07-30",
        "subtotal": "10.00",
        "tax": "0.80",
        "total": "10.80",
        "lines": ["locally labeled lines"],
        "route": "expenseReview"
      },
      "actual": {
        "text": "text supplied by the app",
        "merchant": "merchant supplied by the app",
        "date": "2026-07-30",
        "subtotal": "10.00",
        "tax": "0.80",
        "total": "10.80",
        "lines": ["lines supplied by the app"],
        "route": "expenseReview"
      }
    }
  ]
}
```

`sourceId` must be anonymous. Do not put a file path, receipt text, account
number, customer name, phone number, or payment information in provenance.

## Run the gate

```sh
dart tool/receipt_ocr_benchmark_runner.dart \
  --input=build/local_receipt_benchmark/2026-07-30-local-v1.json \
  --release-gate
```

The command exits nonzero until every required condition has three independent
real sources, each reported metric reaches the selected threshold, and the run
contains one OCR engine/version. A passing result is evidence for that exact
local OCR run—not a license to skip human receipt review.
