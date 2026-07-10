# Reusable Parsing QA Checkpoint

Last updated: 2026-07-09 11:58 PM EDT

- Primary reusable branch: `codex/reusable-parsing-qa-foundation`
- Windows working branch: `codex/inventory-parser-backup-20260702-2056`
- Windows execution commit: `929c706`
- Validated floor commit: `8e9771d`
- Ready for Mac measurement wave: `true`
- Ready to claim 90-95 percent: `false`
- Remaining measured gap count: `38`
- Next trades by remaining gap: `hvac`

## Windows Next

- Keep Windows ownership on inventory-specific Work Supplies parser/code hardening.
- Do not claim 90-95 percent PEH readiness until the Mac wave closes the remaining measured gaps.
- Keep the branch below a 90-95 percent claim until the hvac remaining measured Mac wave clears.

## Mac Mini Next

- Run the Mac PEH measurement wave commands from the packet on branch codex/reusable-parsing-qa-foundation.
- Prioritize hvac because they still have measured coverage gaps.
- After the heavier run finishes, execute `dart run tool/work_supply_parser_qa_peh_core_post_mac_refresh.dart --root .` to rebuild the PEH and reusable handoff artifacts together.
