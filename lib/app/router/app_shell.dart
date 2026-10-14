import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/nav_destinations.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/widgets/app_nav/adaptive_nav.dart';
import 'package:ledgerly/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:material_ui/material_ui.dart';

/// The app shell: primary navigation chrome wrapped around the active page.
///
/// Owns exactly one decision — **where the nav sits relative to the content**,
/// which follows the window size class (`docs/Platform.md` §5):
///
///  * **compact** — nav is a bottom bar; content fills the screen and scrolls
///    *under* it. The page is inset by the bar's height so nothing is hidden.
///  * **medium / expanded / large** — nav is a rail or sidebar on the left and
///    the content is the `Expanded` pane beside it.
///
/// Pages stay unaware of all of this: they render their own `Scaffold` and the
/// shell positions it. That is what lets the same `CalendarPage` be a single
/// column on a phone and the left pane of a two-pane layout on a tablet.
class AppShell extends ConsumerStatefulWidget {
  /// Creates the shell.
  const AppShell({required this.location, required this.child, super.key});

  /// The current route path, used to light the matching destination.
  final String location;

  /// The active page.
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          ref.read(recurringSchedulerNotifierProvider.notifier).runScheduler(),
        );
      }
    });
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        if (mounted) {
          unawaited(
            ref
                .read(recurringSchedulerNotifierProvider.notifier)
                .runScheduler(),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sizeClass = WindowSizeClass.of(context);

    // Reading this here (rather than in the pages) keeps the nav's own label
    // language in step with the rest of the app the moment it changes.
    ref.watch(currentSettingsProvider);

    final current = NavDestination.fromLocation(widget.location);

    void select(NavDestination destination) {
      // `go` rather than `push`: primary destinations replace each other, so
      // the back gesture does not walk a tab history (docs/Platform.md §3).
      if (destination == current) return;
      context.go(destination.route);
    }

    final nav = AdaptiveNav(current: current, onSelect: select);

    // Medium and up: nav is a rail/sidebar beside the content, so the page gets
    // the full remaining width and needs no bottom inset.
    if (sizeClass.usesNavigationRail) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            nav,
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    // Compact: the bar floats over the content. `extendBody` lets a page's
    // scrollable run to the screen edge and be seen *through* the glass, which
    // is the whole point of the bar — but that also means the last row of a list
    // would sit underneath it.
    //
    // The fix belongs here, not in each page: the shell adds the bar's height to
    // the bottom view padding, so any page that already respects safe areas
    // (`SafeArea`, a `ListView` with `padding`, a `SliverAppBar`) clears the bar
    // for free and none of them has to know the bar exists.
    return Scaffold(
      extendBody: true,
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: MediaQuery.paddingOf(
            context,
          ).copyWith(bottom: MediaQuery.paddingOf(context).bottom + _barInset),
          viewPadding: MediaQuery.viewPaddingOf(context).copyWith(
            bottom: MediaQuery.viewPaddingOf(context).bottom + _barInset,
          ),
        ),
        child: widget.child,
      ),
      bottomNavigationBar: nav,
    );
  }

  /// Height reserved for the compact bottom bar, excluding the system inset.
  ///
  /// Matches the M3 `NavigationBar` height the bar sets, so the reserved space
  /// and the painted bar agree. The glass bar is shorter, so it reserves the
  /// same — a consistent gap beats a gap that changes with the platform.
  static const double _barInset = 64;
}
