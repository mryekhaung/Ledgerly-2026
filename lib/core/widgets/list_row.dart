import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// The atomic list unit (docs/Design.md §5.6).
///
/// * Height: 64 px (single line) / 76 px (two line). Never shorter than 56 px.
/// * Layout: `[leading 40] [gap lg] [title/subtitle flex] [gap md] [trailing amount/widget]`
/// * Padding: horizontal `lg` (16 px), vertical `md` (12 px).
/// * Separator: 1 px `border`, inset from the left by `72 px` (`lg + 40 + lg`),
///   aligning directly with the text column rather than the edge.
/// * Press state: full-bleed `surfaceSunken` wash over `micro`, plus light haptic.
class ListRow extends StatefulWidget {
  /// Creates a [ListRow].
  const ListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.amount,
    this.isExpense,
    this.onTap,
    this.showDivider = false,
    this.semanticsLabel,
    super.key,
  });

  /// Primary row title.
  final Widget title;

  /// Optional second-line subtitle.
  final Widget? subtitle;

  /// Leading slot (e.g. [CategoryGem] or icon). Allocated a fixed 40 px width.
  final Widget? leading;

  /// Custom trailing slot. If [amount] is provided, [amount] takes precedence.
  final Widget? trailing;

  /// Optional money amount rendered via [AmountText].
  final Money? amount;

  /// Whether the [amount] is an expense (negative/moneyOut) or income (positive/moneyIn).
  final bool? isExpense;

  /// Tap callback. Adds interactive press feedback and selection haptic.
  final VoidCallback? onTap;

  /// Whether to render a bottom 1 px divider inset by 72 px.
  final bool showDivider;

  /// Optional accessibility label.
  final String? semanticsLabel;

  @override
  State<ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<ListRow> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final isTwoLine = widget.subtitle != null;
    final minHeight = isTwoLine
        ? AppRowHeight.twoLine
        : AppRowHeight.singleLine;

    // Resolve trailing widget: amount takes priority if supplied.
    Widget? trailingWidget = widget.trailing;
    if (widget.amount != null) {
      trailingWidget = AmountText(
        widget.amount!,
        signed: widget.isExpense != null,
      );
    }

    final rowContent = Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      color: _isPressed ? colors.surfaceSunken : Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (widget.leading != null) ...<Widget>[
            SizedBox(
              width: 40,
              height: 40,
              child: Center(child: widget.leading),
            ),
            const SizedBox(width: AppSpacing.lg),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DefaultTextStyle(
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: widget.title,
                ),
                if (widget.subtitle != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  DefaultTextStyle(
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: widget.subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (trailingWidget != null) ...<Widget>[
            const SizedBox(width: AppSpacing.md),
            trailingWidget,
          ],
        ],
      ),
    );

    Widget content = widget.onTap == null
        ? rowContent
        : GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: () {
              AppFeedback.selection();
              widget.onTap?.call();
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: AppMotion.micro,
              curve: AppMotion.standard,
              color: _isPressed ? colors.surfaceSunken : Colors.transparent,
              child: rowContent,
            ),
          );

    if (widget.showDivider) {
      // Separator: 1 px border, inset from the left by lg + 40 + lg = 72 px (docs/Design.md §5.6).
      const leftInset = AppSpacing.lg + 40.0 + AppSpacing.lg;
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          content,
          Padding(
            padding: const EdgeInsets.only(left: leftInset),
            child: Divider(height: 1, thickness: 1, color: colors.border),
          ),
        ],
      );
    }

    if (widget.semanticsLabel != null || widget.onTap != null) {
      content = Semantics(
        label: widget.semanticsLabel,
        button: widget.onTap != null,
        child: content,
      );
    }

    return content;
  }
}
