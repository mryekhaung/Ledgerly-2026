# Platform.md — Adaptive UI (iOS native · Android Material 3 · Responsive Web)

One codebase, one domain layer, one set of brand tokens — **platform-specific chrome and controls**, **window-size-specific layouts**.

## 1. Targets
| Target | Visual language | Notes |
|---|---|---|
| iOS / iPadOS | Native iOS controls; system Liquid Glass on iOS 26+, opaque Cupertino fallback | App Store |
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
  app_nav/     adaptive_nav.dart · native iOS tab bar · M3 navigation bar · nav rail/sidebar
  ...every design-system component follows: one public widget → per-platform implementations
```
**Rules**
1. **Pages/features never check the platform.** They use design-system widgets (`AppScaffold`, `AppButton`, `AppSwitch`, `AppDatePicker`, `AppDialog`, `AppActionSheet`, `AdaptiveNav`…). Only `core/widgets` branches on platform.
2. **Shared:** domain, data, state, routes, brand color/typography tokens, page *structure*.
3. **Platform-specific:** navigation chrome, top bars, buttons, switches, pickers, dialogs, sheets, transitions, haptic style, scroll physics.
4. **Layout differences come from size class, not platform** (an Android tablet and iPad get the same layout).
5. Each adaptive component ships a golden test per platform × light/dark.

## 3. Component mapping
| Concern | iOS — native Cupertino | Android — Material 3 | Web (≥ medium) |
|---|---|---|---|
| Primary nav | Native `UITabBar` on iOS 26+; `CupertinoTabBar` on older iOS | M3 `NavigationBar` | `NavigationRail` (medium) → sidebar drawer (expanded) |
| Top bar | Native Liquid Glass toolbar on iOS 26+ for plain titles and adaptive actions; Cupertino navigation bar otherwise | M3 Top App Bar (Large/Medium collapsing) | Header bar with page title + actions |
| Buttons | Cupertino; native Liquid Glass buttons on iOS 26+ | M3 buttons | M3 buttons |
| Primary action (+) | Native-style toolbar action | M3 FAB (Extended FAB on wide) | Extended FAB or header button + shortcut `N` |
| Sheets | Cupertino sheet | M3 Modal Bottom Sheet | Centered dialog / side panel |
| Date picker | Native adaptive picker; in-app calendar page for transaction/recurring dates | M3 picker; in-app calendar page for transaction/recurring dates | M3 picker; in-app calendar page for transaction/recurring dates |
| Segmented control | Cupertino segmented (Expense/Income) | M3 `SegmentedButton` | M3 `SegmentedButton` |
| Switch / toggles | Cupertino switch | M3 switch | M3 switch |
| Dialogs / confirm | Alert + action sheet | M3 AlertDialog | M3 AlertDialog |
| Form selectors | Native selection sheet | M3 dropdown field | M3 dropdown field |
| Page transition | iOS push + edge-swipe back | M3 shared-axis + predictive back | Fade-through |
| Feedback | `HapticFeedback` light/medium (taptic feel) | Haptics where supported | Hover/focus/pressed states |
| System UI | Safe areas, Dynamic Island aware | Edge-to-edge, system bars transparent | Max content width, scrollbars |
| Color | Brand tokens | Brand tokens; optional **Dynamic Color** toggle in Settings (default OFF to keep brand identity) | Brand tokens |
| Body font | System (SF) + Noto Sans Myanmar fallback | Roboto/system + Noto Sans Myanmar | Bundled Inter + Noto fonts (web has no reliable system fallback) |
| Amounts | Inter tabular (all platforms, brand consistency) | same | same |

## 4. Native platform UI
`adaptive_platform_ui: ^1.0.2` provides platform-specific navigation and controls:

- iOS 26+: a native UIKit tab bar with the system Liquid Glass effect.
- iOS 26+: `AdaptiveToolbarHost` provides the native UIKit toolbar for pages
  with a plain title and adaptive `AdaptiveAppBarAction`s. Pair custom fallback
  actions with their adaptive equivalents; put page tabs in the body below the
  toolbar rather than in `AppScaffold.bottom`. Arbitrary Flutter toolbar widgets
  without native action equivalents retain the Cupertino navigation bar. The
  native toolbar overlays the body, so `AppScaffold` consumes the
  package-provided top inset even when a page's scrollable has explicit padding.
- Category create/edit forms use `AppScaffold` and adaptive save actions so the
  route uses the same native toolbar instead of a standalone Material form bar.
- iOS 15–25: native-style Cupertino controls with opaque surfaces. App modal
  sheets reserve space below the system/app bar and use a functional drag handle.
- Android: Material navigation and controls.
- `AppSelectField` keeps Material dropdowns off iOS and presents options in an
  adaptive Cupertino / Liquid Glass sheet.
- The app minimum is iOS 15, matching the package's podspec requirement.

Do not imitate Liquid Glass with Flutter `BackdropFilter`, translucent tint, or
decorative hairlines. Use the package's native iOS 26 bar where supported; use
opaque Cupertino surfaces on older iOS and Material surfaces on Android/web.
Content cards are always opaque brand surfaces.

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
- **Recurring forms:** start/end dates open the shared routed calendar picker;
  configured date bounds stay selectable and the picker remains a GoRouter page.
- **Modal sheets:** shared sheets reserve top clearance beneath the native app
  bar and expose a working downward drag-to-dismiss handle; long option lists
  remain content-sized until they reach their height cap.
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
