import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/platform/window_size.dart';

void main() {
  group('WindowSizeClass.fromWidth', () {
    test('should_return_compact_when_width_below_600', () {
      expect(WindowSizeClass.fromWidth(360), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(599), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(0), WindowSizeClass.compact);
    });

    test('should_return_medium_when_width_between_600_and_840', () {
      expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(768), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(839), WindowSizeClass.medium);
    });

    test('should_return_expanded_when_width_between_840_and_1200', () {
      expect(WindowSizeClass.fromWidth(840), WindowSizeClass.expanded);
      expect(WindowSizeClass.fromWidth(1024), WindowSizeClass.expanded);
      expect(WindowSizeClass.fromWidth(1199), WindowSizeClass.expanded);
    });

    test('should_return_large_when_width_at_or_above_1200', () {
      expect(WindowSizeClass.fromWidth(1200), WindowSizeClass.large);
      expect(WindowSizeClass.fromWidth(1440), WindowSizeClass.large);
    });

    test('should_classify_every_canonical_test_width', () {
      final actual = TestWidths.all.map(WindowSizeClass.fromWidth).toList();

      expect(actual, <WindowSizeClass>[
        WindowSizeClass.compact, // 360
        WindowSizeClass.compact, // 390
        WindowSizeClass.compact, // 430
        WindowSizeClass.medium, // 768
        WindowSizeClass.expanded, // 1024
        WindowSizeClass.large, // 1440
      ]);
    });
  });

  group('layout capabilities', () {
    test('should_allow_two_panes_only_from_medium_up', () {
      expect(WindowSizeClass.compact.isTwoPaneCapable, isFalse);
      expect(WindowSizeClass.medium.isTwoPaneCapable, isTrue);
      expect(WindowSizeClass.expanded.isTwoPaneCapable, isTrue);
      expect(WindowSizeClass.large.isTwoPaneCapable, isTrue);
    });

    test('should_use_navigation_rail_only_from_medium_up', () {
      expect(WindowSizeClass.compact.usesNavigationRail, isFalse);
      expect(WindowSizeClass.medium.usesNavigationRail, isTrue);
    });

    test('should_use_sidebar_only_from_expanded_up', () {
      expect(WindowSizeClass.compact.usesSidebar, isFalse);
      expect(WindowSizeClass.medium.usesSidebar, isFalse);
      expect(WindowSizeClass.expanded.usesSidebar, isTrue);
      expect(WindowSizeClass.large.usesSidebar, isTrue);
    });

    test('should_use_modal_forms_only_from_medium_up', () {
      expect(WindowSizeClass.compact.usesModalForms, isFalse);
      expect(WindowSizeClass.medium.usesModalForms, isTrue);
    });
  });

  group('label', () {
    test('should_describe_each_class', () {
      expect(WindowSizeClass.compact.label, 'compact');
      expect(WindowSizeClass.medium.label, 'medium');
      expect(WindowSizeClass.expanded.label, 'expanded');
      expect(WindowSizeClass.large.label, 'large');
    });
  });
}
