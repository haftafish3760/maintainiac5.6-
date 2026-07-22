# Maintainiac 5.7 System Handoffs

These are the authoritative, rolling system records for 5.7. Open the central
index first, then only the handoff for the assigned system.

Status terms:

- `PRESENT`: implementation evidence exists; this is not a QA claim.
- `VERIFIED SUBSET`: the named checkpoint or tests passed.
- `DEFERRED`: approved direction intentionally not implemented yet.
- `NEEDS RECONCILIATION`: source-repository differences remain to be compared.
- `UNVERIFIED`: no current evidence-based audit has been recorded.

Every system handoff must keep its screen inventory, current implementation,
verification evidence, deferred decisions, remaining reconciliation, and the
smallest useful start-here file list current. Never use conversation history as
the only record.

Cross-system test-runner or audit repairs must be recorded in every system
whose ownership boundary or verification evidence changed. A global QA note
never replaces the affected system handoffs.

Accessibility text scaling is a cross-system requirement. Every screen owner
must read `accessibility_responsive_ui.md` and record that screen's large-text
evidence in both the accessibility handoff and the screen's owning handoff.
