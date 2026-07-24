# Maintenance Receipt Parser Pass Log

This is the pass ledger for the maintenance receipt and maintenance-setup lane.
A pass is a bounded file/work edit cycle that ends only after its relevant test
or tests are green. Questions, status checks, Git inspection, failed or
interrupted checks, documentation-only corrections, and push-only activity are
not passes. Related changes stay bundled whenever safe, as required by
`PROJECT_RULES.md`.

Passes 1-35 were reconstructed on 2026-07-23 from completed source changes,
focused test results, milestone gates, and the roadmap because numbering did
not begin when the lane started. The reconstruction is conservative: uncertain
cycles were not counted. Pass 36 onward must be recorded immediately after its
required checks pass.

## Accepted passes

1. Workspace, ownership, and no-GitHub boundaries.
2. Stable maintenance record and vehicle identities.
3. Local maintenance persistence and serialized writes.
4. Restart recovery and legacy identity migration.
5. Reversible archive/restore without history loss.
6. Vehicle-rename continuity and event-list alias repair.
7. Pure parser input/result contract.
8. Purchase-versus-service receipt classification.
9. Initial maintenance-family candidate extraction.
10. Parser JSON validation and normalized SHA-256 identity.
11. Review mapper and editable candidate state.
12. Per-candidate decision validation.
13. Return, estimate, and declined-work contradiction handling.
14. Inert confirmed-command generation.
15. Versioned review-draft serialization.
16. Serialized local review-draft storage and recovery.
17. Maintenance-native receipt review screen.
18. Active-vehicle and global-odometer review binding.
19. Maintenance-owned plain-text handoff boundary.
20. Explicit final apply-consent dialog.
21. Atomic durable receipt application.
22. Retry idempotency and persisted provenance.
23. Manual maintenance setup prefill integration.
24. Initial structured merchant/item corpus.
25. Parser/review/test file splitting and 499-line gate.
26. Canonical command-integrity namespace v3.
27. Basic-default and Advanced-opt-in setup contract.
28. Corpus expansion through 14 exact cases.
29. Locale date and item-specific schedule safety.
30. Conservative text normalization, privacy, and odometer reads.
31. Semantic duplicate rejection and catalog alignment.
32. Unscoped return/declined-heading safety.
33. Future-date rejection and valid-date recovery.
34. Corpus expansion through 20 exact cases.
35. Dirty/crumpled recognized-text and fragmented-line safety. The focused
    four-test file and the full maintenance receipt gate passed; duplicate-line
    handling remained OCR-owned.
36. Full manual-catalog parser coverage. Added exact QA parity between every
    manual maintenance catalog item and the pure parser, including time-based
    key-fob battery, registration, and inspection receipts. Focused analysis,
    four catalog-contract tests, and the full maintenance receipt gate passed.
37. Cross-catalog development accuracy gate. Expanded the exact corpus to 23
    receipts so every current catalog family is represented, then added
    per-family precision, recall, and action-accuracy floors plus merchant,
    receipt-kind, and exact candidate-set measurements. The gate explicitly
    distinguishes synthetic development evidence from unseen real-receipt
    release proof. Focused checks and the full maintenance receipt gate passed.
38. Codex 5.3 Spark operating handoff. Added a contract-tested 100-pass wave
    manual defining pass mechanics, bundling, boundaries, accuracy rules,
    failure handling, 20-pass anti-drift audits, and the mandatory hundred-pass
    return handoff. The first contract run exposed one exact-wording mismatch;
    that failed cycle was not counted. The corrected two-test contract and full
    maintenance receipt gate passed.
39. Maintenance state model split. Moved maintenance records, service events,
    serialization, provenance, and model normalization helpers from the
    oversized shared state file into a descriptive 380-line library part.
    Focused analysis, 22 persistence/application checks, and the full
    maintenance receipt gate passed without behavioral changes.
40. Maintenance state controller split. Moved durable maintenance operations
    from shared state into a descriptive controller part while retaining a
    narrow notifier wrapper. The three affected state files are 481, 463, and
    380 lines. Full maintenance analysis, 37 broader persistence/UI checks, and
    the full maintenance receipt gate passed.
41. Maintenance state line-limit regression. Extended the maintenance-owned
    gate to format, analyze, and enforce the 499-line ceiling for the shared
    state facade plus both maintenance state parts. The full maintenance
    receipt gate and diff integrity check passed.
42. Bounded OCR-layout and service-alias coverage. Added eight explicitly
    classified fixtures for wrapped descriptions, detached prices, three-row
    item names, service codes, service-only aliases, and a parts-store alias
    collision guard. Matching may now use up to three adjacent recognized-text
    rows, and service-only aliases are eligible only when the document has
    service evidence. Advanced details are scoped to each candidate's evidence,
    fixing front/rear brake detail leakage while retaining a narrow wrapped
    oil-type fallback. Two focused failures exposed the axle scoping and
    shortest-window defects and were not counted. The corrected layout suite,
    85-test broader parser set, and 142-check full maintenance gate passed.
43. Calendar schedule separation and Basic time-interval inference. Added a
    dedicated nine-test schedule suite proving that next-due dates cannot
    become completed-service dates, supported numeric and named dates can
    produce only exact one-to-36-month intervals, month-end clamping is safe,
    and reversed, unsupported-locale, or non-whole-month evidence stays
    review-only. Generic dates remain isolated from unrelated items on
    multi-service invoices, while item-specific schedules can apply to their
    own family. The focused parser/review/application regressions and the
    151-check full maintenance gate passed.
44. Merchant OCR aliases and general-retailer purchase boundaries. Added ten
    exact layout cases covering spaced and collapsed auto-parts names, a
    high-confidence `0`/`O` substitution, Walmart, Costco, Sam's Club, Tractor
    Supply, and Rural King purchases, plus unproven-versus-proven retailer
    service-center behavior. Known retailer receipts remain purchase-only
    unless a work order contains strong performed-service evidence; all results
    still require confirmation. The first full gate stopped at a pending
    formatter change and was not counted. After formatting, the focused
    merchant suite and 161-check full maintenance gate passed.
45. Manual-first periodic-family expansion. Added Timing Belt, Transfer Case
    Fluid, and PCV Valve to the canonical Basic manual catalog with
    representable mileage/month defaults before adding parser definitions.
    Exact purchase and completed-service fixtures preserve separation from
    serpentine belts and transmission fluid. The first focused run exposed
    bare `ATF+4` leaking into the transmission family and was not counted; bare
    ATF is now intentionally system-ambiguous unless the receipt names the
    maintained system. Catalog, icon, and line-limit coverage were added to the
    maintenance gate. The corrected development-accuracy checks and 167-check
    full gate passed.
46. Transaction-adjustment and true-return separation. Battery core charges,
    deposits, credits, refunds, returns, and exchanges are now treated as
    financial adjustments rather than proof that the purchased battery itself
    was returned. Actual maintenance-product returns and exchanges still force
    manual review, while coupons remain neutral. Added exact cases for a battery
    purchase with core credit, a true battery return, an oil/filter coupon, a
    battery warranty replacement, and a true oil-filter exchange. The first
    full gate exposed vehicle-Battery leakage from `KEY FOB BATTERY REPLACED`
    and was not counted. The corrected specific-family boundary, 24-case layout
    corpus, and 172-check full maintenance gate passed.
47. Transaction-policy disclosure separation. Printed `RETURN POLICY` and
    `EXCHANGE POLICY` footers no longer turn an otherwise valid maintenance
    purchase into a returned-product event. Two exact oil and battery purchase
    cases protect that boundary while the true-return and true-exchange cases
    from Pass 46 remain manual-review regressions. Focused analysis, the
    layout/return safety suite, and the 174-check full maintenance gate passed.
48. Candidate-scoped mixed return/purchase transactions. When a receipt
    explicitly identifies the returned or exchanged maintenance item, generic
    refund-tender rows no longer contaminate a different item purchased in the
    same transaction. Standalone return headings and refunds with no
    item-specific return evidence remain receipt-wide manual-review safeguards.
    Added exact brake-return/oil-purchase, filter-exchange/wiper-purchase, and
    ambiguous-refund contracts. Focused analysis and return/layout safety tests
    passed, followed by the 177-check full maintenance gate.
49. Locale-safe dot-separated receipt dates. Common numeric dates such as
    `07.08.26` and `23.07.26` now use the same two-digit-year, supported-locale,
    future-date, and next-due separation rules as slash and dash formats.
    Ambiguous dot-separated dates under an unsupported locale remain unset for
    manual entry. The first focused run used an incorrect ambiguity expectation
    for `07.23.26` and was not counted. The corrected temporal, schedule, and
    parser-safety suite passed, followed by the 180-check full maintenance gate.
50. Deterministic service-status sections. Explicit `SERVICE PERFORMED`,
    `WORK COMPLETED`, `DECLINED SERVICES`, and recommendation headings now
    scope status only to following candidate rows until another explicit status
    heading resets the section. Completed work before a declined section and
    completed work after a declined/recommended section can remain completed-
    service suggestions, while declined/recommended candidates stay manual.
    Ambiguous document-level estimates remain receipt-wide manual review.
    Focused analysis and 32 parser/service-safety checks passed, followed by the
    182-check full maintenance gate.
51. Completed-section warranty and comeback evidence. Terse maintenance item
    rows beneath an explicit performed/completed heading can now use that
    section as performed-work evidence even when the row is zero-dollar,
    `NO CHARGE`, or does not repeat an operation verb. Added exact automotive-
    battery warranty and brake-pad comeback contracts, including a completed
    invoice without a work-order phrase. Declined/recommended sections still
    override completion for their rows. Focused analysis and 34 service/parser
    safety checks passed, followed by the 184-check full maintenance gate.
52. Multi-odometer invoice safety. Explicit mileage/odometer out remains the
    preferred completed-service reading, explicit in is the fallback, and
    clearly labeled prior/previous/last mileage can no longer outrank the
    current service reading. A reversed pair where out is below in now forces
    review while retaining the printed out value as an editable suggestion; it
    never changes global odometer truth. Added exact reversed-pair and
    historical-versus-current contracts. Focused analysis and 44 parser/review
    safety checks passed, followed by the 186-check full maintenance gate.
53. Kilometer evidence cannot populate mile fields. Service odometer, next-due
    odometer, and interval values explicitly labeled in kilometers now remain
    unset for manual conversion and review because canonical maintenance
    storage is currently miles-only. A separately proven mile service reading
    remains available when only the due value is in kilometers. No conversion
    is guessed, no receipt value changes global odometer truth, and the parser
    preserves OCR lines without deduplication. Added exact service, mixed-unit,
    and interval contracts. Focused analysis and 26 related regression checks
    passed, followed by the 189-check full maintenance gate.
54. Kilometer-labeled odometer in/out safety. Common service-invoice forms such
    as `ODOMETER OUT 160000 KM`, `ODOMETER IN`, and abbreviated `ODO IN` now
    trigger the same miles-only manual-conversion safeguard as a plain
    odometer label. These readings cannot leak through the older in/out
    extraction precedence into a mile field. Added exact full-word and
    abbreviated contracts. Focused analysis and seven distance/odometer checks
    passed, followed by the 191-check full maintenance gate.
55. Plural kilometer-abbreviation safety. Receipt labels ending in `KMS` now
    receive the same miles-only safeguard as `KM` and full
    kilometer/kilometre words for service odometers, next-due odometers, and
    mileage intervals. This prevents generic numeric extraction from treating
    a plural-abbreviation value as miles. Added exact service, mixed-unit due,
    and interval contracts. Focused analysis and 19 distance/odometer/schedule
    checks passed, followed by the 194-check full maintenance gate.
56. Thousands-separated kilometer safety. Kilometer detection now uses the
    same comma-normalized comparison as numeric odometer extraction, so values
    such as `160,000 KM`, `NEXT DUE 170,000 KM`, and `EVERY 10,000 KM` cannot
    bypass the unit safeguard and enter miles-only fields. A separately proven
    comma-formatted mile reading remains available. Added exact service,
    mixed-unit due, and interval contracts. Focused analysis and 22
    distance/odometer/schedule checks passed, followed by the 197-check full
    maintenance gate.
57. Row-scoped space-grouped distance normalization. Values such as
    `160 000 KM` are now normalized within their original OCR row for both unit
    detection and numeric extraction, preventing a truncated `160`-mile
    suggestion. A matching `100 000 MI` value remains an editable 100,000-mile
    suggestion. Normalization occurs before rows are joined so unrelated
    numbers on adjacent lines cannot be merged. Added exact kilometer-service,
    mile-service, due, and interval contracts. Focused analysis and 25
    distance/odometer/schedule checks passed, followed by the 200-check full
    maintenance gate.
58. Dot- and apostrophe-grouped distance normalization. Row-scoped distance
    comparison now recognizes `160.000 KM` and `170'000 KM` without truncating
    either value to its leading digits or bypassing the kilometer safeguard.
    Matching dot- or apostrophe-grouped mile evidence remains an editable
    suggestion. Added exact service, mixed-unit schedule, and positive-mile
    contracts. Focused analysis and 19 distance/odometer checks passed,
    followed by the 203-check full maintenance gate.
59. Customer-request section safety. `CUSTOMER REQUESTED SERVICES`,
    `CUSTOMER REQUEST`, customer concern/state headings, and generic requested-
    service headings now start review-only sections. Items beneath them cannot
    inherit completed status from an earlier performed-work section, while a
    later explicit performed/completed heading safely resets the section.
    Added exact mixed-operation request-after-completion and
    concern-before-completion contracts. Focused analysis and 36
    service-section/parser/review checks passed, followed by the 205-check full
    maintenance gate.
60. Authorization and inspection-result section safety. Authorized/approved
    service, work, or repair headings and inspection result/finding headings
    now start review-only sections. Items beneath them cannot inherit completed
    status from earlier work, because authorization and a finding do not prove
    performance. A later explicit performed/completed heading resets the
    section. Added exact authorization-after-completion and
    finding-before-completion contracts. Focused analysis and 38
    service-section/parser/review checks passed, followed by the 207-check full
    maintenance gate.

## Current counter

- Last accepted pass: **60**
- Next pass: **61**
- Architecture/drift review due: after Pass 200 at the earliest, and no later
  than after Pass 300.

## OCR ownership boundary

OCR owns image perspective, crumple/crease cleanup, dirt/fade preparation,
overlap, and duplicated recognized lines. The maintenance parser does not
deduplicate OCR lines. Parser dirty-receipt passes may cover only conservative
recognized-text damage, fragmented item descriptions, safe review fallback,
and preservation of the original evidence text.
