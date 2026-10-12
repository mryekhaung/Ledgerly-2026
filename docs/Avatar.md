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

## 9. Spike report

**Source inspected:** `dicebear/styles/src/open-peeps.json` (the raw definition, 192 KB,
downloaded from the `dicebear/styles` repo on **12 Oct 2026**; also shipped in the
`dicebear_styles` pub package as `open_peeps`). Schema: `@dicebear/schema@2.0.1`.
Top-level keys: `meta`, `canvas`, `attributes`, `components`, `colors`.

### 9.1 License (verified 12 Oct 2026)
- `meta.license` inside the definition: **`CC0 1.0`**, url `creativecommons.org/publicdomain/zero/1.0/`,
  text *"Remix of „Open Peeps" (openpeeps.com) by „Pablo Stanley", licensed under „CC0 1.0"."*
- Confirmed on `dicebear.com/licenses` (checked 12 Oct 2026): **Open Peeps is listed under "CC0 1.0"**
  ("Remix of Open Peeps by Pablo Stanley"). CC0 needs no attribution — we credit anyway (§1).
- `meta.creator` = Pablo Stanley, `meta.source` = Open Peeps. Recorded in `docs/Versions.md`.

### 9.2 Canvas & layer order
- **Canvas: `704 × 704`** (`canvas.width` / `canvas.height`). The avatar is a **half-body**
  drawing whose torso+arms are **baked into the canvas** — not a swappable part.
- `canvas.elements` in draw order (bottom → top) — this is the authority for §5's layer order:
  | # | element | type | fill |
  |---|---|---|---|
  | 1 | (torso path) | element | token `skin` |
  | 2 | (clothing path) | element | token `clothing` |
  | 3 | (line-art outline path) | element | literal `#000000` |
  | 4 | `head` | component | — |
  | 5 | `expression` | component | — |
  | 6 | `facialHair` | component | — |
  | 7 | `mask` | component | — |
  | 8 | `accessories` | component | — |
- So the real order is **skin → clothing → ink → head → expression → facialHair → mask → accessories**.
  Note the ink outline of the body sits *between* clothing and head, and `accessories` (glasses)
  draws **above** `mask`. The spec's proposed order was correct except it placed `item` last (v2.1)
  and assumed `background` was a layer — see 9.4.
- Each component carries a fixed `transform` (e.g. `head` → `matrix(.99789 0 0 1 6 -58)`,
  `expression` → `translate(351 275)`, `accessories` → `translate(190 243)`); overlays are
  positioned by these, not by the caller.

### 9.3 Component groups — **the real names and counts**
The definition calls the groups (top-level `components` keys): **`head`, `expression`,
`facialHair`, `mask`, `accessories`**. Two spec assumptions need correcting:
- the "face" tab is actually the **`expression`** group;
- the "Glasses" tab is the **`accessories`** group (eyepatch/glasses/sunglasses).
- There is **no `face` key** and **no `top`/`clothing`/`body`/`base` key** — see 9.5.

| Group | Tab (§6) | Variants | `probability` | Notes |
|---|---|---|---|---|
| `head` | Head | **48** | (required) | afro, bangs, bantuKnots, bear, bun, cornrows, dreads, flatTop, gray*, hat{Beanie,Hip}, hijab, long*, medium*, mohawk, noHair1–3, pomp, shaved1–3, short1–5, turban, twists… |
| `expression` | Face | **30** | (required) | angryWithFang, awe, blank, calm, cheeky, concerned, contempt, cute, cyclops, driven, eatingHappy, explaining, eyesClosed, fear, hectic, lovingGrin1/2, monster, old, rage, serious, smile, smileBig, smileLOL, smileTeethGap, solemn, suspicious, tired, veryAngry |
| `facialHair` | (not a tab in §6 — see 9.6) | **16** | `10` | chin, full, full2–4, goatee1/2, moustache1–9 — all ink; `full4`/`moustache9` also use `headContrast` |
| `accessories` | Glasses | **8** | `20` | eyepatch, glasses, glasses2–5, sunglasses, sunglasses2 — all ink; `glasses4` also has a literal `#ffffff` lens |
| `mask` | (decide — see 9.7) | **2** | `5` | medicalMask, respirator |

- **Total selectable part variants: 48 + 30 + 16 + 8 + 2 = 104.**
- `probability` (20 = accessories, 10 = facialHair, 5 = mask, null = always) is the source's
  own "how often to include this overlay" hint. Our editor is **explicit choice**, not random-only,
  so we treat every group as optional-with-a-"none" (−) tile rather than using `probability`;
  `probability` is useful only for `AvatarConfig.random`, where matching the source's spacing
  avoids a face buried under glasses+beard+mask.

### 9.4 Color groups
The definition's `colors` object has exactly **four** groups (values are the *source defaults*;
we supersede them with curated palettes in §6):

| Token | Source values | Role (§6) | Curated count needed |
|---|---|---|---|
| `skin` | 5 (`#694d3d` … `#ffdbb4`) | **Skin tone** | 7 |
| `clothing` | 7 (`#78e185` … `#ffcf77`) | **Outfit** (torso is baked — a *color*, not a part) | 10 |
| `headContrast` | 10 (`#2c1b18` … `#f59797`) | **Hair** (shadows/hair accents; also used by some heads/beards) | 10 |
| `ink` | 1 (`#000000`) | **Outline / line-art** | 4 |

- **`headContrast` is the "hair" slot** — the group name is the *source's*; it tints grey/contrast
  hair strands (head variants `grayShort/grayMedium/grayBun`, `bangs`, `cornrows`, `mohawk*`,
  `noHair3`, `short4`, and beards `full4`/`moustache9`). Exposed in the UI as **Hair**.
- **There is no `background` token and no background layer in the canvas.** The spec's
  "Background" swatch row therefore paints the **container/ring behind the avatar** in our own
  composer (not a source token) — it is a real user choice, just not carried by the art. Keep the
  curated background palette at 8 (§6) and render it as the circle/squircle fill under the layers.
- The token vocabulary actually referenced anywhere in the file is
  **`{skin, clothing, headContrast, ink}`** — nothing else. Any extractor must fail on a token
  outside this set (and on a leftover literal for a *tokenizable* slot).

### 9.5 Torso / clothing handling — **"Top" does NOT exist as a swappable part**
Confirmed by exhaustive key scan: the only groups are the five in 9.3. There is **no `top`,
`clothing`-as-component, `body` or `base` group**. The half-body torso, arms and their creases are
**three fixed paths in the canvas** (skin fill, clothing fill, black outline), with the *clothing
shape being identical for every avatar*. Consequences for §6:
- **Drop the "Top" tab** (as the spec anticipated). "Outfit" is **only a color** (the `clothing`
  token), exposed in the *Colors* tab.
- Do **not** expect a `base/body.svg` asset to extract — the body is part of `canvas`, so the
  extractor should emit the three canvas paths as `base/body.svg` (§3) or keep them inline in the
  composer; **decide in step 2**. Either way it is one file, not a group of variants.
- Because the torso never changes shape, the *Outfit* row is a genuine customization gap the
  source does not fill — a good candidate for v2.1 originals alongside the *Item* art.

### 9.6 `facialHair` has no tab in §6
§6 lists tabs **Head · Face · Glasses · Item · Colors** — there is **no facial-hair tab**, yet the
group is real (16 variants) and `random` will pick it (`probability` 10). Two coherent choices:
1. **Fold it into the *Face* tab** as a labelled sub-section ("Beard / Moustache") — keeps the
   reference tab structure and still exposes all 16. **← recommended (matches §6's "real
   component groups" intent without adding a tab).**
2. Leave it random-only (never user-editable) — simplest, but loses 16 hand-drawn options.
Step 4 should pick (1); if the owner prefers strict tab parity, (2) is the fallback. Recorded here
so step 4 is not a surprise.

### 9.7 `mask` — expose or not? (spec §11 open question)
`mask` is a real group (2 variants, `probability` 5). It draws **above `facialHair`** but
**below `accessories`**, so glasses still sit on top of a mask — visually correct.
**Recommendation: do NOT expose a Mask tab in v2** (keeps the editor to the reference's five tabs
and a mask is an odd thing to pick next to a smiley). Keep the group in the extractor + manifest
(cheap, ~2 files) so `random` *may* use it and v2.1 can surface it without re-extracting.
If the owner wants it user-selectable, it folds into the *Face* tab next to facial hair — same
sub-section pattern as 9.6.

### 9.8 Summary for the next steps
- **Group → file mapping (step 2):** `head/` (48), `expression/` (30 — *rename the spec's `face/`*),
  `facial_hair/` (16), `accessories/` (8), `mask/` (2), `base/body.svg` (single, from `canvas`).
  Plus a synthetic `"none"` tile for `accessories`/`facial_hair`/`mask` (not real files).
- **Tokens:** `@skin`, `@clothing`, `@headContrast`→**`@hair`**, `@ink`; **add `@background`** as a
  *composer-only* token (no source equivalent) for the circle fill. Extractor must reject any other
  token and any unconverted literal in a tokenizable slot (the handful of `#ffffff`/`#ff6c6c` etc.
  in `expression`/`accessories`/`mask` are intentional local accents — **white-list, do not tokenize**).
- **Model impact (step 3):** `AvatarConfig` needs `headId`, `faceId`(=expression), `facialHairId?`,
  `accessoryId?`, `itemId?` (null now), plus colors `background, skin, hair(clothing? see below)…`
  → concretely `AvatarColors{ background, skin, hair, outfit, ink }` (drop the spec's separate
  "clothing" name — map `outfit`→`clothing` token, `hair`→`headContrast` token at compose time).
- **Canvas size for the composed `<svg viewBox>`: `0 0 704 704`.**

## 10. Out of scope / later
- **v2.1 original items** (cat, sprout, headband… drawn by us as SVG with the same token scheme) → fills the *Item* tab.
- Photo avatars, avatar sync (it is one small JSON value, so it syncs for free with settings/profile in v0.4).

## 11. Open questions
- Expose the `mask` group? (decide in the spike)
- Circle-only or user-selectable shape?
