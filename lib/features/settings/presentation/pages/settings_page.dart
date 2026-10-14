import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/profile/presentation/providers/profile_providers.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:material_ui/material_ui.dart';

/// App settings: currency, language, appearance and week start.
///
/// **No local state.** Every row reads the current value from
/// [currentSettingsProvider] and writes through [saveSettingsActionProvider], so
/// the Drift stream stays the single source of truth: a toggle repaints the app
/// (theme, locale, every amount) without this page holding a copy that could go
/// stale (`docs/Architecture.md` §5).
///
/// The page never fails to render. A preference that cannot be read decodes to
/// its default rather than an error (`SettingsLocalDataSource._decode`), so the
/// only state that can actually fail is the *write* — which surfaces as a
/// snackbar and leaves the switch where it was, because the stream will not have
/// emitted the change.
class SettingsPage extends ConsumerWidget {
  /// Creates the page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final settings = ref.watch(currentSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings('settingsTitle'))),
      // Width-capped rather than stretched: a preference row reads as a row at
      // 560 px and as a stranded label at 1200 (`docs/Design.md` §8).
      body: ConstrainedPane(
        maxWidth: AppSpacing.proseMaxWidth,
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal(
              MediaQuery.sizeOf(context).width,
            ),
            vertical: AppSpacing.lg,
          ),
          children: <Widget>[
            _SectionHeader(label: strings('settingsPreferencesSection')),
            const SizedBox(height: AppSpacing.sm),
            _SettingsGroup(
              children: <Widget>[
                _ChoiceRow<CurrencyCode>(
                  label: strings('settingsCurrencyLabel'),
                  body: strings('settingsCurrencyBody'),
                  value: settings.currency,
                  // Every supported currency, symbol-first so the list reads as
                  // "Ks / ¥ / $" rather than as ten ISO codes.
                  options: <_Choice<CurrencyCode>>[
                    for (final currency in CurrencyCode.values)
                      _Choice<CurrencyCode>(
                        value: currency,
                        label: '${currency.symbol}  ${currency.code}',
                      ),
                  ],
                  onChanged: (value) => _save(
                    context,
                    ref,
                    settings.copyWith(currency: value),
                    strings,
                  ),
                ),
                const _GroupDivider(),
                _ChoiceRow<AppThemeMode>(
                  label: strings('settingsThemeLabel'),
                  value: settings.themeMode,
                  options: <_Choice<AppThemeMode>>[
                    _Choice<AppThemeMode>(
                      value: AppThemeMode.system,
                      label: strings('settingsThemeSystem'),
                    ),
                    _Choice<AppThemeMode>(
                      value: AppThemeMode.light,
                      label: strings('settingsThemeLight'),
                    ),
                    _Choice<AppThemeMode>(
                      value: AppThemeMode.dark,
                      label: strings('settingsThemeDark'),
                    ),
                  ],
                  // Inline segments, not a sheet: three options that each change
                  // the screen *behind* the control, so the result is visible
                  // while choosing rather than after dismissing.
                  layout: _ChoiceLayout.segmented,
                  onChanged: (value) => _save(
                    context,
                    ref,
                    settings.copyWith(themeMode: value),
                    strings,
                  ),
                ),
                const _GroupDivider(),
                _ChoiceRow<WeekStart>(
                  label: strings('settingsWeekStartLabel'),
                  value: settings.weekStart,
                  options: <_Choice<WeekStart>>[
                    _Choice<WeekStart>(
                      value: WeekStart.monday,
                      label: strings('settingsWeekStartMonday'),
                    ),
                    _Choice<WeekStart>(
                      value: WeekStart.sunday,
                      label: strings('settingsWeekStartSunday'),
                    ),
                  ],
                  layout: _ChoiceLayout.segmented,
                  onChanged: (value) => _save(
                    context,
                    ref,
                    settings.copyWith(weekStart: value),
                    strings,
                  ),
                ),
                const _GroupDivider(),
                _NavRow(
                  label: strings('settingsMonthStartsOn'),
                  subtitle: strings('settingsMonthStartsOnDescription'),
                  trailingText: AppStrings.fill(
                    context,
                    'monthStartsOnDayFormat',
                    {'day': settings.monthStartDay},
                  ),
                  onTap: () =>
                      context.pushNamed(AppRoutes.settingsMonthStartsOnName),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(label: strings('settingsLanguageLabel')),
            const SizedBox(height: AppSpacing.sm),
            _SettingsGroup(
              children: <Widget>[
                _ChoiceRow<String?>(
                  // Uses the section header as the visible label, so the row shows
                  // only the current choice — a second copy of the word "Language"
                  // next to a header that already says it is noise.
                  label: null,
                  value: settings.localeCode,
                  options: <_Choice<String?>>[
                    // Null is a real option, not the absence of one: it is how
                    // "follow the device" is stored, and it survives a round-trip
                    // through the table by *deleting* the row rather than writing
                    // a sentinel string.
                    _Choice<String?>(
                      value: null,
                      label: strings('settingsLanguageSystem'),
                    ),
                    const _Choice<String?>(value: 'en', label: 'English'),
                    const _Choice<String?>(value: 'my', label: 'မြန်မာ'),
                    const _Choice<String?>(value: 'ja', label: '日本語'),
                  ],
                  onChanged: (value) => _save(
                    context,
                    ref,
                    value == null
                        ? settings.clearLocale()
                        : settings.copyWith(localeCode: value),
                    strings,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(label: strings('settingsAboutSection')),
            const SizedBox(height: AppSpacing.sm),
            _SettingsGroup(
              children: <Widget>[
                _NavRow(
                  label: strings('profileTitle'),
                  leading: Avatar(
                    config: ref.watch(currentAvatarProvider),
                    size: 32,
                  ),
                  onTap: () => context.pushNamed(AppRoutes.profileName),
                ),
                const _GroupDivider(),
                _InfoRow(
                  label: strings('settingsVersionLabel'),
                  value: _AppVersion.display,
                ),
                const _GroupDivider(),
                _NavRow(
                  label: strings('settingsCreditsTitle'),
                  subtitle: strings('settingsCreditsAvatar'),
                  onTap: () => _showCreditsDialog(context, strings),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  /// Persists [next] and reports the outcome.
  ///
  /// Deliberately does **not** optimistically update anything: the Drift stream
  /// is what repaints the page, which means a failed write leaves the control
  /// showing the old value — the honest result — instead of a change that did
  /// not stick.
  static Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    AppSettings next,
    String Function(String key) strings,
  ) async {
    final result = await ref.read(saveSettingsActionProvider)((
      settings: next,
      partial: false,
    ));

    // The page can be popped mid-write (a fast back-tap), and mounted is the
    // guard that keeps this from touching a disposed element.
    if (!context.mounted) return;

    if (result.isSuccess) {
      // A settings change already repaints the row, so the tap is the
      // acknowledgement and the snack bar is only the confirmation
      // (`docs/Platform.md` §6).
      AppFeedback.selection();
      AppFeedback.confirm(context, message: strings('settingsSaved'));
      return;
    }
    AppFeedback.destructive();
    AppFeedback.failure(context, message: strings('settingsSaveFailed'));
  }

  static void _showCreditsDialog(
    BuildContext context,
    String Function(String key) strings,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings('settingsCreditsTitle')),
        content: Text(strings('settingsCreditsAvatar')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings('actionDone')),
          ),
        ],
      ),
    );
  }
}

/// The app version shown in the About section.
///
/// A constant rather than a `package_info_plus` read: the plugin adds a platform
/// channel and an async startup dependency for a string that changes once per
/// release. `pubspec.yaml` is the source of truth and this is updated with it —
/// the release checklist in `docs/Platform.md` §7 names it.
abstract final class _AppVersion {
  const _AppVersion._();

  /// Semver + build, matching `pubspec.yaml` `version:`.
  static const String display = '1.0.0 (1)';
}

/// A titled group of rows with the standard card treatment.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.border),
        boxShadow: AppElevation.raised(colors),
      ),
      // ClipBehaviour via the decoration's radius: a row's ink splash would
      // otherwise paint square corners over the rounded card.
      child: ClipRRect(
        borderRadius: AppRadius.borderLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// A hairline between rows inside a group.
class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    indent: AppSpacing.lg,
    color: AppThemeColors.of(context).border,
  );
}

/// A small uppercase section label above a group.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: colors.textSecondary, letterSpacing: 0.8),
      ),
    );
  }
}

/// How a [_ChoiceRow] presents its options.
enum _ChoiceLayout {
  /// Opens a bottom sheet. Right for a long list (10 currencies).
  sheet,

  /// Inline segments. Right for two or three options the user compares.
  segmented,
}

/// One selectable option.
class _Choice<T> {
  const _Choice({required this.value, required this.label});

  final T value;
  final String label;
}

/// A settings row that picks one value from a small set.
///
/// Generic over `T`, and deliberately tolerant of a **null** value: "follow the
/// device" for the locale is a genuine choice, so the row cannot treat null as
/// "nothing selected" without making that option unreachable.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.body,
    this.layout = _ChoiceLayout.sheet,
  });

  /// Row label, or null when a section header already names the row.
  final String? label;

  /// Optional supporting line under the label.
  final String? body;

  final T value;
  final List<_Choice<T>> options;
  final ValueChanged<T> onChanged;
  final _ChoiceLayout layout;

  /// The option whose value equals [value], or null when nothing matches.
  _Choice<T>? get _selected {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (layout == _ChoiceLayout.segmented) return _buildSegmented(context);

    final colors = AppThemeColors.of(context);
    final selected = _selected;

    return InkWell(
      onTap: () => _openSheet(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppRowHeight.absoluteMinimum,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (label case final label?)
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: colors.textPrimary),
                      ),
                    if (body case final body?) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        body,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                selected?.label ?? '',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right, size: 20, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmented(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (label case final label?)
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: colors.textPrimary),
            ),
          if (label != null) const SizedBox(height: AppSpacing.md),
          SegmentedButton<int>(
            segments: <ButtonSegment<int>>[
              for (var i = 0; i < options.length; i++)
                ButtonSegment<int>(value: i, label: Text(options[i].label)),
            ],
            // Index-based selection so T may be nullable and need no equality
            // contract beyond `==` (which `CurrencyCode` etc. already have).
            selected: <int>{if (_selected != null) options.indexOf(_selected!)},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                onChanged(options[selection.first].value),
            style: ButtonStyle(
              textStyle: WidgetStatePropertyAll<TextStyle?>(
                Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final colors = AppThemeColors.of(context);
    final selected = _selected;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.radiusXl),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: AppSpacing.md),
            // The list must scroll. `mainAxisSize: min` sizes the sheet to its
            // content, but ten currencies are taller than a short phone: without
            // this the sheet overflows and the last rows are unreachable (and
            // Flutter paints the yellow-and-black overflow stripes in debug).
            // `shrinkWrap` inside a `Flexible` keeps the sheet only as tall as
            // it needs to be *up to* the available space.
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: <Widget>[
                  for (final option in options)
                    ListTile(
                      title: Text(option.label),
                      trailing: option.value == selected?.value
                          ? Icon(Icons.check, color: colors.brandPrimary)
                          : null,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        // Guard against a no-op save: re-picking the current
                        // value would still write four rows and show "Settings
                        // saved.", which reads like a bug.
                        if (option.value != value) onChanged(option.value);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// A row that navigates somewhere: optional leading widget, label, chevron.
///
/// The profile entry point lives in the About group rather than in a group of
/// its own: on a local-only build it *is* information about the app instance, and
/// giving a guest profile a top-level section would promise an account system
/// that does not exist yet.
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.label,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.trailingText,
  });

  final String label;
  final VoidCallback onTap;

  /// Shown before the label — the user's avatar, for the profile row.
  final Widget? leading;

  /// Optional supporting text below the label.
  final String? subtitle;

  /// Optional value text shown before the chevron.
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppRowHeight.absoluteMinimum,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                if (leading case final leading?) ...<Widget>[
                  leading,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: colors.textPrimary),
                      ),
                      if (subtitle case final subtitle?) ...<Widget>[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingText case final trailingText?) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    trailingText,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ],
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right, size: 20, color: colors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A read-only row: label on the left, value on the right.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppRowHeight.absoluteMinimum,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: colors.textPrimary),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
