<!--
Contains the consolidated owner directive for Maintainiac GPS-assisted trip tracking.
Owns product intent, integrity rules, engineering workflow, QA expectations, and release evidence.
Does not own implementation state, test results, field evidence, or completion claims.
Consumed by every engineer or Codex task working on the trip-tracking subsystem.
The confirmed odometer and explicit human review remain authoritative throughout the lifecycle.
-->

# Maintainiac GPS-Assisted Trip Tracking: Master Directive

Date consolidated: 2026-07-28 EDT
Workspace: `/Users/rbbie/Documents/Maintainiac_5.7_Active`
Status: authoritative owner direction; completion must be proven from current evidence

## 1. Product Standard

Maintainiac trip tracking must be a world-class, commercial-grade system suitable for people who rely on it every working day. It is not a prototype, narrow demo, or feature that is considered finished because it compiles or passes a small synthetic test.

The supported audience includes residential contractors, service technicians, plumbers, electricians, HVAC workers, lawn-care crews, delivery drivers, rideshare and gig drivers, home-health workers, non-emergency medical transport, and other people using a vehicle for business.

The product must serve users with one occasional trip and users with eight, ten, or more scheduled stops in a day. It must support recurring customers and future calendar, invoice, estimate, customer-address, route-planning, and Mapbox integrations without making those systems prerequisites for reliable trip recording.

Engineering decisions should match the care expected from a senior GPS, Flutter, Android lifecycle, iOS lifecycle, Bluetooth, data-integrity, performance, security, test, UI, and commercial-readiness team.

## 2. Non-Negotiable Truth and Control Rules

- The confirmed odometer is canonical mileage truth.
- GPS supplies advisory evidence and a live projection.
- Tracking proposes; TripLog and the user confirm.
- GPS, Bluetooth, maps, Mapbox, cloud services, Firebase, OCR, or AI must never silently overwrite confirmed mileage.
- Bluetooth may identify or suggest a likely vehicle but must never silently reassign the vehicle of an active or completed trip.
- A human must review and confirm consequential trip, stop, vehicle, mileage, split, merge, and completion decisions.
- Manual TripLog must work without GPS, Bluetooth, maps, internet, Firebase, cloud services, or AI.
- GPS and sensor assistance must be opt-in, understandable, disableable, and recoverable.
- Only one active local tracking session may exist.
- Stationary behavior must never automatically finalize a trip.
- Walking must never create vehicle mileage.
- Maps remain optional and independent. Map failure must never prevent tracking.
- Local recording must continue without cellular service when device GPS remains available.
- Synthetic results must never be described as real-world accuracy or field verification.

## 3. Core User Experience

The dashboard must make the current workday and trip understandable at a glance. It should show:

- the active vehicle and whether it was manually selected or Bluetooth-suggested;
- GPS/provider state, including starting, live, degraded, interrupted, paused, and review required;
- advisory live mileage without presenting it as confirmed odometer truth;
- a chronological, easily distinguishable list of probable stops;
- why each stop was suggested and whether review is needed;
- walking evidence separated from vehicle distance;
- signal gaps and recovery without fabricating the missing route;
- clear manual controls to start, pause, resume, stop, correct, split, merge, dismiss, or confirm evidence;
- recovery guidance when permissions, battery conditions, Bluetooth, storage, or providers are unavailable.

The layout must remain usable with large text, long workdays, many stops, interruptions, poor connectivity, and users who are in a hurry.

## 4. Work Profiles and Scheduling Direction

The system must accommodate different work patterns:

- normal Monday-Friday or custom workweeks;
- weekend work;
- overnight shifts;
- on-call or 24/7 availability;
- recurring weekly customers;
- scheduled contractor jobs;
- unscheduled gig or delivery work;
- multiple stops at one location;
- revisits to the same customer;
- personal detours mixed with business travel;
- future calendar- and invoice-derived customer stops.

Future Mapbox routing may help order or display scheduled destinations, but it must remain a rendering and advisory adapter. It must not own mileage, session state, accepted/rejected GPS evidence, trip start, trip completion, or odometer projection.

## 5. Session and Data-Integrity Contract

Session transitions must be deterministic, serialized, durable, and recoverable. The system must reject or safely absorb:

- duplicate manual and Bluetooth starts;
- callbacks arriving more than once;
- duplicate and out-of-order samples;
- stale cached starting locations;
- duplicate events, revisions, completion attempts, and TripLog handoffs;
- callbacks from an older provider registration or older session;
- clock rollback, clock jumps, timezone changes, and daylight-saving changes;
- interrupted writes, partial writes, and corrupt newer snapshots;
- process death, operating-system kill, app restart, reboot, and background transitions;
- completion-pending and review-pending recovery.

Persist monotonic ordering and revision evidence separately from wall-clock display time. Never fabricate route distance across pauses, rejected samples, cached fixes, signal gaps, or provider outages. Keep measured distance, estimated gaps, and rejected distance distinct.

The system must preserve vehicle and profile attribution and must never rewrite confirmed history silently.

## 6. GPS and Stop-Detection Expectations

The engine must handle:

- immediate, delayed, missing, late, and duplicated provider registration;
- provider registration after timeout or cancellation;
- startup and recovery races;
- fresh, stale, approximate, inaccurate, invalid, mocked, duplicated, and out-of-order locations;
- impossible jumps and implausible speeds;
- urban canyons, tunnels, garages, tree cover, buildings, fields, rural roads, and off-road travel;
- temporary and prolonged signal loss with conservative recovery;
- stationary jitter, low-speed crawling, sharp turns, vibration, and stop-and-go traffic;
- walking before driving, after parking, between drive segments, and near the origin;
- brief pauses, long dwell, traffic lights, gridlock, loading, unloading, pickups, deliveries, fuel stops, rest stops, construction delays, and waiting;
- repeated drive, park, walk, return, and resume cycles;
- speeds from stationary and walking pace through approximately 50 MPH for the planned side-by-side test, plus normal roadway speeds supported by the product.

Stop detection must favor reviewable evidence over false certainty. It must distinguish likely stops from traffic control, GPS drift, walking, signal loss, and ordinary congestion.

## 7. Heartbeat, Battery, and Background Behavior

Provider liveness must distinguish fresh, stale, delayed, duplicated, missing, and out-of-order heartbeats. Degraded-state entry and recovery must be deterministic and must survive restart without creating distance.

Battery handling must cover normal, low, critical, charging, unplugging, battery saver, balanced, and high-accuracy modes. Low-battery protection may pause or reduce GPS collection safely, but it must not end the user's workday, invent mileage, corrupt projection, or discard review evidence.

When the user enables supported background tracking, Android and iOS must continue collecting according to platform rules while the app is backgrounded or the screen is locked. Permission loss, provider loss, operating-system restrictions, and service interruption must be visible, recoverable, and mileage-safe.

## 8. Bluetooth Vehicle Recognition and Premium Automation

Bluetooth vehicle recognition is the primary vehicle-identification signal where supported. The system must:

- use only user-approved device-to-vehicle associations;
- use opaque local identifiers rather than exposing raw hardware addresses;
- initialize production observation exactly once;
- handle delayed initialization and retries idempotently;
- handle Bluetooth disabled, denied, revoked, disconnected, and reconnected states;
- handle stale associations, renamed devices, wrong devices, and multiple known devices deterministically;
- ignore stale or duplicate connection broadcasts;
- keep manual vehicle selection and manual trip tracking available at all times;
- prevent a Bluetooth callback from taking ownership of an active trip;
- prevent manual/Bluetooth races from creating duplicate sessions.

For eligible premium users, approved settings may allow Bluetooth evidence to assist with starting the day automatically. This capability still requires explicit opt-in, entitlement validation, durable-session checks, provider readiness, duplicate suppression, and human review. Automation must never confirm official mileage or silently complete a trip.

## 9. Planned Owner Field Test

The initial owner test will use:

- Samsung Galaxy S24 Ultra;
- iPhone SE third generation when charged and available;
- a dead-end road slightly over one mile long;
- repeated driving, pulling over, exiting, walking, returning, and resuming;
- possible field and off-road travel in a side-by-side up to approximately 50 MPH;
- areas where cellular signal may be weaker but satellite sky visibility is generally good.

Before the owner drives, automated gates, platform builds, production wiring, permission readiness, background-service readiness, and coordinate-minimized evidence capture must be clean. Codex must not create or alter a real workday or confirmed mileage merely to test the app.

Field evidence should record independent odometer distance, advisory GPS distance, expected and detected stops, walking matches, provider/background/recovery observations, battery state, and uncertainty without retaining unnecessary coordinates.

One successful drive cannot establish a reliability percentage. Multiple representative runs are required before a commercial accuracy claim.

## 10. Device QA Tooling

Maintain one reusable, non-destructive device-validation entry point supporting Android and iOS modes. It must:

- perform platform-specific readiness checks;
- identify the exact connected device and app package/bundle;
- avoid installing to the wrong phone;
- build the intended variant before installation;
- require explicit owner involvement for consequential permission prompts and starting a real test session;
- verify foreground and background provider state without logging raw coordinates;
- capture bounded app logs and crash evidence;
- preserve coordinate-minimized field evidence;
- never clear application data, alter confirmed records, or start a normal workday automatically;
- report unsupported or unavailable checks honestly.

The S24 Ultra is the Android Maintainiac test device. Do not install Maintainiac on another Android phone without explicit instruction. The iPhone workflow must verify the physical device, signing, provisioning, bundle identity, and background location capability before install or launch.

## 11. Permanent Regression and Stress System

Use one deterministic, configurable, memory-bounded harness. Do not create copied suites for different counts. It must support:

- 1,000 smoke scenarios;
- 10,000 routine development scenarios;
- 100,000 development stress scenarios;
- 500,000 extended scenarios;
- 1,000,000 deep-stress scenarios only when explicitly requested.

The harness must generate incrementally, use bounded batches, discard successful traces, retain detailed traces only for failures, keep console output concise, and keep memory approximately stable as counts rise.

Scenario generation must meaningfully vary provider/startup, GPS evidence, motion/stops, lifecycle/recovery, battery/device state, Bluetooth state, distance/odometer classification, persistence, vehicle ownership, and TripLog handoff. Counts must not be inflated by repeating nearly identical cases.

Every run must record:

- master seed and harness version;
- Git revision and configuration;
- scenario count and family distribution;
- elapsed time and scenarios per second;
- invalid, skipped, and failed counts;
- bounded memory observations.

Every failure must preserve its seed, scenario index, family, parameters, minimal event sequence, initial state, expected and actual results, distance breakdown, session revision, and relevant persisted evidence. Minimize and promote every valid discovered failure into a named permanent regression case.

The same seed and configuration must reproduce the same scenario sequence. A deliberate failure-injection test must prove reproducibility.

During the present development stage, run at least 100,000 meaningful scenarios, repeat the same seed, then run a different seed. Run 500,000 only after the 100,000 gate is deterministic, correct, and memory-stable. Do not run 1,000,000 without explicit owner authorization.

## 12. Required Test Gates

Use impact-selected testing during repairs and major checkpoint gates after coherent milestones. Stop at the first legitimate failure, fix it, and rerun it.

Major checkpoint evidence includes:

1. formatting for changed Dart files;
2. focused Flutter analysis;
3. Bluetooth and automatic-start tests;
4. commercial workday and recovery suite;
5. native source-contract tests;
6. complete trip gate;
7. existing trip-tracking QA gate;
8. permanent regression corpus;
9. 100,000-scenario run;
10. same-seed repeat;
11. different-seed run;
12. Android debug build and readiness;
13. iOS build/signing/readiness when the iPhone is available;
14. owner-controlled physical field validation.

Compilation, analysis, unit tests, simulations, and builds are scoped evidence only. None alone proves physical background collection, stop accuracy, distance accuracy, or commercial readiness.

## 13. Pass and Working-Ledger Discipline

Maintain a visible sequential pass counter. Each pass has one bounded objective and reports its expected files/tests and unanswered question before work begins.

A pass ends only after inspection, repair, permanent regression coverage where applicable, focused and adjacent green tests, formatting, diff review, ledger update, and a concise result. A blocked pass must identify its exact blocker and must not be called complete.

The working ledger records:

- branch, revision, upstream, and Git status;
- unrelated dirty files that must remain untouched;
- authoritative owners and runtime entry points;
- files and symbols already inspected and the question each answered;
- failure list and root-cause hypotheses;
- repairs and regression cases;
- tests, exit codes, elapsed time, and retained logs;
- current pass, objective, result, and next action.

Use the ledger to avoid repetitive searches and unnecessary file reads.

## 14. Repository, File, and Token Discipline

- Remain in the current main 5.7 checkout and current branch.
- Do not create a branch or worktree.
- Do not switch branches, reset, rebase, force-push, clean, discard, overwrite, or revert unrelated work.
- Preserve unrelated modified and untracked files exactly.
- Search for an exact symbol or failure before reading.
- Open only the smallest sufficient source range.
- Do not dump full files or successful logs into conversation output.
- Do not rerun expensive gates after every small edit.
- Do not create duplicate trackers, stores, engines, bindings, or QA harnesses.
- Keep every new maintainable file at 500 lines or fewer with a responsibility header.
- Avoid enlarging existing oversized files; extract focused responsibility only when correctness or testability justifies it.
- Do not cut necessary investigation or validation to save tokens.

## 15. Git Checkpoint Discipline

Commit and push coherent, verified GPS checkpoints approximately every 30-60 minutes and immediately after major verified milestones. Review status and scoped diffs first, stage only intended files, and leave unrelated work untouched.

Commit messages must explain what changed, why it was needed, validation performed, what remains, and why the checkpoint is being pushed. If a safe diagnostic checkpoint must be preserved while tests remain failing, label it honestly and list the failures. Never describe an incomplete checkpoint as verified.

## 16. Current Work Order

1. Verify the current checkpoint and reproduce every complete-trip-gate failure.
2. Repair legitimate provider-registration, battery/projection, heartbeat, and native-contract defects.
3. Complete production Bluetooth-to-trip bootstrap and permanent regression coverage.
4. Establish the permanent regression corpus.
5. Extend one scalable deterministic stress harness and run the 100,000 scenario gates.
6. Obtain clean focused analysis, complete trip QA, commercial replay, and platform builds.
7. Prepare the S24 Ultra and iPhone SE device-validation script.
8. Perform owner-controlled Android and iOS readiness and runtime checks.
9. Perform multiple controlled road and field runs with coordinate-minimized evidence.
10. Reassess whether Mapbox work may safely begin.

## 17. Completion Standard

Completion requires requirement-by-requirement evidence from the current source, tests, builds, runtime, and field observations. Uncertain, missing, indirect, stale, or purely synthetic evidence is not completion.

Final reporting must identify the exact production Bluetooth call path, root cause and repair for every original failure, permanent regression cases, stress distribution and reproducibility, runtime and memory observations, platform build status, device and field evidence, remaining failures, uncommitted files, and whether the subsystem is ready for install, owner testing, Mapbox integration, or commercial claims.

Evidence classifications:

- PRESENT
- WIRED
- VERIFIED SUBSET
- NEEDS RECONCILIATION
- FIELD QA PENDING
- BLOCKED
- NOT FOUND
