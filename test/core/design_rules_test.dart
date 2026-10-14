import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:material_ui/material_ui.dart';

/// Enforces the design-system contract at the *source* level.
///
/// `test/app/theme/design_tokens_test.dart` proves the token **values** are
/// right (contrast, scale, tabular figures). This file proves the app actually
/// **uses** them. Without it `docs/Design.md` is a document nothing checks — and
/// that is exactly how this app drifted to 30 off-scale radii, 32 hand-rolled
/// page frames and 21 first-paint spinners while every build stayed green.
///
/// It is a text scan rather than an analyzer plugin: every rule here is
/// expressible as "this construct must not appear in this directory", and a test
/// needs no extra tooling to run in CI. Three limits are accepted deliberately:
///  * it cannot see a value laundered through a variable,
///  * it cannot tell a painted colour from one in dead code, and
///  * it strips `//` comments, so a `//` inside a string literal clips the line
///    (the failure mode is a miss, never a false alarm — the same trade-off
///    `test/core/layer_rule_test.dart` documents for the layer rules).
///
/// ## Why a burn-down budget instead of a plain gate
///
/// The app already violates every rule below, so a naive gate would be red on
/// arrival and deleted within a week. Instead each rule carries a **per-file
/// budget** of the violations that existed when the rule was written. The gate
/// then fails on any *increase* in any file, so new debt is blocked immediately
/// while the old debt is paid down file by file.
///
/// Budgets are checked in both directions — a file that now has *fewer*
/// violations than its budget also fails, with "tighten the number". That is what
/// stops this from becoming a permanent allowlist. Burn-down progress is tracked
/// in `docs/Roadmap.md` ("Design debt burn-down").
/// A violation site, carrying everything the failure message needs.
///
/// Top-level rather than local to `main()`: Dart does not allow a class
/// declaration inside a function body.
final class Site {
  /// Records a site.
  const Site(this.file, this.lineNumber, this.text);

  /// Repo-relative path.
  final String file;

  /// 1-based line number.
  final int lineNumber;

  /// The raw source line, trimmed for display.
  final String text;

  @override
  String toString() => '$file:$lineNumber  $text';
}

void main() {
  // ---------------------------------------------------------------------------
  // Scanner
  // ---------------------------------------------------------------------------

  /// Every `.dart` file under [dir], recursive, sorted for stable output.
  List<File> dartFilesIn(String dir) {
    final directory = Directory(dir);
    if (!directory.existsSync()) {
      // A missing directory would make every rule below pass vacuously — the
      // tripwire `layer_rule_test.dart` uses for the same reason.
      fail('Expected directory "$dir" to exist (docs/Architecture.md §2).');
    }
    return directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        // Generated and vendored sources are not ours to police.
        .where((file) => !file.path.endsWith('.g.dart'))
        .where((file) => !file.path.endsWith('.gr.dart'))
        .where((file) => !file.path.endsWith('.freezed.dart'))
        .where(
          (file) => !file.path.replaceAll(r'\', '/').contains('l10n/generated'),
        )
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  /// Repo-relative path with forward slashes, so budget keys are portable
  /// between the agent's Windows checkout and CI's Linux runner.
  String relative(String path) {
    final cwd = Directory.current.path.replaceAll(r'\', '/');
    final normalized = path.replaceAll(r'\', '/');
    final prefix = cwd.endsWith('/') ? cwd : '$cwd/';
    return normalized.startsWith(prefix)
        ? normalized.substring(prefix.length)
        : normalized;
  }

  /// Strips a trailing `//` comment from [line].
  String withoutComment(String line) {
    final index = line.indexOf('//');
    return index == -1 ? line : line.substring(0, index);
  }

  /// Finds every line under [dirs] matching [pattern] on its comment-stripped
  /// form. [include] filters by exact relative path; [dismiss] drops a matching
  /// line whose content is a legitimate exception.
  List<Site> scan(
    List<String> dirs,
    RegExp pattern, {
    bool Function(String path)? include,
    bool Function(String line)? dismiss,
  }) {
    final sites = <Site>[];
    for (final dir in dirs) {
      for (final file in dartFilesIn(dir)) {
        final path = relative(file.path);
        if (include != null && !include(path)) continue;

        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final code = withoutComment(lines[i]);
          if (!pattern.hasMatch(code)) continue;
          if (dismiss != null && dismiss(code)) continue;
          sites.add(Site(path, i + 1, lines[i].trim()));
        }
      }
    }
    return sites;
  }

  /// Asserts that no file exceeds its budget, and that no budget is loose.
  ///
  /// [budgets] maps a relative file path to how many violations it may have. A
  /// file absent from the map is allowed zero. Both directions are checked so
  /// the map can only ever tighten.
  void expectWithinBudget(
    String rule,
    String doc,
    List<Site> sites,
    Map<String, int> budgets,
  ) {
    final byFile = <String, List<Site>>{};
    for (final site in sites) {
      (byFile[site.file] ??= <Site>[]).add(site);
    }

    final overage = <String>[];
    for (final entry in byFile.entries) {
      final budget = budgets[entry.key] ?? 0;
      if (entry.value.length <= budget) continue;
      overage.add(
        '  ${entry.key}: ${entry.value.length} found, budget $budget\n'
        '${entry.value.skip(budget).map((s) => '    $s').join('\n')}',
      );
    }

    expect(
      overage,
      isEmpty,
      reason:
          'New $rule violation(s) — $doc.\n'
          'Use the design token/component instead:\n'
          '${overage.join('\n')}',
    );

    final slack = <String>[];
    for (final entry in budgets.entries) {
      final found = byFile[entry.key]?.length ?? 0;
      if (found >= entry.value) continue;
      slack.add('  ${entry.key}: budget ${entry.value}, found $found');
    }

    expect(
      slack,
      isEmpty,
      reason:
          'Stale $rule budget(s) — these files have fewer violations than their '
          'budget, so the number now licenses new debt. Lower it (delete the '
          'entry at 0):\n'
          '${slack.join('\n')}',
    );
  }

  // ---------------------------------------------------------------------------
  // Rule 1 — colours come from tokens
  // ---------------------------------------------------------------------------

  /// The curated avatar palette is *data*, not theme: N hex values the user
  /// picks between, authored in one file by definition, so it is exempt.
  const avatarPalettePath =
      'lib/features/profile/presentation/widgets/avatar_palette.dart';

  group('design rule: colours come from tokens (docs/Design.md §2)', () {
    test('should_not_hardcode_a_colour_in_a_widget', () {
      final sites = scan(
        const <String>['lib/features', 'lib/core/widgets'],
        // `\b` matters: without it `AppThemeColors.of` matches `Colors.of`.
        RegExp(r'\bColor\(0x|\bColors\.(?!transparent)[a-z]'),
        include: (path) => path != avatarPalettePath,
      );

      expectWithinBudget(
        'hardcoded colour',
        'docs/Design.md §2 — widgets read AppThemeColors, never raw hex',
        sites,
        // Burned to zero. The last of them were a reimplemented `warning`
        // (#D97706, which also broke dark mode), Material's stock
        // green/orange/blue, and several `Colors.white` on-colour uses that
        // now read `textOnBrand`.
        const <String, int>{},
      );
    });

    test('should_keep_the_avatar_palette_as_the_single_colour_data_source', () {
      // Re-asserts the exemption so a later reader does not "fix" the palette
      // file and delete the curated set the avatar feature depends on.
      final palette = File(avatarPalettePath);
      expect(palette.existsSync(), isTrue);
      expect(
        palette.readAsStringSync().contains('Color(0x'),
        isTrue,
        reason:
            'The curated avatar palette intentionally holds raw hex values.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Rule 2 — radius comes from AppRadius
  // ---------------------------------------------------------------------------

  group('design rule: radius comes from AppRadius (docs/Design.md §4.2)', () {
    /// The only five values the scale defines.
    const scale = <int>{8, 12, 20, 28, 999};

    test('should_only_use_a_value_from_the_radius_scale', () {
      final sites = <Site>[];
      for (final file in dartFilesIn('lib')) {
        final path = relative(file.path);
        if (path == 'lib/app/theme/app_spacing.dart') continue;

        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          for (final match in RegExp(
            r'(?:Border)?Radius\.circular\((\d+)\)',
          ).allMatches(withoutComment(lines[i]))) {
            if (scale.contains(int.parse(match.group(1)!))) continue;
            sites.add(Site(path, i + 1, lines[i].trim()));
          }
        }
      }

      expectWithinBudget(
        'off-scale radius',
        'docs/Design.md §4.2 — only AppRadius.sm(8)/md(12)/lg(20)/xl(28)/full(999)',
        sites,
        // Burned to zero. Any new off-scale radius now fails immediately.
        const <String, int>{},
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Rule 3 — pages use AppScaffold
  // ---------------------------------------------------------------------------

  group('design rule: pages use AppScaffold (docs/Design.md §5.1)', () {
    /// Files whose `Scaffold` **is** the frame rather than a page inside one.
    ///
    /// `AppScaffold` is a *page* frame: it supplies the content cap, safe areas
    /// and an adaptive bar to whatever body a page hands it. These three supply
    /// a frame themselves, so routing them through `AppScaffold` would either
    /// recurse or fight the thing that calls them:
    ///
    /// * `app_shell.dart` — hosts `AppScaffold` pages as its child; it must own
    ///   the nav chrome the pages sit in.
    /// * `responsive_layout.dart` (`ModalFormScaffold`) — a deliberately
    ///   different presentation for modal *forms*: a card on a sunk background
    ///   with its own `AppBar`, not the standard page frame.
    /// * `app_router.dart` — the error/loading frames for a route that cannot
    ///   build its page yet.
    ///
    /// The rule therefore targets pages, and these are asserted below to still
    /// exist so a later reader does not "fix" them.
    const framePaths = <String>[
      'lib/app/router/app_shell.dart',
      'lib/app/router/app_router.dart',
      'lib/features/shared/presentation/widgets/responsive_layout.dart',
    ];

    test('should_not_build_a_raw_scaffold_in_a_feature_page', () {
      final sites = scan(
        const <String>['lib/features', 'lib/app'],
        // ScaffoldMessenger is not a page frame; `(?<!Messenger)` is unavailable
        // in Dart's RegExp, so it is dismissed below by content instead.
        RegExp(r'\bScaffold\('),
        dismiss: (line) => line.contains('ScaffoldMessenger'),
        include: (path) => !framePaths.contains(path),
      );

      expectWithinBudget(
        'raw Scaffold',
        'docs/Design.md §5.1 — "Every page uses AppScaffold, no raw Scaffold in '
            'features": it owns the 1200 px content cap and the safe areas, so a '
            'raw Scaffold stretches to 1440 px on web',
        sites,
        // Burned to zero for pages. The only remaining `Scaffold`s live in the
        // three frame files excluded above, which supply the frame rather than
        // sit inside one.
        const <String, int>{},
      );
    });

    test('should_keep_the_exempted_page_frames', () {
      // Re-asserts the path exemption: these three files are excluded from the
      // rule above because they supply a frame rather than live inside one, so
      // they must still actually contain the scaffolds being exempted.
      for (final path in framePaths) {
        final source = File(path).readAsStringSync();
        expect(
          RegExp(r'\bScaffold\(').hasMatch(source),
          isTrue,
          reason:
              '$path is exempted from the AppScaffold rule because it '
              'builds the frame itself; if that is no longer true, remove it '
              'from framePaths.',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Rule 4 — first paint is a skeleton, not a spinner
  // ---------------------------------------------------------------------------

  group('design rule: loading is a skeleton (docs/Design.md §5.11)', () {
    test('should_not_show_a_centered_spinner_on_first_paint', () {
      // §5.11 bans the *first-paint* spinner, not every spinner. Two kinds are
      // legitimate and are dismissed here rather than budgeted, so the rule can
      // sit at zero and every future spinner has to justify itself:
      //
      //   1. A **busy indicator inside a control** — a `Submit` button that
      //      swaps its label for a thin spinner. §5.11 does not cover this: the
      //      affordance is the button and the page is not blanked. These always
      //      set a thin `strokeWidth` (they are 18-20 px, where the default
      //      4 px ring swamps the label).
      //   2. **`AppSkeleton`** — the sanctioned first-paint treatment, which
      //      happens to animate and so mentions no spinner at all.
      //
      // `AppSkeleton` therefore never matches, and a bare
      // `CircularProgressIndicator()` in a page body still does.
      //
      // The `strokeWidth` tell can land on the *next* line (a formatted
      // `CircularProgressIndicator(\n strokeWidth: 2,\n)`), so the dismissal
      // looks one line ahead. `scan` is line-scoped, so the join happens here.
      final allLines = <String, List<String>>{};
      final sites = scan(
        const <String>['lib/features', 'lib/app'],
        RegExp(r'CircularProgressIndicator'),
        dismiss: (line) => line.contains('strokeWidth'),
      );

      // Re-scan, dismissing on the joined (line, next-line) text so a spinner
      // whose `strokeWidth` wrapped onto the following line is still treated as
      // a busy indicator.
      final refined = <Site>[];
      for (final site in sites) {
        final lines = allLines.putIfAbsent(site.file, () {
          final file = File(site.file);
          return file.existsSync() ? file.readAsLinesSync() : const <String>[];
        });
        final next = site.lineNumber < lines.length
            ? withoutComment(lines[site.lineNumber])
            : '';
        if (next.contains('strokeWidth')) continue;
        refined.add(site);
      }

      expectWithinBudget(
        'first-paint spinner',
        'docs/Design.md §5.11 — "never a centered spinner"; first paint is a '
            'skeleton matching the final layout',
        refined,
        const <String, int>{},
      );
    });

    test('should_dismiss_only_the_busy_indicator_form', () {
      // Pins the dismissal above: a thin spinner is allowed, a bare one is not.
      final pattern = RegExp(r'CircularProgressIndicator');
      bool dismiss(String line) => line.contains('strokeWidth');

      expect(
        dismiss('child: CircularProgressIndicator(strokeWidth: 2),'),
        isTrue,
        reason: 'A busy indicator inside a button carries a strokeWidth.',
      );
      expect(
        dismiss(
          'loading: () => const Center(child: CircularProgressIndicator()),',
        ),
        isFalse,
        reason: 'A first-paint spinner is bare, so it must not be dismissed.',
      );
      expect(
        pattern.hasMatch('child: CircularProgressIndicator.adaptive(),'),
        isTrue,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Rule 5 — type comes from AppTypography
  // ---------------------------------------------------------------------------

  group('design rule: type comes from AppTypography (docs/Design.md §3)', () {
    test('should_not_go_below_the_caption_size', () {
      final sites = <Site>[];
      for (final file in dartFilesIn('lib')) {
        final path = relative(file.path);
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final match = RegExp(r'fontSize:\s*(\d+)')
              .firstMatch(withoutComment(lines[i]));
          if (match == null) continue;
          if (int.parse(match.group(1)!) >= 11) continue;
          sites.add(Site(path, i + 1, lines[i].trim()));
        }
      }

      expectWithinBudget(
        'sub-caption text',
        'docs/Design.md §3 — "Never go below caption (11)"; Burmese and '
            'Japanese lose legibility below it',
        sites,
        // Burned to zero. The four sites here were the calendar month label
        // (now `overline` per §6.6), the archived badge on `account_card`, and
        // the two chart captions (now derived from `caption`).
        const <String, int>{},
      );
    });

    test('should_not_build_an_inline_text_style_in_a_view', () {
      final sites = scan(const <String>[
        'lib/features',
      ], RegExp(r'TextStyle\('));

      expectWithinBudget(
        'inline TextStyle',
        'docs/Design.md §3 / §8 — "Only tokens, zero literal sizes"; build '
            'styles from theme.textTheme.* or AppTypography.*',
        sites,
        // Burned to zero. Every site now derives from `AppTypography.*`
        // (`title`/`body`/`label`/`caption`/`overline`) with only colour and,
        // where the design calls for it, a weight override.
        const <String, int>{},
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Rule 6 — user-facing copy is localized
  // ---------------------------------------------------------------------------

  group('design rule: UI copy is localized (docs/Design.md §7)', () {
    test('should_not_hardcode_an_english_string_in_a_widget', () {
      final sites = scan(const <String>[
        'lib/features',
      ], RegExp(r"""Text\(\s*'[A-Za-z][A-Za-z ]{2,}'"""));

      expectWithinBudget(
        'hardcoded UI string',
        'docs/Design.md §7 — every visible string is an ARB key (en/my/ja); '
            'no literals in widgets',
        sites,
        // Burned to zero: the two "Paste" buttons became `dataTransferPaste`,
        // the goal dialog's "Cancel" reuses `actionCancel`, and the recurring
        // form's "No Account specified" became `recurringAccountNone`.
        const <String, int>{},
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Rule 7 — chrome adapts per platform
  // ---------------------------------------------------------------------------

  group('design rule: chrome is platform-adaptive (docs/Platform.md §2)', () {
    test('should_choose_the_splash_per_platform_not_globally', () {
      // The bug this guards: the theme set `splashFactory: InkSparkle...`
      // unconditionally, so iOS got an Android ink ripple — the "skinned, not
      // native" trap docs/Design.md §1 forbids and §5.2 calls out ("never a
      // ripple on iOS").
      //
      // A plain "contains InkSparkle" check would be wrong: Material *should*
      // have the sparkle. What must hold is that the choice is gated on the
      // platform, so iOS resolves to a no-ripple factory.
      final theme = File('lib/app/theme/app_theme.dart').readAsStringSync();

      expect(
        theme.contains('AppPlatform.resolve()'),
        isTrue,
        reason:
            'The theme must resolve the host platform so chrome can adapt '
            '(docs/Platform.md §2). app.dart passes an explicit platform in '
            'tests, so `_build` needs a platform parameter.',
      );

      expect(
        theme.contains('NoSplash.splashFactory'),
        isTrue,
        reason:
            'iOS must get a no-ripple press treatment, not a Material ink '
            'splash (docs/Design.md §5.2).',
      );

      // The global, ungated assignment is the actual smell.
      expect(
        RegExp(r'splashFactory:\s*InkSparkle\.splashFactory\s*,')
            .hasMatch(theme),
        isFalse,
        reason:
            'splashFactory is assigned unconditionally, so iOS inherits the '
            'Android ripple. Gate it on AppPlatform.usesMaterial.',
      );
    });

    test('should_not_apply_a_material_ripple_when_the_platform_is_ios', () {
      final ios = AppTheme.light(platform: AppPlatform.ios);
      final android = AppTheme.light(platform: AppPlatform.android);

      expect(
        ios.splashFactory,
        isNot(android.splashFactory),
        reason: 'iOS and Android must not share one splash factory.',
      );
      expect(
        ios.splashFactory,
        NoSplash.splashFactory,
        reason: 'iOS uses the Cupertino press state, not an ink ripple.',
      );
      expect(
        android.splashFactory,
        InkSparkle.splashFactory,
        reason: 'Android keeps the M3 sparkle.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Scanner self-check — a rule that cannot detect is worse than no rule
  // ---------------------------------------------------------------------------

  group('scanner self-check', () {
    /// The literal-colour pattern, kept here so the self-checks exercise the
    /// exact expression the rule uses.
    final colourPattern = RegExp(r'\bColor\(0x|\bColors\.(?!transparent)[a-z]');

    test('should_flag_a_literal_colour', () {
      expect(colourPattern.hasMatch('color: Color(0xFFD97706)'), isTrue);
      expect(colourPattern.hasMatch('color: Colors.white'), isTrue);
    });

    test('should_not_flag_a_theme_token_colour', () {
      // The bug this guards against: `AppThemeColors.of` matched `Colors.of`
      // before the `\b` was added, which flagged 150 legitimate call sites.
      expect(
        colourPattern.hasMatch('final colors = AppThemeColors.of(context);'),
        isFalse,
      );
      expect(colourPattern.hasMatch('color: colors.brandPrimary,'), isFalse);
    });

    test('should_allow_transparent', () {
      expect(colourPattern.hasMatch('color: Colors.transparent'), isFalse);
    });

    test('should_flag_an_off_scale_radius_and_pass_a_token', () {
      final pattern = RegExp(r'(?:Border)?Radius\.circular\((\d+)\)');
      final match = pattern.firstMatch('BorderRadius.circular(16)');
      expect(match, isNotNull);
      expect(int.parse(match!.group(1)!), 16);
      expect(pattern.hasMatch('BorderRadius.circular(20)'), isTrue);
    });

    test('should_flag_a_raw_scaffold_but_dismiss_a_messenger', () {
      final pattern = RegExp(r'\bScaffold\(');
      bool dismiss(String line) => line.contains('ScaffoldMessenger');

      expect(pattern.hasMatch('return Scaffold('), isTrue);
      const messenger = 'ScaffoldMessenger.of(context).showSnackBar';
      expect(pattern.hasMatch(messenger) && !dismiss(messenger), isFalse);
    });

    test('should_flag_a_sub_caption_size', () {
      final match = RegExp(r'fontSize:\s*(\d+)').firstMatch('fontSize: 10,');
      expect(int.parse(match!.group(1)!), lessThan(11));
    });

    test('should_flag_a_hardcoded_string', () {
      expect(
        RegExp(r"""Text\(\s*'[A-Za-z][A-Za-z ]{2,}'""")
            .hasMatch("child: Text('No Account specified')"),
        isTrue,
      );
    });

    test('should_skip_generated_localizations', () {
      final paths = dartFilesIn('lib').map((f) => relative(f.path)).toList();
      expect(paths.where((p) => p.contains('l10n/generated')), isEmpty);
    });

    test('should_scan_a_non_trivial_source_tree', () {
      // Guards against the scanner silently running over nothing.
      expect(dartFilesIn('lib/features').length, greaterThan(50));
    });
  });
}
