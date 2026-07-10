# Reusable Parsing QA Handoff Index

Last updated: 2026-07-09 20:15 EDT

This is the single first file the Mac Mini side should open.

Current baseline:

- Branch: `codex/reusable-parsing-qa-foundation`
- Commit: `108b0d7`
- Commit label:
  `Reusable parsing QA 2026-07-09 20:13 EDT: refresh handoff docs to current baseline`

Open these in order:

1. `docs/reusable_parsing_qa_handoff_marker.md`
2. `docs/reusable_parsing_qa_mac_runbook.md`
3. `docs/reusable_parsing_qa_mac_handoff_packet.json`

What this means:

- The marker is the top human-readable boundary and ownership file.
- The runbook is the plain-English execution sequence.
- The packet is the machine-readable source of exact Mac-side commands.

When the Mac Mini advances the checkpoint and needs to refresh these handoff
docs, run:

`dart run tool/reusable_parsing_qa_handoff_refresh.dart`

Do not trust older chat instructions over these committed files.
