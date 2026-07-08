# Electrical Core Parser Readiness Roadmap

This roadmap pins the active work to Electrical Residential Core inventory and
parser QA. Do not use it to justify OCR, camera, expenses, UI, PDF, Plumbing,
HVAC, or unrelated module work.

## Objective

Make Electrical Core release-ready for common residential service use in the
United States, in English and Spanish, using the Plumbing Core readiness pattern:
catalog membership, item metadata, realistic receipt fixtures, parser evidence,
readiness audit, progress memory, and milestone commits.

## Operating Rules

- Electrical Core must be proven by behavior and readiness artifacts, not by
  string scans alone.
- Do not broaden into Electrical Standard, Professional, or Complete until
  Core is clean.
- Do not run broad/heavy shards while family metadata, fixture coverage, parser
  routes, or known focused failures remain open.
- Fix parser or metadata causes directly. Do not cap, waive, hide, or weaken
  confidence to make checks pass.
- Use small focused reruns first, then family shards, then full Core validation.
- Keep Plumbing Core validation running independently from the clean committed
  source; do not let that run become an excuse to drift.

## Family Order

1. Wire and cable.
   - NM-B, UF-B, THHN/THWN, low-voltage, common service cable.
   - Must distinguish wire gauge/count/length and avoid plumbing/HVAC copper
     or cable-like false positives.
2. Boxes and covers.
   - Old-work, new-work, metal handy, ceiling/fan-rated, junction, weatherproof,
     mud rings, extension rings, covers, wall plates.
3. Devices and controls.
   - Duplex, GFCI, WR/TR, switches, dimmers, timers, occupancy sensors, USB,
     smart controls when normal residential service stock.
4. Breakers and panels.
   - Common single/double pole, GFCI/AFCI/dual function, tandem, load-center
     accessories, panel covers/fillers where service-stock relevant.
5. Conduit and fittings.
   - EMT, PVC electrical conduit, flex/MC support fittings, connectors,
     couplings, straps, bushings, locknuts.
6. Connectors and consumables.
   - Wire nuts, lever connectors, butt splices, electrical tape, anti-short
     bushings, staples, cable clamps, wire lube/pulling items where core.
7. Grounding and bonding.
   - Ground rods, clamps, pigtails, bonding jumpers, grounding screws, lugs.
8. Lighting, alarms, and low-voltage service.
   - Keyless lampholders, fixture straps, smoke/CO alarms, doorbell
     transformer/chime, basic residential lighting service items.
9. Service equipment and disconnects.
   - AC disconnects, pullouts, safety switches, outdoor covers, surge
     protection where normal residential service stock.

## Validation Ladder

1. Electrical Core readiness audit.
2. Metadata enrichment for required Electrical Core fields.
3. Family generator isolation tests.
4. Focused parser fixture ID reruns.
5. Family shard reruns.
6. Electrical Core readiness audit must report all Core rows release-ready.
7. Full Electrical Core generated en-US and es-US validation.
8. Progress memory update and milestone push.

## Completion Standard

- Electrical Core readiness JSON reports all Core rows release-ready.
- Needs-work and critical counts are zero.
- English and Spanish parser terms are present.
- Every family has focused parser evidence.
- Full generated Electrical Core validation has no failures.
- Mac handoff is created after Windows deterministic proof.
