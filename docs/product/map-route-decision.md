# Map Route Decision

## Decision Needed

The Notion spec asks for 지도 기반 이동 흐름 표시. Current MVP can show textual route previews without new dependencies. A real map requires choosing a map provider.

## Options

### Option A: No External Map For MVP

Use a custom lightweight canvas/polyline preview from local coordinates.

Pros:

- No API keys.
- No external tracking surface.
- Faster to ship.

Cons:

- Less familiar than real maps.
- Cannot show streets/landmarks.

### Option B: Google Maps

Use Google Maps Flutter plugin.

Pros:

- Familiar map UX.
- Good Android support.

Cons:

- API key, billing, privacy review, dependency setup.

### Option C: OpenStreetMap-Based Flutter Map

Use tile-based map rendering.

Pros:

- More open ecosystem.
- Less tied to Google.

Cons:

- Tile policy, caching, attribution, dependency choices.

## Recommendation

Ship Option A first. Only add a real map after the route preview proves useful on a physical device.
