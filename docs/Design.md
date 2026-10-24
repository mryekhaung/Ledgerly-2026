# Design.md — Design System & Screen Specs

**MANDATORY read before any UI work.** Every color, type style, space, radius and string used in
the app comes from a token defined here. No hardcoded values in widgets (`Agent.md` §3.9).

Companion docs: `Platform.md` (adaptive chrome, Liquid Glass / M3 / responsive), `Architecture.md`
§2 (where token files live), `Conventions.md` §1 (naming).

---

## 1. Design principles

| # | Principle | Meaning in practice |
|---|---|---|
| 1 | **Calm by default** | Money apps create anxiety. Surfaces are quiet, numbers are the loudest thing on screen. |
| 2 | **One decision per screen** | Each page answers exactly one question ("what did I spend today?"). |
| 3 | **Number-first** | Amounts get the largest, highest-contrast type. Chrome recedes. |
| 4 | **Native, not skinned** | iOS feels iOS, Android feels Android. We never draw Material on iOS or glass on Android. |
| 5 | **Nothing is a table** | No bordered grids, no zebra rows, no dense admin tables. Lists are airy rows with generous hit targets. |
| 6 | **Motion is feedback, not decoration** | Motion explains where things came from. Duration scales with distance. |

### Anti-patterns — do NOT ship these

- ❌ Dense bordered tables, `DataTable`, zebra striping, visible grid lines
- ❌ Generic M3 `Card` used as the default container for everything
- ❌ Modal dialogs / inline editing for creating or editing an entity
- ❌ More than 2 accent colors on one screen
- ❌ Drop shadows everywhere; heavy `elevation` values
- ❌ Corner radius smaller than 8 on a card or larger than 28 on a button
- ❌ Full-width text stretched past ~560 px
- ❌ Loading spinners on first paint where a skeleton would do
- ❌ Red/green used decoratively — **they mean money direction, nothing else**

---

## 2. Color tokens

Source of truth: `app/theme/app_colors.dart`. Raw palette is private; only semantic tokens
are exported. Widgets never reference the raw palette.

### 2.1 Brand palette (raw — do not use directly in widgets)

| Name | Hex | Role |
|---|---|---|
| `ink900` | `#0F1720` | Neutral darkest |
| `ink700` | `#26313D` | Neutral dark |
| `ink600` | `#2C3844` | Neutral dark-mid — dark hairline |
| `ink500` | `#575F6D` | Neutral mid — light `textSecondary` (6.00:1 on the page) |
| `ink400` | `#67707C` | Neutral mid-light — light `textTertiary` (4.68:1 on the page) |
| `ink350` | `#7E8896` | Neutral light — dark `textTertiary`, light focus ring |
| `ink300` | `#98A2B0` | Neutral light |
| `ink200` | `#DCE1E9` | Neutral lighter — light hairline |
| `ink100` | `#E4E8EE` | Neutral lighter |
| `ink50` | `#F5F7FA` | Neutral lightest — the light **page** (§2.7) |
| `jade600` | `#0E7C66` | **Brand primary** |
| `jade500` | `#12987C` | Brand primary hover/pressed |
| `jade100` | `#A3DBC8` | Brand tint — `brandSubtle` (light) |
| `jadeOnTintLight` | `#0A5A4A` | Text/icon on the light brand tint |
| `coral500` | `#CC3438` | **Expense / negative** — AA on white (5.10:1). See §2.4 |
| `coral100` | `#FDE7E7` | Expense tint |
| `sage500` | `#1C7340` | **Income / positive** — AA on white (5.87:1). See §2.4 |
| `sage100` | `#E3F6E9` | Income tint |
| `amber500` | `#9C6606` | Warning / budget at risk — 4.53:1 on the page |
| `amber100` | `#FCF0D8` | Warning tint |
| `violet500` | `#6B5BD2` | Category accent slot 5 |

### 2.2 Semantic tokens — light

| Token | Value | Use |
|---|---|---|
| `surface` | `#F5F7FA` | **Page** background — grouped-section grey, not white (§2.7) |
| `surfaceRaised` | `#FFFFFF` | Cards/rows — the brightest surface, which is what lifts them |
| `surfaceSubtle` | `#F7F9FB` | Grouped sections, field fills, calendar backdrop |
| `surfaceSunken` | `#F1F4F8` | Keypad tray, inset wells |
| `border` | `#DCE1E9` | Hairlines — **only** separators, never box outlines |
| `borderStrong` | `#7E8896` | Focus rings, selected outlines — 3.35:1, clears the 3:1 UI-mark floor |
| `textPrimary` | `#0F1720` | Amounts, titles |
| `textSecondary` | `#575F6D` | Labels, metadata — 6.00:1 on the page |
| `textTertiary` | `#67707C` | Placeholders, disabled, weekend headers — 4.68:1 on the page |
| `textOnBrand` | `#FFFFFF` | Text on `brandPrimary` |
| `brandPrimary` | `#0E7C66` | FAB, selected tab, primary button, **selected fill** |
| `brandSubtle` | `#A3DBC8` | Tinted fill: selected chip background, nav indicator, today ring's tint |
| `onBrandSubtle` | `#0A5A4A` | Text/icon **on** `brandSubtle` — 5.25:1 |
| `selectedFill` | `#0E7C66` | **Solid** selected state (day cell, chosen option) — see §2.6 |
| `onSelectedFill` | `#FFFFFF` | Text/icon on `selectedFill` |
| `moneyOut` | `#CC3438` | Expense amounts — 4.75:1 on the page |
| `moneyOutSubtle` | `#FDE7E7` | Expense capsule fill |
| `moneyIn` | `#1C7340` | Income amounts — 5.47:1 on the page |
| `moneyInSubtle` | `#E3F6E9` | Income capsule fill |
| `warning` | `#9C6606` | Budget near limit — 4.53:1 on the page |
| `warningSubtle` | `#FCF0D8` | Warning capsule fill |
| `overlay` | `#0F1720` @ 32% | Scrims |

> **Ratios are against the `surface` the token actually sits on.** §2.7 moved the
> light page from `#FFFFFF` to `#F5F7FA`, so every light-mode ratio above shifted
> down and three tokens moved with it to hold AA: `textSecondary`, `textTertiary`
> and `moneyIn`. The old table quoted ratios against white, which stopped being
> the page background — a doc that no longer described the app.

> **`textTertiary` is not decorative.** It used to be `#98A2B0` at **2.58:1** on
> white — the weekday header was an unreadable label rather than a de-emphasised
> one (`docs/Roadmap.md` §K.1-4). It is reserved for placeholder/disabled copy
> and the weekend columns per §6.2; never for a live label.

### 2.3 Semantic tokens — dark

| Token | Value | Notes |
|---|---|---|
| `surface` | `#0E1218` | Page background |
| `surfaceRaised` | `#182029` | Cards/rows |
| `surfaceSubtle` | `#141A21` | Grouped sections |
| `surfaceSunken` | `#0A0E13` | Keypad tray |
| `border` | `#2C3844` | Hairlines |
| `borderStrong` | `#98A2B0` | Focus |
| `textPrimary` | `#F5F7FA` | |
| `textSecondary` | `#98A2B0` | |
| `textTertiary` | `#7E8896` | |
| `brandPrimary` | `#22A287` | **Lightened** — `jade600` fails 4.5:1 on dark |
| `brandSubtle` | `#1A4C40` | |
| `onBrandSubtle` | `#7FD8C0` | Text/icon on `brandSubtle` |
| `selectedFill` | `#22A287` | Solid selected state — see §2.6 |
| `onSelectedFill` | `#06231D` | |
| `moneyOut` | `#E85D66` | Lightened for dark contrast |
| `moneyOutSubtle` | `#33191B` | |
| `moneyIn` | `#3FAD64` | |
| `moneyInSubtle` | `#122C1C` | |
| `warning` | `#E0A63C` | |
| `warningSubtle` | `#33280F` | |
| `overlay` | `#000000` @ 55% | |

> **The dark accents are lightened only as far as AA requires.** They used to run
> far brighter than their light twins — `moneyIn` was **+63 %** and `brandPrimary`
> **+48 %** in contrast — which is the measurable form of "the two modes look like
> different apps" (`docs/Roadmap.md` §K.2). Every role now sits within **30 %** of
> its light counterpart, asserted in `test/app/theme/design_tokens_test.dart`.

### 2.6 Selection tokens (a state is not a tint)

Before these existed the *only* "selected" token was `brandSubtle`, a wash that
measured **1.20:1 on white and 1.29:1 on dark** — below the 3:1 WCAG floor for a
non-text UI mark. Every selected control in the app was therefore effectively
invisible, and in dark mode it read as a near-black square (`docs/Roadmap.md`
§K.1-2). Two pairs replace it, and the distinction is the point:

| Pair | Fill | Foreground | Where |
|---|---|---|---|
| `selectedFill` / `onSelectedFill` | **solid** `brandPrimary` | `textOnBrand` | Day cell, chosen option, month-picker tile, day-grid chip |
| `brandSubtle` / `onBrandSubtle` | **tinted** | `onBrandSubtle` | Segmented tabs, nav indicator, filter chips, swipe affordances |

Rules:

1. **A fill must clear 3:1 against the surface it sits on.** A tint (`brandSubtle`)
   is exempt only where the state is *also* carried by something else — a filled
   icon, a weight change, a border.
2. **A tint carries its own on-colour.** Painting `brandPrimary` on `brandSubtle`
   measured 3.90:1 light / 3.43:1 dark, both below AA — so `onBrandSubtle` exists
   and `brandPrimary` must never be painted on `brandSubtle`.
3. **Light and dark are the same design.** Same role, same contrast, within 30 %.

### 2.7 Surface ramp (a card has to be able to lift)

§K audited every *colour role* and left the surface ramp unexamined, on the
assumption that four named surfaces were four different surfaces. In light mode
they were not:

| Role | Before §L | After §L |
|---|---|---|
| `surfaceSunken` | `#EDF0F5` | `#F1F4F8` |
| `surface` | `#FFFFFF` | `#F5F7FA` |
| `surfaceSubtle` | `#F5F7FA` | `#F7F9FB` |
| `surfaceRaised` | `#FFFFFF` | `#FFFFFF` |

`surface` and `surfaceRaised` were **the same colour**, and `surfaceSubtle` was
*darker* than the "raised" surface §2.2 defines as the one that lifts off it. A
card therefore sat at **1.00:1** against the page behind it. Measured, not
argued: in `test/features/accounts/presentation/goldens/accounts_light.png`
**83.6 %** of the screen was one identical `#FFFFFF` — page and card alike —
while the dark twin separated the same two roles into 61.4 % `#0E1218` and
21.7 % `#182029`. No test could see it, because no test compared two surfaces.

White is the brightest value light mode has, so the only way to make a card
*lift* is to lower the page. Every hue (jade / coral / sage) is untouched; this
moves neutrals only. After §L the same screen reads **61.1 % page / 22.6 %
card** — structurally the same picture dark mode was already drawing.

**How far down the page goes is solved, not chosen.** The binding constraints are
AA floors on the surfaces the ink actually lands on:

| Foreground | Surface it lands on | Floor it imposes |
|---|---|---|
| `warning` | the page | page luminance ≥ 0.9213 |
| `textTertiary` | the keypad tray (`surfaceSunken`) | ≥ 0.8917 |

Light mode has very little headroom here — that is why the ramp is tight rather
than dramatic, and why `warning` is asserted only on `surface` and
`surfaceRaised` (it is never painted on a well or a band).

**The two ramps are not the same width, and should not be.** Light spans L\* 96.1
→ 100.0 (3.9 pts); dark spans 3.8 → 11.9 (8.1 pts). Dark's steps are twice as
wide because dark mode gets **no shadow** — `AppElevation.raised` is empty there
and the surface ramp does all the work (§4.3). Light keeps its `raised` shadow,
so a tight ramp plus a shadow separates as well as dark's wide ramp alone. What
must match is not the width but the *relationship*: the card lift, which is
1.07:1 light and 1.14:1 dark — 6 % apart.

**Rules**

1. **The ramp is strictly ascending in both modes** — `surfaceSunken` < `surface`
   < `surfaceSubtle` < `surfaceRaised`. Asserted in
   `test/app/theme/design_tokens_test.dart`.
2. **`surfaceRaised` must clear 1.05:1 against `surface` in both modes.** A card
   that cannot be told from the page is not a card.
3. **The two modes must lift a card by the same amount** (within 30 %) — the §2.6.3
   parity rule, extended from colour roles to surface relationships. Light
   separates its card by 1.07:1, dark by 1.14:1 — 6 % apart. The ramp *width*
   is deliberately not asserted: it is 3.9 L\* in light and 8.1 in dark, because
   dark has no shadow to lean on.
4. **Never "brighten the page for airiness."** White is the ceiling; the page is
   already at the darkest value that keeps `warning` legible on it.
5. **The day-capsule ramp is coupled to this.** Lowering the page brought the
   light `*Subtle` tints closer to it, so capsule step 1 fell to 2.48:1 and had
   to be re-raised from 60 % to 66 % (§6.2).

### 2.4 Money color rule (do not deviate)

> **Out = expense = `moneyOut` (coral/red family). In = income = `moneyIn` (sage/green family).**

This is a **universal** convention for this app, chosen for the primary market (Myanmar/Japan) and
because it matches the accounting convention the product is teaching. It is **not** the US
stock-market convention and is deliberately not configurable in v0.1.

- Never use `moneyIn`/`moneyOut` for anything that is not an amount.
- Never signal "bad" with `moneyOut` — an expense is neutral information, not an error.
- Errors use `warning` or the platform error color, never `moneyOut`.

#### Contrast requirement (tested, not aspirational)

Amounts are the most important content on screen, so both money colors **must reach WCAG AA
(4.5:1) against every surface they can sit on** — `surface`, `surfaceRaised` **and**
`surfaceSubtle`. This is asserted in `test/app/theme/design_tokens_test.dart`.

| Pair | Ratio | Verdict |
|---|---|---|
| `moneyOut` `#CC3438` on `#FFFFFF` | 5.10 | ✅ AA |
| `moneyOut` `#CC3438` on `#F5F7FA` | 4.75 | ✅ AA |
| `moneyIn` `#1C7340` on `#FFFFFF` | 5.87 | ✅ AA |
| `moneyIn` `#1C7340` on the `#F5F7FA` page | 5.47 | ✅ AA |
| dark `moneyOut` `#E85D66` on `#0E1218` | 5.53 | ✅ AA |
| dark `moneyIn` `#3FAD64` on `#0E1218` | 6.59 | ✅ AA |

The dark values were **lowered** from `#FF6B6F` (6.78) and `#4CC777` (8.71) —
over-brightening the accents is what made the two modes read as different apps
(§K.2). They are now within 8 % and 23 % of their light twins instead of 33 % and 63 %.

Light `moneyIn` was **darkened** from `#1E7A45` (5.35:1 on white) in §L: on the new
`#F5F7FA` page that measured only 4.99:1, which put it 32 % away from dark's 6.59:1
and broke the §2.6.3 parity rule. `#1C7340` is 5.47:1 there — 20 % away, and still
AA on all four light surfaces (§2.7).

> **This table only ever covered the money colours.** Every other role — the text
> ramp, `brandPrimary`, `warning`, the focus ring, all fills, the selected state,
> the FAB and the capsule ramp — was unmeasured, which is exactly why §K found an
> invisible selected day and an invisible capsule shipping green. §2.6 and the
> `§K` group in `design_tokens_test.dart` close that gap. §L then found the one
> thing left: the surfaces themselves were never compared to each other.

> Historical note: the first draft used `#E5484D` / `#2E9E5B`, which only reached 3.91 and 3.41 on
> white — **too low for text**. They were kept as-is nowhere: the palette above is the corrected
> pair. Do not "brighten" these for aesthetics without re-running the contrast test.


### 2.5 Platform-native surfaces

The app does not simulate Liquid Glass with blur, tint, or translucent borders.
On supported iOS versions, native navigation chrome is provided by
`adaptive_platform_ui`; older iOS uses opaque Cupertino surfaces. Content cards
remain opaque `surfaceRaised` surfaces on every platform.

---

## 3. Typography

Fonts (per `Platform.md` §3): **Inter** for amounts and Latin UI, **Noto Sans Myanmar** (my),
**Noto Sans JP** (ja), system fallback elsewhere. Bundled for web; system-preferred on mobile.

Source of truth: `app/theme/app_typography.dart`.

| Token | Size / Line / Weight | Family | Use |
|---|---|---|---|
| `displayAmount` | 40 / 44 / w600 | Inter tabular | Hero amount (summary card, keypad) |
| `amountLarge` | 28 / 32 / w600 | Inter tabular | Selected-day total |
| `amount` | 17 / 22 / w600 | Inter tabular | Row amounts |
| `titleLarge` | 22 / 28 / w600 | Inter | Screen title (large) |
| `title` | 17 / 22 / w600 | Inter | Card titles, nav labels |
| `body` | 15 / 21 / w400 | Inter | Body copy |
| `label` | 13 / 18 / w500 | Inter | Field labels, chips |
| `caption` | 11 / 15 / w500 | Inter | Day numbers, timestamps |
| `overline` | 11 / 14 / w600 + tracking 0.6 | Inter | Section headers, ALL CAPS |

**Rules**
- **All amounts use tabular figures** (`fontFeatures: [FontFeature.tabularFigures()]`) so columns
  align and digits don't jitter during animation. Non-negotiable.
- Numbers use `.numericAlt` only for currency glyphs, never for digits.
- Never go below `caption` (11). Never use `w300` or lighter — Burmese and Japanese thin weights
  render poorly at small sizes.
- Font scaling: layouts must survive `textScaleFactor` 2.0 without overflow (see §8).
- Line height for `my`/`ja` gets `+0.15` multiplier automatically via the theme's
  `TextTheme` per-locale adjustment.

---

## 4. Spacing, radius, elevation, motion

### 4.1 Spacing (`app/theme/app_spacing.dart`)

Base unit **4**. Only these values exist:

| Token | px |
|---|---|
| `xxs` | 2 |
| `xs` | 4 |
| `sm` | 8 |
| `md` | 12 |
| `lg` | 16 |
| `xl` | 24 |
| `xxl` | 32 |
| `xxxl` | 48 |

- Screen horizontal padding: `lg` (16) compact, `xl` (24) medium+.
- Gap between unrelated blocks: `xl`. Between related items: `sm`.
- Between list rows: **0** — rows use internal padding + a hairline, not margins.

### 4.2 Radius (`app/theme/app_radius.dart`)

| Token | px | Use |
|---|---|---|
| `sm` | 8 | Chips, capsules, small badges |
| `md` | 12 | Inputs, list-group containers |
| `lg` | 20 | Cards, sheets |
| `xl` | 28 | FAB, large surfaces |
| `full` | 999 | Pills, avatars, circular buttons |

### 4.3 Elevation

We prefer **tint + hairline** over shadow. Only three levels:

| Token | Light | Dark | Use |
|---|---|---|---|
| `flat` | none, `border` hairline | none, `border` hairline | Rows, grouped lists |
| `raised` | `0 1 2 rgba(15,23,32,.06)` | none, lighter surface | Cards |
| `floating` | `0 8 24 rgba(15,23,32,.12)` | `0 8 24 rgba(0,0,0,.4)` | FAB, sheets |

### 4.4 Motion (`app/theme/app_motion.dart`)

| Token | Duration | Curve |
|---|---|---|
| `micro` | 100 ms | `easeOut` |
| `short` | 180 ms | `easeOutCubic` |
| `medium` | 260 ms | `easeInOutCubic` |
| `long` | 400 ms | `easeInOutCubic` |
| `emphasized` | 500 ms | `easeOutQuint` |

- Respect `MediaQuery.disableAnimations` → collapse every duration to `Duration.zero`.
- Camera-ish moves (page push, sheet) use the platform transition from `Platform.md` §3.
- Never animate `width`/`height` in a scrolling list.

---

## 5. Component specs

Every component lives in `core/widgets/<name>/` with **one public widget** and per-platform
implementations (`_ios.dart` / `_material.dart`) per `Platform.md` §2. Pages import the public
widget only.

### 5.1 `AppScaffold`

The shared page frame. Every page uses it — no raw `Scaffold` in features.

- Owns: safe areas, top bar (adaptive), bottom nav inset, background (`surface`), and the content
  column. The shell owns the native tab bar and its content inset.
- Full-viewport pages that do not give their own scrollables bottom clearance opt into
  `reserveNativeTabBarSpace` to keep content above the iOS 26 overlay.
- All floating actions use `AppFloatingActionButton` with the shared brand colors; scaffold
  placement stays platform-adaptive.
- The **content column** is capped at 1200 px by default, or at the page's `contentMaxWidth` when it
  declares one (a form or prose list: 560). The frame caps *and centres* the column and derives the
  top bar title's inset from it, so the title's left edge lands on the content's rather than at a
  fixed 16 px. A page that capped its own body could not do this — that was the 55 px title/content
  offset (`docs/Roadmap.md` §G.8 R2 / §J).
- Props: `title`, `leading`, `actions`, `bottomNav`, `floatingAction`, `body`, `isScrollable`,
  `contentMaxWidth`, `contentInset`.
- **Top bar**: iOS Cupertino navigation bar; Android M3 Large Top App Bar.

### 5.2 `AppCard`

- Container: `surfaceRaised`, `radius.lg`, padding `lg`, elevation `raised`, **no border**.
- Optional `onTap` → adds press state (`micro` fade to 96% opacity + light haptic), never a ripple
  on iOS.
- **Never nest an `AppCard` inside another `AppCard`.**

### 5.3 `CategoryGem`

The category glyph, drawn **not** with an icon font but as a solid shape with the category color.

- Sizes: `sm` 20, `md` 28, `lg` 40, `xl` 56.
- Shape: `radius.full` circle by default; `squircle` variant for expanded layouts.
- Renders: color fill (`brandSubtle`-tinted if the category has no color), glyph icon at 55% of
  size, optional `+N` overflow badge for merged categories.
- **Never** place a `CategoryGem` on a colored background of the same hue.

### 5.4 `AmountText`

Renders a `Money`. The only widget allowed to format money.

- Props: `money`, `style` (from §3 amount tokens), `showSign`, `signed`, `strikethrough`,
  `animateOnChange`.
- `signed: true` → prepends `−` for expense / `+` for income **and** applies `moneyOut`/`moneyIn`.
  `signed: false` → always `textPrimary` (use for totals where sign is implied by context).
- Uses `MoneyFormatter` (`core/money`) with the active locale and currency.
- Inserts hair spaces around the currency symbol — never a plain space.
- `animateOnChange` uses an implicit tween over `short`; must not reflow the layout.

### 5.5 `SegmentedTabs`

- iOS 26+: native segmented control. Earlier iOS uses the Cupertino sliding
  control. Android/Web use the M3-style pill track.
- Pill shape (`radius.full`), height 32, label `label` token.
- The native control uses `brandPrimary` + `textOnBrand` for its selected state.
  The tinted Material track uses `brandSubtle` + `onBrandSubtle`; unselected
  labels use `textSecondary`.
  The on-colour matters — `brandPrimary` on `brandSubtle` fails AA (§2.6).
- Sliding indicator animates with `short`. Max **3** segments; more becomes a scrollable chip row.

### 5.6 `ListRow`

The atomic list unit. Replaces any table.

- Height: **64** (single line) / **76** (two line). Never shorter than 56.
- Layout: `[leading 40] [gap lg] [title/ subtitle flex] [gap md] [trailing amount]`
- Padding: horizontal `lg`, vertical `md`.
- Separator: 1 px `border`, **inset from the left by `lg + 40 + lg`** (aligns with text, not edge).
- Trailing amount uses `AmountText` with the `amount` token, right-aligned, tabular.
- Press state: full-bleed `surfaceSunken` wash over `micro`, plus haptic light.

### 5.7 Buttons

| Variant | Light | Notes |
|---|---|---|
| `primary` | `brandPrimary` fill, `textOnBrand`, height 52, `radius.full` | One per screen max |
| `secondary` | transparent, `borderStrong` hairline, `textPrimary` | Paired with primary |
| `ghost` | text only, `brandPrimary` | Inline actions |
| `destructive` | `moneyOut` text, no fill | Delete. Requires confirm. |
| `icon` | 44×44 min hit target, `radius.full` | Toolbars |

- Floating actions use `brandPrimary` + `textOnBrand`; `AppFloatingActionButton` supplies the
  platform-specific appearance and tooltip/semantics.
- Minimum hit target **44×44** everywhere (iOS HIG). Android may use 48 for FAB.
- No button is ever disabled without an adjacent explanation. Prefer enabled + validation on press.

### 5.8 Fields

- Container: `surfaceSubtle`, `radius.md`, height 56, padding `lg`.
- Label inside at top (`label`, `textSecondary`), value below (`body`, `textPrimary`) — this is the
  filled style; **no floating-label Material outline fields**, no `OutlineInputBorder` boxes.
- Focus: 2 px `borderStrong` ring, no glow.
- Error: text + subtle `warningSubtle` fill; message below in `caption`.
- Keyboard: numeric keypad is a **dedicated page/tray**, never the OS keyboard, for amount entry.

### 5.9 `EmptyState`

- Centered, max width 320, vertically centered in available space.
- Parts: 96 px illustration (line-art, `brandSubtle` + `textTertiary`), `title`, `body`
  (`textSecondary`, centered, max 2 lines), one action button.
- Never an empty screen with just "No data".

### 5.10 Native iOS tab bar / `M3NavigationBar` (Android)

- iOS 26+: `adaptive_platform_ui`'s native `UITabBar` and system Liquid Glass; older iOS: opaque
  `CupertinoTabBar`. No Flutter blur/tint imitation.
- Android: M3 `NavigationBar`, opaque `surfaceRaised`, hairline top border.
- 3–5 destinations. Active icon filled, inactive outlined; label always visible.

### 5.11 State widgets

| State | Treatment |
|---|---|
| **Loading (first paint)** | Skeleton matching final layout (`surfaceSubtle` shimmer), never a centered spinner |
| **Loading (refresh)** | Subtle inline indicator in the top bar only; content stays |
| **Error** | Inline banner inside the content area: `warningSubtle`, icon, plain-language message, `Retry` ghost button. Never a full-screen red page. |
| **Empty** | `EmptyState` (§5.9) |

---

## 6. Calendar screen spec

Roadmap Phase 1. Compact = single column; medium+ = two panes (`Platform.md` §5).

### 6.1 Structure — compact

```
┌─────────────────────────────────────────────┐
│  ‹   October 2026   ›          [today]      │  period switcher, sticky (§6.6: "Oct 10 – Nov 9" in pay-cycle mode)
├─────────────────────────────────────────────┤
│  M   T   W   T   F   S   S                  │  weekday header — `overline`
│  29  30  1   2   3   4   5                  │
│  6   7   8  (9)  10  11  12                 │  (9) = selected
│  ▁   ▂   ▃   ▅  ▁                           │  Day Capsule intensity
├─────────────────────────────────────────────┤
│  Spent today            −12,500 Ks          │  summary card (AppCard)
│  ────────────────────────────────           │
│  Income  +45,000   Expense  −57,500         │
├─────────────────────────────────────────────┤
│  ● Groceries      −3,200 Ks                 │  day list (ListRow ×n)
│  ● Transport      −800 Ks                   │
│  ● Salary         +45,000 Ks                │
└─────────────────────────────────────────────┘
                                    ( + )  ← FAB / glass
```

### 6.2 Day Capsule grid

The signature component. A **period** grid (a calendar month by default; the pay-cycle days when `monthStartDay` ≠ 1 — §6.6) where each day cell carries a **capsule** whose fill encodes
that day's net spend magnitude.

Every number below is Material 3's own measurement for a mobile date picker, not a
preference (`material.io/design/components/pickers.html`): **44 dp** cell, **36 × 36 dp**
selected indicator, **1 dp** today ring. §M brought the code back to them (§M.1–3) after it
had drifted to 48 / 40 × 40 / 1.5.

- Cell: **44 × 44**. Grid is `7` columns, always. The whole cell is the touch target; the
  36 px indicator is what is *drawn* inside it, not what is tapped.
- Selected indicator: **36 × 36** (`_selectedIndicatorSize`). 40 px inside a 44 px cell
  left 2 px of air and read heavy.
- Today: a **1 dp** ring at `radius.full`, drawn over the selected fill so the two can
  coexist. M3 specifies today as an outline with no fill precisely so it stays distinct
  from the filled selected state; 1.5 px read as a second selection.
- Capsule: **3 px** tall at `radius.full`, **36 %** of the cell wide (`capsuleWidthFraction`).
  The width is a *fraction*, not a pixel count, so the capsule keeps its proportion when the
  grid stretches on tablet and desktop. It was 60 % × 4 px, which the owner read as a
  divider rather than a data mark — "divider width ကို နဲနဲလျှော့လိုက်ရင် ပိုလှသာမယ်ထင်တယ်"
  (§M.4). A narrower bar is also the more honest encoding: the capsule's job is to say
  *this day had activity and roughly how much*, and at 60 % it competed with the day
  number instead of annotating it. `borderFull` rather than `borderSm`: a fully rounded
  3 px dash reads as a deliberate mark, where an 8 px radius on a 3 px bar is
  geometrically a rectangle with clipped corners.
- **Intensity** maps to `intensity = clamp(net / p95MonthNet, 0, 1)` where `p95PeriodNet` is the
  95th-percentile absolute net of the visible period. Quantize into **5 steps** (`0, .25, .5, .75, 1`)
  so the grid reads as texture, not noise.
  - **Step 0 is the palest capsule, not no capsule.** A day with *no* activity has a null
    intensity and draws nothing; a step-0 day draws the faintest bar. The field's doc
    comment used to claim "0 = no capsule" while `_Capsule` rendered for every non-null
    intensity — the comment described the intent the ramp was built to avoid (§M.9).
  - Steps 0–4: a **lerp from 66 % toward the full colour** — `moneyOutSubtle` /
    `moneyInSubtle` → `moneyOut` / `moneyIn` — so every step is visible. The
    `*Subtle` tints measure 1.10–1.25:1 on their surface, so starting the ramp
    *at* them made step 1 a bar nobody could see ("the black bar", §K.1-3).
    Step 0 sits *below* the start (it is a fifth of the ramp, not a fourth) and is
    **clamped at `capsuleRampFloor` = 0.60**, because the unclamped extrapolation
    measured 2.46:1 / 2.38:1 in light — under the floor every other step clears
    (§M.10). The five steps land at:

    | | step 0 | step 1 | step 2 | step 3 | step 4 |
    |---|---|---|---|---|---|
    | light expense | 2.66 | 2.93 | 3.48 | 4.10 | 4.75 |
    | light income | 2.61 | 2.88 | 3.54 | 4.39 | 5.47 |
    | dark expense | 3.01 | 3.30 | 3.97 | 4.68 | 5.53 |
    | dark income | 3.52 | 3.91 | 4.71 | 5.57 | 6.59 |

    Asserted in `design_tokens_test.dart`
    (`every_capsule_step_is_visible_and_ordered`, which imports the widget's own
    `capsuleRampStart` / `capsuleRampFloor` rather than copying them) and, on the
    rendered widget, in `calendar_page_test.dart`'s Day Capsule group. **The start was
    raised from 60 % to 66 % in §L** — lowering the page (§2.7) brought the light
    tints closer to it, dropping step 1 to 2.48:1, back under the floor.
  - Inside a **selected** cell the capsule is repainted `onSelectedFill`. It used to stay
    `moneyOut`, so a selected day drew a saturated red bar across a saturated teal disc —
    two focal colours inside one 36 px circle, the clash visible on day 16 of the owner's
    light-mode screenshot (§M.5). The selected day is the single focal state on the screen
    (§1.2); everything inside it reads as one object. The capsule keeps its *length*, so
    the day's magnitude is still legible, and gives up only its hue.
- **Selected**: a **solid** `selectedFill` circle (`radius.full`) behind the whole
  cell, with the day number in `onSelectedFill` w600 — the Google Calendar /
  Apple Calendar convention. A tint is not a state (§2.6). Selection and today
  can coexist: on a selected cell the today ring switches to `onSelectedFill`,
  because a `brandPrimary` ring on a `brandPrimary` fill would vanish.
- **Outside the visible period** (padding days that complete the first/last week): a blank
  `SizedBox` at `AppRowHeight.calendarCell` — no day number, no capsule, not tappable.
  This doc used to promise `textTertiary` digits and a 40 %-alpha capsule that navigate to
  the neighbouring period; the code has never drawn either, and a golden is the only thing
  that would have caught it (§M.13). The height is the *same constant* the real cells use,
  so the two cannot drift apart (§M.1).
- Weekend column headers get `textTertiary`; no other special-casing. The header is
  `AppTypography.overline` (§6.1's own mock specified it; the code had drifted to
  `labelSmall` — §M.7).
- Densities: compact shows capsule + number. Expanded shows capsule + number + tiny amount
  (`caption`, truncated) for cells wide enough (≥ 64 px).

**Period switcher**: Calendar, Insights, and Budgets use the same raised selector. The
Calendar label opens a full-screen month picker outside the navigation shell, so the primary
bottom bar is not left visible on a secondary screen. The picker uses the shared selector to
browse years and a localized 3 × 4 month grid with concise month names; `Today` is an adaptive
toolbar action.
Horizontal swipe on the grid changes month; the swipe must not fight the day-list scroll
(grid owns horizontal, list owns vertical).

### 6.3 Summary card

An `AppCard` directly under the grid.

- Eyebrow: `overline`, `textSecondary` — "SPENT TODAY" / localized.
- Hero: `displayAmount` (40 px), **unsigned and in `moneyOut`** — the day's *spend*, so the
  figure can never contradict the eyebrow. It used to be the signed net, which
  rendered a salary as a green `+¥200,000` under the words "SPENT TODAY"
  (§K.1-1). Animated on day change (`short`).
  The hero is wrapped in `FittedBox(fit: BoxFit.scaleDown)` because
  `AmountText` sets `overflow: TextOverflow.ellipsis`: a hero that is too wide
  would **drop digits** rather than overflow, and no layout test can catch that
  — the `Text` widget keeps its `data` intact while the *render* clips. Scaling
  down renders a smaller number; ellipsizing renders a **wrong** one. This is
  what let the hero finally adopt the size §3 always specified; it had been
  pinned to `amountLarge` (28 px) because a fixed 40 px overflowed a long
  amount at 2× text scale (§L.6).
- Divider: full-bleed hairline `border`.
- Footer: two columns — `Income +45,000` (`moneyIn`) and `Expense −57,500` (`moneyOut`), both
  `amountLarge`. Equal flex, left-aligned, labels in `label`/`textSecondary`.
- Compact: two columns side by side. Expanded (≥ medium): same, with a third "Net" column.
- Tapping the card opens the Insights page for that period (Phase 2 — until then, no `onTap`).

### 6.4 Day list

- Section header: the full date, `label`/`textSecondary`, sticky, on `surfaceSubtle`.
- Rows: `ListRow` with `CategoryGem` leading, category name + note, `AmountText` trailing.
- Outcome ordering: expenses and income interleaved by time, newest first. No grouping by sign.
- Swipe left → delete (confirm), swipe right → edit. iOS also gets a long-press context menu.
- **Empty**: `EmptyState` — "Nothing on this day", body "Tap + to add your first transaction."
- **Loading**: 4 skeleton `ListRow`s.
- **Error**: inline banner + `Retry`.
- Pagination: 50 rows, infinite scroll (`Conventions.md` §3).

### 6.5 Two-pane layout (medium / expanded / large)

| Width | Layout |
|---|---|
| compact `< 600` | grid → summary → day list, all in one scrolling column |
| medium `600–839` | **left 360**: grid + summary (no day list) · **right**: selected-day list. Nav rail. |
| expanded `840–1199` | left 400: grid + summary · right: day list + month stats strip. Sidebar nav. |
| large `≥ 1200` | as expanded, content capped 1200, extra gutters, day list gets a third column for a mini donut |

In two-pane mode the day list is the detail pane and must show a `EmptyState` ("Select a day")
before any day is picked only on first launch; afterwards the last-selected day persists.

### 6.6 Pay-cycle period ("month starts on the 10th")

A "month" is a **budget period** (`DataModel.md` §8). Default `monthStartDay = 1` renders exactly
as a calendar month; anything else switches the screen to pay-cycle mode.

- **Header title:** calendar mode → `October 2026`. Pay-cycle mode → `Oct 10 – Nov 9` (`title`
  weight, short month names from `intl`, never hardcoded) with a `caption`/`textSecondary`
  line below: "Pay cycle" (localized). Tapping opens the period picker (a list of recent periods
  in that same format, current one marked `brandSubtle`).
- **Grid:** shows only the period's days, from the start day to the end day, padded with dimmed
  outside days to complete the first/last week (§6.2). Because a period spans two calendar
  months, **the 1st of each calendar month carries a tiny month label** (`overline`, e.g. `Nov`)
  above the day number, so the boundary is obvious without a divider line.
- **Capsule intensity** uses the period's own `p95PeriodNet` (§6.2) — never the calendar month's.
- **Summary card & stats strip:** all totals are for the period; eyebrow labels say "THIS PERIOD"
  (localized) in pay-cycle mode and "THIS MONTH" in calendar mode.
- **Settings → "Month starts on":** a dedicated picker **page** (not a dialog), consistent with
  the other settings rows. Day chips/wheel 1–28; a **live preview card** under it:
  "Current period: Oct 10 – Nov 9" and "Previous: Sep 10 – Oct 9". Changing it recomputes every
  screen immediately; show a one-line `caption`: "Your transactions are not changed."
- **First-run question** (with onboarding, Phase 2): "When does your month start? (e.g. pay day)",
  default 1, skippable.
- The **date picker in the transaction form stays a calendar** — picking a date is not a period
  concern.
- **Widths:** no layout change; only the title string gets longer — it must ellipsize
  gracefully at 360 px and text scale 2.0 (add to the §8 checklist run).

---

## 7. Localization in UI

- Every visible string is an ARB key (`l10n/`), en / my / ja. No literals in widgets.
- **Burmese (my)**: taller line boxes, no italics ever, and it must never be truncated mid-cluster
  — prefer wrapping to ellipsis. Test at 2.0 text scale.
- **Japanese (ja)**: no spaces between words; don't build sentences from concatenated fragments.
- Month and weekday names come from `intl` for the active locale — never a hardcoded English array.
- Number grouping and currency placement follow the locale; `MoneyFormatter` owns this.
- RTL is not supported in v0.1 but nothing may hardcode `TextAlign.left`.

---

## 8. Verification checklist (Definition of Done for UI)

- [ ] Only tokens — zero literal colors, sizes, or radii
- [ ] Light **and** dark checked side by side
- [ ] iOS and Android both feel native; no Material on iOS, no glass on Android
- [ ] Verified at **360 / 768 / 1440 px**, portrait and landscape
- [ ] Text scale **1.0 and 2.0** — zero overflow, zero clipped glyphs
- [ ] Empty, loading, and error states all implemented
- [ ] Every string localized (en / my / ja); no overflow with long Burmese/Japanese
- [ ] All controllers/timers/subscriptions disposed (`Conventions.md` §3)
- [ ] Amounts use tabular figures and `AmountText` only
- [ ] Money colors follow §2.4 exactly
- [ ] Every text token ≥4.5:1 and every accent ≥4.5:1 on **all three** surfaces
      (`surface`, `surfaceRaised`, `surfaceSubtle`)
- [ ] Every selected fill ≥3:1; **no `brandPrimary` painted on `brandSubtle`** (§2.6.2)
- [ ] Light and dark agree within **30 %** on every text and accent role (§2.6.3)
- [ ] The surface ramp ascends in **both** modes and `surfaceRaised` clears
      **1.05:1** against `surface` — a card must be tellable from its page (§2.7)
- [ ] The two modes lift a card by the same amount, within 30 % (§2.7.3)
- [ ] `RepaintBoundary` around the calendar grid and any chart
- [ ] Golden tests per platform × light/dark for design-system components
- [ ] Screenshot reviewed in `--profile` on a low-end device, no jank while scrolling the grid

The contrast and surface bullets are **asserted, not reviewed** — they are the
tests `test/app/theme/design_tokens_test.dart` runs. They exist because the §K
audit found every one of them shipping green: the old suite checked only
`textPrimary`, `moneyOut`, `moneyIn` and dark `brandPrimary`, each on `surface`
alone. §L then showed the remaining blind spot — the suite compared every token
to a surface, but never compared two surfaces to each other, which is how a card
and its page came to be the same colour.
