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
| `ink500` | `#5A6675` | Neutral mid |
| `ink300` | `#98A2B0` | Neutral light |
| `ink100` | `#E4E8EE` | Neutral lighter |
| `ink50` | `#F5F7FA` | Neutral lightest |
| `jade600` | `#0E7C66` | **Brand primary** |
| `jade500` | `#12987C` | Brand primary hover/pressed |
| `jade100` | `#D6F0E8` | Brand tint |
| `coral500` | `#CC3438` | **Expense / negative** — AA on white (5.1:1). See §2.4 |
| `coral100` | `#FDE7E7` | Expense tint |
| `sage500` | `#1E7A45` | **Income / positive** — AA on white (5.35:1). See §2.4 |
| `sage100` | `#E3F6E9` | Income tint |
| `amber500` | `#C98A0B` | Warning / budget at risk |
| `amber100` | `#FCF0D8` | Warning tint |
| `violet500` | `#6B5BD2` | Category accent slot 5 |

### 2.2 Semantic tokens — light

| Token | Value | Use |
|---|---|---|
| `surface` | `#FFFFFF` | Page background |
| `surfaceRaised` | `#FFFFFF` | Cards/rows that need to lift off `surfaceSubtle` |
| `surfaceSubtle` | `#F5F7FA` | Grouped sections, calendar backdrop |
| `surfaceSunken` | `#EDF0F5` | Keypad tray, inset wells |
| `border` | `#E4E8EE` | Hairlines — **only** separators, never box outlines |
| `borderStrong` | `#98A2B0` | Focus rings, selected outlines |
| `textPrimary` | `#0F1720` | Amounts, titles |
| `textSecondary` | `#5A6675` | Labels, metadata |
| `textTertiary` | `#98A2B0` | Placeholders, disabled |
| `textOnBrand` | `#FFFFFF` | Text on `brandPrimary` |
| `brandPrimary` | `#0E7C66` | FAB, selected tab, primary button |
| `brandSubtle` | `#D6F0E8` | Selected chip background, today ring |
| `moneyOut` | `#CC3438` | Expense amounts — 5.1:1 on `surface` |
| `moneyOutSubtle` | `#FDE7E7` | Expense capsule fill |
| `moneyIn` | `#1E7A45` | Income amounts — 5.35:1 on `surface` |
| `moneyInSubtle` | `#E3F6E9` | Income capsule fill |
| `warning` | `#C98A0B` | Budget near limit |
| `warningSubtle` | `#FCF0D8` | Warning capsule fill |
| `overlay` | `#0F1720` @ 32% | Scrims |
| `glassTint` | `#FFFFFF` @ 62% | Glass surface fill (see §2.5) |
| `glassStroke` | `#FFFFFF` @ 45% | Glass hairline highlight |

### 2.3 Semantic tokens — dark

| Token | Value | Notes |
|---|---|---|
| `surface` | `#0E1218` | Page background |
| `surfaceRaised` | `#182029` | Cards/rows |
| `surfaceSubtle` | `#141A21` | Grouped sections |
| `surfaceSunken` | `#0A0E13` | Keypad tray |
| `border` | `#26313D` | Hairlines |
| `borderStrong` | `#98A2B0` | Focus |
| `textPrimary` | `#F5F7FA` | |
| `textSecondary` | `#98A2B0` | |
| `textTertiary` | `#5A6675` | |
| `brandPrimary` | `#2BB99A` | **Lightened** — `jade600` fails 4.5:1 on dark |
| `brandSubtle` | `#0F2E28` | |
| `moneyOut` | `#FF6B6F` | Lightened for dark contrast |
| `moneyOutSubtle` | `#33191B` | |
| `moneyIn` | `#4CC777` | |
| `moneyInSubtle` | `#122C1C` | |
| `warning` | `#E0A63C` | |
| `warningSubtle` | `#33280F` | |
| `overlay` | `#000000` @ 55% | |
| `glassTint` | `#182029` @ 58% | |
| `glassStroke` | `#FFFFFF` @ 12% | |

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
| `moneyIn` `#1E7A45` on `#FFFFFF` | 5.35 | ✅ AA |
| `moneyIn` `#1E7A45` on `#F5F7FA` | 4.99 | ✅ AA |
| dark `moneyOut` `#FF6B6F` on `#0E1218` | 6.78 | ✅ AA |
| dark `moneyIn` `#4CC777` on `#0E1218` | 8.71 | ✅ AA |

> Historical note: the first draft used `#E5484D` / `#2E9E5B`, which only reached 3.91 and 3.41 on
> white — **too low for text**. They were kept as-is nowhere: the palette above is the corrected
> pair. Do not "brighten" these for aesthetics without re-running the contrast test.


### 2.5 Glass tokens (iOS only)

Defined here so `core/widgets/glass/` has one source. Glass is **floating chrome only** —
never a content card (`Platform.md` §4).

| Token | Value |
|---|---|
| `glassBlurSigma` | `18` (compact) / `24` (medium+) |
| `glassTint` | see §2.2 / §2.3 |
| `glassStroke` | see §2.2 / §2.3 |
| `glassStrokeWidth` | `0.5` |
| `glassRadius` | `radius.xl` (28) for bars, `radius.lg` (20) for buttons |

Fallback chain: native glass → `BackdropFilter` blur → **solid `surfaceRaised`** when
*Reduce Transparency* or *Increase Contrast* is on. The fallback is not optional.

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
| `xl` | 28 | Glass bars, FAB, large surfaces |
| `full` | 999 | Pills, avatars, circular buttons |

### 4.3 Elevation

We prefer **tint + hairline** over shadow. Only three levels:

| Token | Light | Dark | Use |
|---|---|---|---|
| `flat` | none, `border` hairline | none, `border` hairline | Rows, grouped lists |
| `raised` | `0 1 2 rgba(15,23,32,.06)` | none, lighter surface | Cards |
| `floating` | `0 8 24 rgba(15,23,32,.12)` | `0 8 24 rgba(0,0,0,.4)` | FAB, glass bars, sheets |

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

- Owns: safe areas, top bar (adaptive), bottom nav inset, background (`surface`), the content column,
  and the scroll-under-glass insets.
- The **content column** is capped at 1200 px by default, or at the page's `contentMaxWidth` when it
  declares one (a form or prose list: 560). The frame caps *and centres* the column and derives the
  top bar title's inset from it, so the title's left edge lands on the content's rather than at a
  fixed 16 px. A page that capped its own body could not do this — that was the 55 px title/content
  offset (`docs/Roadmap.md` §G.8 R2 / §J).
- Props: `title`, `leading`, `actions`, `bottomNav`, `floatingAction`, `body`, `isScrollable`,
  `contentMaxWidth`, `contentInset`.
- **Top bar**: iOS large collapsing title w/ glass toolbar; Android M3 Large Top App Bar.

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

- iOS: glass segmented control. Android: M3 `SegmentedButton`. Web: M3.
- Pill shape (`radius.full`), height 32, label `label` token.
- Selected: `brandSubtle` fill + `brandPrimary` label. Unselected: `textSecondary`, no fill.
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

### 5.10 `GlassDock` (iOS) / `M3NavigationBar` (Android)

- iOS: floating glass bar, `radius.xl`, inset `lg` from screen edges and bottom safe area, blur per
  §2.5. Shrinks on scroll-down, expands on scroll-up.
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

- Cell: minimum **44×44**; grid is `7` columns, always.
- Capsule: rounded bar (`radius.sm`, 4 px tall) under the day number, width = 60% of cell.
- **Intensity** maps to `intensity = clamp(net / p95MonthNet, 0, 1)` where `p95PeriodNet` is the
  95th-percentile absolute net of the visible period. Quantize into **5 steps** (`0, .25, .5, .75, 1`)
  so the grid reads as texture, not noise.
  - Step 0 (no transactions): no capsule at all.
  - Steps 1–4: `moneyOutSubtle` at 25/50/75/100% alpha — **or** `moneyInSubtle` for net-positive days.
- **Today**: `brandPrimary` 1.5 px ring around the cell, `radius.full`.
- **Selected**: `brandSubtle` fill behind the whole cell, `radius.md`; day number goes
  `brandPrimary` w600. Selection and today can coexist (ring drawn over fill).
- **Outside the visible period** (padding days that complete the first/last week): `textTertiary`, capsule at 40% alpha, still tappable (navigates to the neighbouring period).
- Weekend column headers get `textTertiary`; no other special-casing.
- Densities: compact shows capsule + number. Expanded shows capsule + number + tiny amount
  (`caption`, truncated) for cells wide enough (≥ 64 px).

**Period switcher**: `‹` / `›` icons (`short` slide+fade of the grid), title is a tappable
period picker. `today` button appears only when the visible period ≠ the current period.
Horizontal swipe on the grid changes month; the swipe must not fight the day-list scroll
(grid owns horizontal, list owns vertical).

### 6.3 Summary card

An `AppCard` directly under the grid.

- Eyebrow: `overline`, `textSecondary` — "SPENT TODAY" / localized.
- Hero: `displayAmount`, `signed: true`, animated on day change (`short`).
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
- [ ] `RepaintBoundary` around the calendar grid and any chart
- [ ] Golden tests per platform × light/dark for design-system components
- [ ] Screenshot reviewed in `--profile` on a low-end device, no jank while scrolling the grid
