import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/money/money_formatter.dart';
import 'package:material_ui/material_ui.dart';

/// Which typographic slot an amount should render in.
///
/// Maps to the amount styles in [AppTypography], so call sites never pass a
/// hand-built `TextStyle` (docs/Design.md §5.4).
enum AmountStyle {
  /// Hero amount — summary card, keypad display (40 px).
  display,

  /// Selected-day / section total (28 px).
  large,

  /// List-row amount (17 px). The default.
  row,
}

/// Renders a [Money] as localized, sign-coloured, tabular text.
///
/// **The only widget allowed to format money** (docs/Design.md §5.4). Formatting
/// is delegated to [MoneyFormatter]; this widget only chooses style and colour.
///
/// Colour rule (docs/Design.md §2.4):
///   * `signed: true`  → expense gets `moneyOut`, income gets `moneyIn`, and a
///     `−`/`+` is prepended.
///   * `signed: false` → always `textPrimary`, for totals whose direction is
///     implied by the surrounding label.
///
/// Tabular figures come from the style tokens, so a column of amounts stays
/// aligned and digits don't jitter when a value animates.
class AmountText extends StatelessWidget {
  /// Renders [money].
  const AmountText(
    this.money, {
    this.style = AmountStyle.row,
    this.signed = true,
    this.format = MoneyFormat.symbol,
    this.color,
    this.textAlign,
    this.maxLines = 1,
    this.semanticsLabel,
    this.formatter,
    super.key,
  });

  /// The amount to render.
  final Money money;

  /// Typographic slot.
  final AmountStyle style;

  /// Whether to colour by sign and show a `+`/`−`. See the class docs.
  final bool signed;

  /// Symbol placement.
  final MoneyFormat format;

  /// Overrides the sign-derived colour. Use sparingly — the default exists so
  /// that expense/income colouring is automatic rather than remembered.
  final Color? color;

  /// Text alignment. Null lets the parent decide (avoids forcing `left`, which
  /// would break RTL later — docs/Design.md §7).
  final TextAlign? textAlign;

  /// Maximum lines. Amounts should never wrap, so the default is 1.
  final int maxLines;

  /// Accessible label. Defaults to a spelled-out form including the sign, since
  /// the visual `−` glyph reads poorly through a screen reader.
  final String? semanticsLabel;

  /// Formatter override, for tests and for the import/export previews that need
  /// a fixed locale.
  final MoneyFormatter? formatter;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final activeFormatter = formatter ?? MoneyFormatter(locale: _localeOf(context));

    final text = activeFormatter.format(
      money,
      format: format,
      showSign: signed,
    );

    return Text(
      text,
      style: _textStyle(colors).copyWith(color: color ?? _resolveColor(colors)),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      semanticsLabel: semanticsLabel ?? _semanticsFor(money, activeFormatter),
    );
  }

  TextStyle _textStyle(AppColors colors) => switch (style) {
    AmountStyle.display => AppTypography.displayAmount,
    AmountStyle.large => AppTypography.amountLarge,
    AmountStyle.row => AppTypography.amount,
  };

  Color _resolveColor(AppColors colors) {
    if (!signed) return colors.textPrimary;
    if (money.isZero) return colors.textPrimary;
    return money.isNegative ? colors.moneyOut : colors.moneyIn;
  }

  /// Spoken form: the visual `−` glyph reads poorly through a screen reader, so
  /// spell the direction out and pair it with the *magnitude* (no second sign).
  String _semanticsFor(Money money, MoneyFormatter activeFormatter) {
    final magnitude = activeFormatter.formatMagnitude(money);
    if (money.isZero) return magnitude;
    final direction = money.isNegative ? 'minus ' : 'plus ';
    return '$direction$magnitude';
  }

  String _localeOf(BuildContext context) =>
      Localizations.maybeLocaleOf(context)?.toLanguageTag() ?? 'en';
}
