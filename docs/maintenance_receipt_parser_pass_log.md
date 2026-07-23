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

## Current counter

- Last accepted pass: **46**
- Next pass: **47**
- Architecture/drift review due: after Pass 200 at the earliest, and no later
  than after Pass 300.

## OCR ownership boundary

OCR owns image perspective, crumple/crease cleanup, dirt/fade preparation,
overlap, and duplicated recognized lines. The maintenance parser does not
deduplicate OCR lines. Parser dirty-receipt passes may cover only conservative
recognized-text damage, fragmented item descriptions, safe review fallback,
and preservation of the original evidence text.
