# Screen Notes Usage

Maintainiac is one app under one roof, but many screens are full applications
in their own right: mileage tracking, expenses, invoices, inventory/materials,
maintenance, employee profiles, calendars, dashboard command centers, and
related flows.

The `screen_notes/` folder exists to preserve user-stated product requirements
for those screens and modules. Before building or changing a screen, read the
matching TXT notes first.

## What Belongs In Screen Notes

- App requirements.
- Screen behavior.
- Required fields, buttons, routes, states, and workflows.
- Security, privacy, backup, sync, permission, and data rules.
- UI/UX requirements that affect how the app must work.
- Future feature notes that belong to a specific screen or module.
- Cross-screen rules such as shared calendar behavior, active vehicle rows,
  local-first storage, Firebase backup, and employee permission enforcement.

## What Does Not Belong

- Personal rambling that is not about the app.
- Repeated venting with no new app requirement.
- Long duplicated text that was already captured.
- Guesses invented by Codex.
- Implementation claims that have not been built or verified.

## How To Add Notes

When new requirements are stated, append them to the most relevant TXT file in
`screen_notes/` with a source/date or batch label.

If the requirement affects a specific Dart screen, also add it to the matching
file under `screen_notes/app_screens/` or create a focused batch companion note.

If the user repeats the same requirement, do not duplicate it unless the new
message changes the requirement.

If the message contains both app requirements and unrelated rambling, capture
only the app requirements.

## Working Rule

The screen notes are not optional background material. They are part of the
working product documentation for Maintainiac. Treat them as the user's durable
memory for what each screen/app is supposed to become.

