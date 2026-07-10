# Reusable Parsing QA Handoff Index

Last updated: 2026-07-09 20:54 EDT

This is the single first file the Mac Mini side should open.

Current baseline:

- Branch: `codex/reusable-parsing-qa-foundation`
- Validated floor commit: `451211e`
- Commit label:
  `Reusable parsing QA 2026-07-09 20:54 EDT: fold parity into handoff status`

Open these in order:

1. `docs/reusable_parsing_qa_handoff_marker.md`
2. `docs/reusable_parsing_qa_scope_boundary.md`
3. `docs/reusable_parsing_qa_checkpoint.md`
4. `docs/reusable_parsing_qa_mac_runbook.md`
5. `docs/reusable_parsing_qa_mac_handoff_packet.json`

What this means:

- The marker is the top human-readable boundary and ownership file.
- The scope boundary file is the explicit reusable-versus-inventory split.
- The checkpoint file is the current Windows-next versus Mac-next state.
- The runbook is the plain-English execution sequence.
- The packet is the machine-readable source of exact Mac-side commands.
- The branch tip is authoritative; the listed commit is the last Windows-validated floor.

Do not trust older chat instructions over these committed files.
