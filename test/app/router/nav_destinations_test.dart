import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/router/nav_destinations.dart';
import 'package:ledgerly/core/widgets/app_nav/adaptive_nav.dart';

/// `NavDestination` — the single source of truth for primary navigation.
///
/// The route-matching rule is worth testing on its own because it is the one
/// thing that decides whether a whole section reads as "you are here", and a bug
/// in it is invisible on the home screen (the calendar matches `/`, which every
/// naive prefix match would also catch).
void main() {
  group('the destination list', () {
    test('should_cover_every_primary_route_exactly_once', () {
      final routes = NavDestination.all.map((d) => d.route).toList();

      expect(routes.toSet().length, routes.length, reason: 'no duplicates');
      expect(
        routes,
        containsAll(<String>[
          AppRoutes.calendar,
          AppRoutes.insights,
          AppRoutes.categories,
          AppRoutes.settings,
        ]),
      );
    });

    test('should_start_with_the_calendar_as_the_home_destination', () {
      // The order is the tab order, and the calendar is the app's home screen.
      expect(NavDestination.all.first, NavDestination.calendar);
      expect(NavDestination.calendar.route, '/');
    });

    test('should_give_every_destination_a_distinct_icon_pair', () {
      for (final destination in NavDestination.all) {
        expect(
          destination.icon,
          isNot(destination.selectedIcon),
          reason:
              '${destination.name} must have a distinct selected icon — '
              'the active state cannot be colour-only (Design.md §2 a11y)',
        );
      }
    });

    test('should_give_every_destination_a_label_key_that_is_not_the_route', () {
      for (final destination in NavDestination.all) {
        expect(destination.labelKey, startsWith('navigation'));
      }
    });
  });

  group('fromLocation', () {
    test('should_match_the_root_to_the_calendar_and_nothing_else', () {
      expect(
        NavDestination.fromLocation('/'),
        NavDestination.calendar,
        reason: 'the calendar is the home route',
      );
      // An empty location is what go_router reports before the first frame.
      expect(NavDestination.fromLocation(''), NavDestination.calendar);
    });

    test('should_not_match_an_unrelated_path_to_the_calendar', () {
      // The bug this guards: the calendar's route is `/`, so a naive
      // `startsWith` would make *every* path select the calendar and the bar
      // would never light anything else.
      expect(
        NavDestination.fromLocation(AppRoutes.settings),
        NavDestination.settings,
      );
      expect(
        NavDestination.fromLocation('/transactions/new'),
        isNull,
        reason: 'a form outside the shell has no destination',
      );
    });

    test('should_match_each_primary_route', () {
      for (final destination in NavDestination.all) {
        expect(
          NavDestination.fromLocation(destination.route),
          destination,
          reason: '${destination.route} must select ${destination.name}',
        );
      }
    });

    test('should_keep_the_parent_selected_inside_a_section', () {
      // A user who opened Settings → Currency is still *in* Settings, so the
      // bar must not go dark. This is the reason matching is prefix-aware at
      // all.
      expect(
        NavDestination.fromLocation(AppRoutes.settingsCurrency),
        NavDestination.settings,
      );
      expect(
        NavDestination.fromLocation('/categories/new'),
        NavDestination.categories,
      );
    });

    test('should_not_match_a_prefix_that_is_not_a_segment_boundary', () {
      // `/settingsX` is not inside `/settings` — matching on the raw string
      // without the trailing slash would wrongly select Settings here.
      expect(NavDestination.fromLocation('/settingsX'), isNull);
      expect(NavDestination.fromLocation('/categoriess'), isNull);
    });

    test('should_return_null_for_an_unknown_path', () {
      expect(NavDestination.fromLocation('/nope'), isNull);
      expect(NavDestination.fromLocation('/nope/deeper'), isNull);
    });
  });

  group('isDestinationSelected', () {
    test('should_agree_with_fromLocation_for_every_destination', () {
      for (final candidate in NavDestination.all) {
        for (final destination in NavDestination.all) {
          expect(
            isDestinationSelected(destination, candidate.route),
            destination == candidate,
            reason: 'on ${candidate.route}, only ${candidate.name} is selected',
          );
        }
      }
    });
  });
}
