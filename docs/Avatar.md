# Avatar.md — Avatar system (Open Peeps art, layered + color slots)

**Status:** spec for "Avatar v2". Replaces the procedural robot-face avatar (background/backdrop/shape/eyes/mouth).
Related: `docs/Auth.md` §7 (profile & editor flow), `docs/Design.md`, `docs/Platform.md`.

## 1. Decision
- Art source: **Open Peeps** by Pablo Stanley — hand-drawn half-body line-art avatars, **CC0 1.0 (public domain)**. We use the **DiceBear "open-peeps" style definition** (a CC0 remix that already splits the drawing into swappable components and color groups) as the *source files*.
- **No runtime dependency on DiceBear's HTTP API** (we are local-first, offline, privacy-friendly). Assets are extracted **once at build time** and committed.
- **Never copy another app's illustrations.** Only Open Peeps/DiceBear-CC0 art and our own originals.
- CC0 needs no attribution, but we credit it anyway: **Settings → Credits** lists "Avatar art: Open Peeps by Pablo Stanley (CC0 1.0), via DiceBear". Keep the definition's license text in `assets/avatar/open_peeps/LICENSE.txt`.
- Verify the license on `dicebear.com/licenses` at implementation time and record the date in `docs/Versions.md`.

## 2. Task order (do NOT skip step 0 and 1)
0. **Layout bug fix first** (separate PR): avatar editor is a **full-screen route outside the shell** (no bottom nav), Save button never under the nav/gesture area, preview never clipped by the header.
1. **Spike (no UI):** inspect the open-peeps definition JSON; write a short report in this file (§9) listing the real component groups, counts, color groups and canvas size. **Do not assume the names below — confirm them.**
2. Build-time extractor tool → committed assets.
3. Domain model + renderer.
4. Editor UI.
5. Tests, goldens, docs.

## 3. Source & extraction pipeline
- Source file: `open-peeps.json` from DiceBear's styles package (`@dicebear/styles`, or the `dicebear_styles` pub package). Commit a copy at `tool/avatar/source/open-peeps.json` with its license block.
- Tool: `tool/avatar/extract_open_peeps.dart` (pure Dart script, run from your own terminal: `dart run tool/avatar/extract_open_peeps.dart`). It must be **deterministic** and idempotent (re-running yields identical files).
- Output (committed): 
```
assets/avatar/open_peeps/
  LICENSE.txt
  manifest.json               # ids, groups, labels, canvas size, color slots, schemaVersion
  head/<id>.svg               # hair / head shapes
  face/<id>.svg               # expressions
  accessories/<id>.svg        # glasses etc. (+ "none")
  facial_hair/<id>.svg        # (+ "none")
  mask/<id>.svg               # (+ "none")  — decide in the spike whether to expose it
  base/body.svg               # canvas / torso with color placeholders
```
- **Color placeholders** inside SVGs use fixed tokens (`@skin`, `@hair`, `@clothing`, `@ink`, `@background`) — never raw hex — so one SVG serves every palette.
- Ids are **stable lowercase snake_case** derived from the source names (e.g. `head_short_curly`). Once shipped, **ids are never renamed** (they are persisted).
- A test fails if `manifest.json` references a missing file or an SVG contains an unreplaced/unknown token.

## 4. Data model (replaces the 5-index encoding)
```dart
final class AvatarConfig {
  final String headId;            // required
  final String faceId;            // required
  final String? accessoryId;      // null = none (glasses etc.)
  final String? facialHairId;     // null = none
  final String? itemId;           // v2.1 — our own original props (cat, sprout…); null for now
  final AvatarColors colors;
  final int version;              // catalog version
}
final class AvatarColors { final int background, skin, hair, clothing, ink; } // ARGB32, chosen only from curated palettes
```
- **Persist ids, not indices** (indices break whenever the catalog is reordered). Stored in the existing `app_settings` row as **JSON** (`profile.avatar`); no schema migration.
- **Decode never throws.** Unknown id → that part falls back to the default part; malformed/old `"a-b-c-d-e"` value → `AvatarConfig.initial`. (Prototype: no need to migrate old robot avatars.)
- `AvatarCatalog` is built from `manifest.json` (loaded once, cached). Domain stays pure Dart: the manifest is parsed in `data/`, and the catalog is passed in through an interface.
- `random(Random seed)` picks ids + palette entries; deterministic given the seed; every result must be valid.

## 5. Rendering
- Layer order (bottom → top): `background` → `base/body` → `head` → `face` → `facial_hair` → `accessories` → `mask` → `item`. Confirm the real order against the definition in the spike.
- Compose **one SVG string** per config (replace tokens, wrap layers in a single `<svg viewBox>` using the canvas size from the manifest) and draw it with **`flutter_svg`** (Flutter-team package; works on iOS/Android/web — add it to `docs/Versions.md` with the resolved version, justification in the PR).
- `Avatar(config, size, shape: circle|squircle)` widget: `RepaintBoundary`, clipped to a **circle** by default (profile/settings header) — matches the reference's circular preview.
- **Cache:** memoize the composed SVG string by config hash (LRU, ≤ 32 entries); dispose nothing global. Part thumbnails in the editor are also cached by `(group, id, colors)`.
- Light/dark: avatar colors are the user's choice and do **not** change with theme. The surrounding ring/background token does.
- Semantics: `semanticLabel` = localized "Your avatar".

## 6. Editor UI (dedicated full-screen page — no shell nav)
- Top bar: **✕** (cancel; confirm only if there are unsaved changes) · title · **✓ Save**.
- Pinned preview: **160 px circle**, centered, with comfortable top spacing; **Generate randomly** button under it (`AppFeedback.selection` haptic).
- Tabs (reference structure): **Head · Face · Glasses · Item · Colors**. Use the design-system tab/segmented control; keep the preview pinned while the tab content scrolls.
  - *Head*, *Face*: 3-column grid of part thumbnails, selected tile has a `brandPrimary` border (`Design.md`).
  - *Glasses*: first tile = "none" (⊘), then accessories.
  - *Item*: first tile = "none". **Empty state for now** ("More items coming soon") until v2.1 originals exist — do not fake items.
  - *Colors*: sections **Background · Outline · Hair · Skin tone · Outfit**, each a swatch row with a selected ring (reference structure).
- Palettes (curated, WCAG-friendly against the preview ring): background 8 · outline/ink 4 · hair 10 · skin 7 · outfit 10. Defined once in `avatar_palette.dart`.
- Responsive: compact = tabs under the preview; medium+ = preview left, tabs/grid right (`TwoPaneLayout`).
- States: loading (skeleton while manifest loads), error (`ErrorBanner` + retry), the usual haptics/undo conventions.
- Accessibility: every tile has a localized semantic label; tap targets ≥ 48 dp; works at text scale 2.0.

## 7. Performance & memory
- Never parse SVG for every tile on every rebuild: `GridView.builder` + cached thumbnails; thumbnails are small (≈ 72 px).
- The manifest is read once (`keepAlive` provider); SVG assets are loaded lazily per group when its tab is first opened.
- Verify: open/close the editor 10× in `--profile` — no memory growth.

## 8. Tests & acceptance
- Extractor: deterministic output, manifest ↔ files consistent, no unknown tokens.
- Domain: `AvatarConfig` JSON round-trip; unknown ids fall back; `random` ×500 always valid and reaches every part id; palette picks always in palette.
- Renderer: composed SVG contains each selected layer in the right order; cache hit for equal configs.
- Widget: editor paints every option of every tab without exceptions; Save is hit-testable (never covered); 360/768/1440 px × text scale 1.0/2.0 with no overflow.
- Golden: `Avatar` in circle/squircle, light/dark surround.
- **Done when:** the editor produces recognisably Open Peeps characters, persists across relaunch, matches the tab structure above, and passes the Definition of Done in `Agent.md`.

## 9. Spike report (agent fills this in)
_Real component groups, counts, color groups, canvas size, torso/clothing handling, whether "Top" exists as a swappable part (if not, the "Top" tab stays dropped and outfit = a color), mask usage._

## 10. Out of scope / later
- **v2.1 original items** (cat, sprout, headband… drawn by us as SVG with the same token scheme) → fills the *Item* tab.
- Photo avatars, avatar sync (it is one small JSON value, so it syncs for free with settings/profile in v0.4).

## 11. Open questions
- Expose the `mask` group? (decide in the spike)
- Circle-only or user-selectable shape?
