# Reusable Parsing QA Handoff Index

Last updated: 2026-07-09 21:11 EDT

This is the single first file the Mac Mini side should open.

Current baseline:

- Branch: `codex/reusable-parsing-qa-foundation`
- Validated floor commit: `610a2f0`
- Commit label:
  `Reusable parsing QA 2026-07-09 09:09 PM EDT: harden handoff refresh templates`

Open these in order:

1. `docs/reusable_parsing_qa_handoff_marker.md`
2. `docs/reusable_parsing_qa_scope_boundary.md`
3. `docs/reusable_parsing_qa_checkpoint.md`
4. `docs/reusable_parsing_qa_mac_runbook.md`
5. `docs/reusable_parsing_qa_mac_handoff_packet.json`
6. `dart run tool/reusable_parsing_qa_handoff_status.dart --root .`

What this means:

- The marker is the top human-readable boundary and ownership file.
- The scope boundary file is the explicit reusable-versus-inventory split.
- The checkpoint file is the current Windows-next versus Mac-next state.
- The runbook is the plain-English execution sequence.
- The packet is the machine-readable source of exact Mac-side commands.
- The handoff status command is the machine-checkable summary of doc alignment,
  and on the Windows execution branch it also enforces PEH packet parity.
- The branch tip is authoritative; the listed commit is the last Windows-validated floor.

Do not trust older chat instructions over these committed files.
