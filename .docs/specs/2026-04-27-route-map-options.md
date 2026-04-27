# Route Map Options

Date: 2026-04-27

## Decision

Do not add a map dependency for the MVP.

Use the existing visit timeline and place summaries as the MVP route surface.
Revisit a visual map only after the product needs precise route visualization
more than lightweight daily reflection.

## Why

- The original MVP spec already excluded full map route visualization.
- The current app now has reliable local visit data, place clusters, today
  timeline preview, and real-device validation.
- A map dependency would add API-key setup, tile-source policy, privacy review,
  network behavior, and design complexity before the core reflection value is
  proven.
- The app promise is "record and interpret my day", not "show a navigation
  trace". A calm timeline fits that promise better for the current stage.

## Options Considered

### 1. Timeline And Route Summary First

Status: selected for MVP.

Use stored visits and places to show:

- Time-ordered day flow.
- Total movement distance and moving time.
- Main places visited.
- Newly noticed places.
- Notable changes versus recent days.

This keeps the app local-first and avoids new dependencies.

### 2. Lightweight Flutter Map

Status: defer.

Possible later if users explicitly need a visual route. This still requires:

- Tile-source decision and licensing review.
- Offline/network behavior decision.
- Location privacy review for rendered paths.
- Design work to avoid making the app feel like a surveillance tracker.

### 3. Native Google Maps

Status: defer.

Best for familiar map interaction, but too heavy for MVP because it introduces:

- API keys and platform setup.
- Billing/quota considerations.
- Extra release configuration.
- Stronger privacy expectations from users.

## Next Implementation If Needed

If route context becomes necessary, build a "route summary" before a map:

- Add a day detail screen from Today or History.
- Show ordered timeline items with distance between places.
- Show a simple text route such as `집 근처 -> 회사 근처 -> 카페`.
- Keep raw coordinates hidden unless the user explicitly asks for detailed
  location history.

Only after that proves insufficient should a map package be evaluated.

## Open Questions

- Does the user actually want to see exact movement paths, or just remember the
  shape of the day?
- Should raw route visualization be available at all if the app's emotional
  direction is reflective rather than tracking-heavy?
- If a map is added later, should it be local/offline-first or accept online
  tile/API dependencies?
