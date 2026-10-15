# Platform.md — Adaptive UI (iOS Liquid Glass · Android Material 3 · Responsive Web)

One codebase, one domain layer, one set of brand tokens — **platform-specific chrome and controls**, **window-size-specific layouts**.

## 1. Targets
| Target | Visual language | Notes |
|---|---|---|
| iOS / iPadOS | **Liquid Glass** (iOS 26 design), graceful frosted fallback on older iOS | App Store |
| Android (phone/tablet/foldable) | **Material 3** (Expressive where stable) | Play Store |
| Web (planned, not committed) | Material 3-based, **fully responsive**, mouse + keyboard friendly | Keep web-ready from day one; ship later |

## 2. Adaptive architecture
```
core/platform/
  app_platform.dart        # enum AppPlatform { ios, android, web } (kIsWeb first, then defaultTargetPlatform)
  window_size.dart         # WindowSizeClass { compact, medium, expanded, large } from MediaQuery.sizeOf
  adaptive_style.dart      # InheritedWidget exposing platform + size class + reduceTransparency
core/widgets/
  app_button/  app_button.dart (public API) · app_button_ios.dart · app_button_material.dart
  app_nav/     adaptive_nav.dart · glass_tab_bar.dart · m3_navigation_bar.dart · nav_rail_sidebar.dart
  glass/       glass_surface.dart (see §4)
  ...every design-system component follows: one public widget → per-platform implementations
```
**Rules**
1. **Pages/features never check the platform.** They use design-system widgets (`AppScaffold`, `AppButton`, `AppSwitch`, `AppDatePicker`, `AppDialog`, `AppActionSheet`, `AdaptiveNav`…). Only `core/widgets` branches on platform.
2. **Shared:** domain, data, state, routes, brand color/typography tokens, page *structure*.
3. **Platform-specific:** navigation chrome, top bars, buttons, switches, pickers, dialogs, sheets, transitions, haptic style, scroll physics.
4. **Layout differences come from size class, not platform** (an Android tablet and iPad get the same layout).
5. Each adaptive component ships a golden test per platform × light/dark.

## 3. Component mapping
| Concern | iOS — Liquid Glass | Android — Material 3 | Web (≥ medium) |
|---|---|---|---|
| Primary nav | Floating glass tab bar, can shrink on scroll | M3 `NavigationBar` | `NavigationRail` (medium) → sidebar drawer (expanded) |
| Top bar | Large collapsing title, glass toolbar buttons | M3 Top App Bar (Large/Medium collapsing) | Header bar with page title + actions |
| Primary action (+) | Glass circular button / toolbar item | M3 FAB (Extended FAB on wide) | Extended FAB or header button + shortcut `N` |
| Sheets | Glass sheet with detents, grabber | M3 Modal Bottom Sheet | Centered dialog / side panel |
| Date picker | Cupertino-style wheel / compact inline | M3 Date Picker | M3 Date Picker (dialog) |
| Segmented control | Glass segmented (Expense/Income) | M3 `SegmentedButton` | M3 `SegmentedButton` |
| Switch / toggles | Cupertino switch | M3 switch | M3 switch |
| Dialogs / confirm | Alert + action sheet | M3 AlertDialog | M3 AlertDialog |
| Page transition | iOS push + edge-swipe back | M3 shared-axis + predictive back | Fade-through |
| Feedback | `HapticFeedback` light/medium (taptic feel) | Haptics where supported | Hover/focus/pressed states |
| System UI | Safe areas, Dynamic Island aware | Edge-to-edge, system bars transparent | Max content width, scrollbars |
| Color | Brand tokens | Brand tokens; optional **Dynamic Color** toggle in Settings (default OFF to keep brand identity) | Brand tokens |
| Body font | System (SF) + Noto Sans Myanmar fallback | Roboto/system + Noto Sans Myanmar | Bundled Inter + Noto fonts (web has no reliable system fallback) |
| Amounts | Inter tabular (all platforms, brand consistency) | same | same |

## 4. Liquid Glass in Flutter (checked Oct 2026)
Flutter's built-in widgets do not render the system's Liquid Glass by themselves. As of Flutter 3.47, **Cupertino is a standalone package (`cupertino_ui` 1.0, weekly releases)** so official iOS-design updates can arrive without an SDK upgrade — but don't assume full Liquid Glass parity; verify per release.

Options found:
| Option | What it is | Verdict |
|---|---|---|
| **Native platform views** — `cupertino_native_better` (^1.3.8) / `cupertino_native_plus` (community forks) | Real iOS 26 UIKit/SwiftUI widgets (glass buttons, `LiquidGlassContainer`, native tab bar `CNTabBarNative` with minimize-on-scroll) composited under Flutter | **Most authentic look.** Cost: platform-view overhead, community maintenance (fork landscape is fragmented), the native tab bar sits on top of / in place of the Flutter app, which must be reconciled with go_router shells and our responsive layouts |
| **Shader renderer** — `liquid_glass_renderer` (0.2.0-dev.4) | Pure-Flutter refraction shader | **Experimental/prerelease.** Needs Impeller, GPU-heavy, authors warn against blind production use. Use only for 1–2 small elements, or skip |
| **Blur fallback** — `BackdropFilter` + tint + hairline | Frosted look, zero dependencies | Always implemented (iOS < 26, low-end devices, Reduce Transparency) |

**Decision (to confirm in the Phase 0 spike):**
1. Build everything behind **`GlassSurface` / `AdaptiveNav`** (no package imports in pages).
2. Ship the **blur fallback first** (works everywhere, zero risk).
3. Spike **`cupertino_native_better`** for the iOS 26 tab bar + glass buttons; adopt only if it survives: hot-restart stability, go_router integration, accessibility (VoiceOver, Reduce Transparency), and a 12-month maintenance check. Keep it behind the interface so it can be dropped.
4. Do **not** depend on `liquid_glass_renderer` for core UI.

Usage rules:
- Glass is for the **floating chrome layer only** (tab bar, toolbar buttons, FAB, sheets) — **never content cards**.
- Respect *Reduce Transparency* / *Increase Contrast* → solid `surface`.
- Max ~3 glass surfaces on screen; `RepaintBoundary`; profile on an older iPhone in `--profile`.
- Content scrolls **under** the glass bars (insets, not fixed gaps).
- iOS < 26: same layout, blur fallback. Android/web: M3 surfaces — never imitate glass.

## 5. Responsive layout (M3 window size classes)
| Class | Width | Layout |
|---|---|---|
| compact | < 600 | Single column, bottom nav, full-screen push pages |
| medium | 600–839 | Nav rail, two-pane where useful, forms in centered 560px column |
| expanded | 840–1199 | Sidebar nav, master–detail panes |
| large | ≥ 1200 | Sidebar + content capped at ~1200px, extra gutters, 3-column insights |

Screen behaviors:
- **Calendar:** compact → calendar above day list. medium+ → **left: month calendar + summary, right: selected-day transactions** (two panes) — but only while the body can hold both at their floors (a 300 px month pane, a 24 px gap and a 260 px day pane). Below that it stays one column, because a squeezed pair is worse than the single column it replaced (`docs/Roadmap.md` §J). Each pane scrolls independently.
- **Add/Edit Transaction & other forms:** same *route*, different presentation — compact: full-screen page; medium+: centered modal page/side panel (max 560px). Still dedicated pages, never inline edit mazes.
- **Categories:** compact list → form push; expanded → list (left) + form (right) master–detail.
- **Insights:** 1 → 2 → 3 column card grid; charts resize with `LayoutBuilder`.
- **Settings:** compact list; expanded master–detail.
- Never hardcode widths; use `ConstrainedBox(maxWidth)`, flex/grid, `SliverGrid`. Test: 360, 390, 430, 768, 1024, 1440 px; portrait + landscape; text scale 1.0 / 2.0.
- Web extras: keyboard shortcuts (`N` new, `←/→` month, `/` search, `Esc` close), hover + focus rings, right-click/long-press menus, proper tab order, browser back/forward via go_router path URLs.

## 6. Web-ready checklist (so "ship web later" costs little)
- **No `dart:io` in domain/presentation.** Use conditional imports (`file_saver`/anchor download on web, `share_plus` elsewhere).
- Drift on web: `drift_flutter` + `sqlite3.wasm` + drift worker (drift releases now attach compatible wasm files), persisted in OPFS/IndexedDB; test it early in Phase 0.
- Build with `flutter build web --release --wasm`; use `package:web` / `dart:js_interop` (no `dart:html`); Wasm deferred loading is still experimental in 3.47.
- Auth on web: Firebase popup/redirect flow for Google/Apple.
- Bundle fonts (Inter, Noto Sans Myanmar, Noto Sans JP — subset to control size).
- Use `url_strategy` path URLs; add PWA manifest; set a sane renderer (CanvasKit/skwasm) and measure first-load size.
- Plugins: before adding any package, confirm **iOS + Android + web** support (or wrap behind an interface with a web stub).
- A marketing/landing site is separate from the app (SEO is not a Flutter-web strength).

## 7. Store release requirements (verify current rules at submission time)
**App Store**
- If you offer Google/other social login, **Sign in with Apple must also be offered**.
- **In-app account deletion** required (and Apple token revocation on delete).
- Privacy Policy URL, App Privacy "nutrition labels", Terms link.
- iPad screenshots if iPad is supported; build with the current Xcode SDK.
**Google Play**
- **Data safety** form, Privacy Policy, **in-app account deletion + a web URL for deletion requests**.
- Target the required API level; new personal developer accounts may need a closed-testing period with testers before production (check current policy).
**Both:** flavors + signing, fastlane/GitHub Actions release lanes, icon + screenshots (compact/tablet), age rating, support email.
