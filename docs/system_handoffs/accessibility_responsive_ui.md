# Accessibility And Responsive UI Living Handoff

## Current Status

`DEVICE TEXT SCALING PRESERVED / SCREEN-BY-SCREEN LAYOUT QA DEFERRED`.

Maintainiac's root `MaterialApp` does not replace, disable, or clamp Flutter's
platform `MediaQuery` text scaler. The operating system's accessibility font
setting therefore remains authoritative.

This is not a claim that every current screen lays out correctly at large or
maximum accessibility text sizes. A source inventory on 2026-07-22 found 134
production files using `maxLines` and 129 using `TextOverflow.ellipsis`.
Those uses are not automatically defects, but every user-facing action,
field label, amount, warning, and status must be reviewed in its owning screen.

## Product Requirements

- Always honor the device's current accessibility font setting.
- Do not add a global text-scale cap, `TextScaler.noScaling`, or a
  no-text-scaling `MediaQuery` wrapper.
- Do not solve overflow by silently shrinking accessible text with a global
  `FittedBox` or fixed font size.
- Primary actions, destructive-action warnings, field labels, totals, receipt
  review decisions, and navigation labels must not be cut off or hidden behind
  ellipsis.
- Layouts should grow, wrap, reflow, scroll, or change from horizontal to
  vertical presentation when larger text requires it.
- Intentional ellipsis may remain for secondary preview text only when the full
  value has an obvious accessible detail surface.
- Each screen-owning Codex task must test normal, large, and maximum supported
  device text sizes as part of that screen's UI completion work.

## Current Verification

- App shell owner: `lib/app/maintaniac_app.dart`
- Regression guard: `test/app_accessibility_text_scaling_contract_test.dart`
- The guard verifies that the app shell keeps `MaterialApp` and contains no
  global no-scaling, clamped-scaling, or fixed-scaler override.

## Remaining Work

- Audit responsive text behavior screen by screen as each unfinished screen is
  completed; do not attempt a blind application-wide mechanical rewrite.
- Add focused widget/golden tests at large text sizes for each completed screen.
- Test on representative small prepaid-phone dimensions as well as flagship
  dimensions because available width and accessibility scaling interact.
- Confirm TalkBack and VoiceOver semantics separately; text scaling alone does
  not establish full accessibility readiness.

## Rolling Log

- 2026-07-22: Verified that the 5.7 app shell preserves the operating system
  text scaler, added a regression contract, and recorded screen-by-screen
  responsive layout QA as required future work.
