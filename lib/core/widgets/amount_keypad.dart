import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:material_ui/material_ui.dart';

/// The amount keypad: a display row plus a numeric tray.
///
/// A dedicated tray rather than the OS keyboard (`docs/Design.md` §5.8): an
/// amount is digits, one optional point, and a backspace — and the OS numeric
/// keyboard varies by platform, offers keys that cannot be used, and covers the
/// category and date the user needs to see while entering.
///
/// Every entry rule lives in `AmountEntry` (pure Dart, unit-tested); this widget
/// only renders and dispatches.
class AmountKeypad extends StatelessWidget {
  /// Creates a keypad.
  const AmountKeypad({
    required this.entryBuffer,
    required this.currency,
    required this.onDigit,
    required this.onDecimalPoint,
    required this.onBackspace,
    this.leadingLabel,
    this.gemColorValue,
    this.gemIconKey,
    this.semanticsLabel,
    super.key,
  });

  /// The digits entered so far, e.g. `'12.5'`.
  final String entryBuffer;

  /// The currency the entry is denominated in — drives the decimal key's
  /// availability and the display's formatting.
  final CurrencyCode currency;

  /// Called with a single `0`–`9` when a digit key is pressed.
  final ValueChanged<String> onDigit;

  /// Called when the decimal key is pressed.
  final VoidCallback onDecimalPoint;

  /// Called when backspace is pressed.
  final VoidCallback onBackspace;

  /// Optional label above the amount — the chosen category's name.
  final String? leadingLabel;

  /// Optional gem colour, so the user sees which category they are filing under
  /// while entering the amount.
  final int? gemColorValue;

  /// Optional gem icon key.
  final String? gemIconKey;

  /// Localized accessibility label for the amount display.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      color: colors.surfaceSunken,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Display(
              entryBuffer: entryBuffer,
              currency: currency,
              leadingLabel: leadingLabel,
              gemColorValue: gemColorValue,
              gemIconKey: gemIconKey,
              semanticsLabel: semanticsLabel,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Column(
                children: <Widget>[
                  for (final row in _digitRows)
                    Row(
                      children: <Widget>[
                        for (final key in row)
                          Expanded(
                            child: _KeypadKey(
                              label: key,
                              currency: currency,
                              onTap: key == _backspaceKey
                                  ? onBackspace
                                  : () => onDigit(key),
                              isBackspace: key == _backspaceKey,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The tray layout, bottom row last. A nested list rather than a flat one so
  /// the four-per-row shape is data, not three near-identical `Row` calls.
  static const List<List<String>> _digitRows = <List<String>>[
    <String>['1', '2', '3'],
    <String>['4', '5', '6'],
    <String>['7', '8', '9'],
    <String>[decimalKey, '0', _backspaceKey],
  ];

  /// Sentinel for the decimal key inside [_digitRows].
  static const String decimalKey = '.';

  /// Sentinel for the backspace key inside [_digitRows].
  static const String _backspaceKey = '<';
}

/// The amount readout above the tray.
class _Display extends StatelessWidget {
  const _Display({
    required this.entryBuffer,
    required this.currency,
    this.leadingLabel,
    this.gemColorValue,
    this.gemIconKey,
    this.semanticsLabel,
  });

  final String entryBuffer;
  final CurrencyCode currency;
  final String? leadingLabel;
  final int? gemColorValue;
  final String? gemIconKey;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final hasEntry = entryBuffer.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          if (gemColorValue case final colorValue?) ...<Widget>[
            CategoryGem(
              colorValue: colorValue,
              iconKey: gemIconKey,
              size: CategoryGemSize.md,
              semanticsLabel: leadingLabel,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (leadingLabel case final label?)
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxs),
                // An empty buffer shows the currency's own zero rather than a
                // blank, so the display never looks like a missing value.
                AmountDisplay(
                  entryBuffer: hasEntry ? entryBuffer : null,
                  currency: currency,
                  semanticsLabel: semanticsLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the raw keypad buffer in the display amount style.
///
/// Distinct from `AmountText` because the buffer is *not* a `Money` — it is
/// mid-entry and may be `'12.'` or `'0'`. Parsing it just to render would format
/// a value the user has not finished typing, so this widget shows the digits
/// verbatim with the currency symbol beside them, and lets the committed
/// transaction render through `AmountText` once it is saved.
class AmountDisplay extends StatelessWidget {
  /// Creates a display for [entryBuffer], or the currency's zero when null.
  const AmountDisplay({
    required this.currency,
    this.entryBuffer,
    this.semanticsLabel,
    super.key,
  });

  /// The digits entered so far, or null/empty to show `0`.
  final String? entryBuffer;

  /// The currency to show the symbol for.
  final CurrencyCode currency;

  /// Localized accessibility label.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final buffer = entryBuffer;

    return Semantics(
      label: semanticsLabel,
      value: buffer == null || buffer.isEmpty ? '0' : buffer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Text(
            currency.symbol,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              buffer == null || buffer.isEmpty ? '0' : buffer,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.displaySmall?.copyWith(
                color: buffer == null || buffer.isEmpty
                    ? colors.textTertiary
                    : colors.textPrimary,
                // Tabular figures so the number does not jitter horizontally as
                // digits are added and removed.
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One key in the tray.
class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    required this.label,
    required this.currency,
    required this.onTap,
    this.isBackspace = false,
  });

  final String label;
  final CurrencyCode currency;
  final VoidCallback onTap;
  final bool isBackspace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    // The decimal key is inert for a zero-exponent currency (MMK, JPY, KRW):
    // there is no minor unit to enter, so a tap must not appear to work.
    final isInert = label == AmountKeypad.decimalKey && currency.exponent == 0;

    return SizedBox(
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInert ? null : onTap,
          child: Center(
            child: isBackspace
                ? Icon(
                    AppIcons.backspace,
                    size: 22,
                    color: colors.textPrimary,
                  )
                : Text(
                    label,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: isInert ? colors.textTertiary : colors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
