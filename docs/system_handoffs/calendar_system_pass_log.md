<!-- Calendar ownership: Calendar presentation, source-owned projections, and Calendar-native contracts only. -->

# Calendar System Pass Log

This log counts a pass only after its focused checks are green. It is not a
claim that unowned source systems, platform notification delivery, or physical
device validation are complete.

| Pass | Date | Capability | Verification |
| --- | --- | --- | --- |
| 1 | 2026-07-29 | Shared month tiles now derive planned, confirmed, and needs-review counts; Dashboard filtering is explicitly scoped to Dashboard. | 10 focused tests; Calendar analyzer |
| 2 | 2026-07-29 | Day timeline stays chronological and important timeline text wraps instead of truncating. | 14 focused tests; Calendar analyzer |
| 3 | 2026-07-29 | Month state badges use visible check/warning symbols with counts, not color-only `S`/`D` codes. | 14 focused tests; Calendar analyzer; whitespace check |
| 4 | 2026-07-29 | Shared responsive tiles, active vehicle/work-profile context, and the active-day Calendar placement were aligned across Calendar hosts. | Current Calendar regression replay; Calendar analyzer |
| 5 | 2026-07-30 | Calendar-native durable appointments project by source scope with honest planned timing, recurrence, exceptions, overnight carryover, and source-safe editing. | Schedule record/projection tests; Calendar analyzer |
| 6 | 2026-07-30 | Schedule editor gained repeat intervals, weekdays, end dates, explicit custom-day validation, and confirmation-gated soft removal. | 13 scheduling/recurrence tests; Calendar analyzer |
| 7 | 2026-07-30 | Calendar planner actions route to Calendar scheduling while missed records continue to route to their source owners. | Calendar routing, Jobs, and schedule tests |
| 8 | 2026-07-30 | Materials/Inventory calendar days receive source-owned transaction events and open an Inventory-owned read-only transaction detail. | Inventory projection, deep-link, and full Calendar regression tests |
| 9 | 2026-07-30 | Projection replay generator was corrected so stale revisions and state coverage are deterministic under every projection source. | Full Calendar-focused suite: 105 passing tests |
