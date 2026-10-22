import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// A labelled, tappable form row in the filled style of `docs/Design.md` §5.8.
///
/// The spec is explicit that inputs are *filled* — label at the top in
/// `label`/`textSecondary`, value below in `body`/`textPrimary`, on a
/// `surfaceSubtle` container with `radius.md` — and explicitly not Material's
/// floating-label outline box. Every row on the transaction form (category,
/// date, note) is one of these, so the shape is defined once.
///
/// [onTap] makes the whole row a single hit target, which is why the row is
/// 56 px tall and never wraps: a field whose value is chosen on another page
/// should be tappable anywhere, not only on its text.
class FormFieldSurface extends StatefulWidget {
  /// Creates a filled form row.
  const FormFieldSurface({
    required this.label,
    this.value,
    this.valueWidget,
    this.leading,
    this.trailing,
    this.onTap,
    this.isError = false,
    super.key,
  });

  /// The field's label, shown above the value.
  final String label;

  /// The field's current value as text, or null to show `placeholder` styling.
  final String? value;

  /// A richer value widget, used instead of [value] when the value is not plain
  /// text (e.g. a gem beside a category name).
  final Widget? valueWidget;

  /// Optional leading widget, vertically centred in the row.
  final Widget? leading;

  /// Optional trailing widget, e.g. a disclosure chevron.
  final Widget? trailing;

  /// Called when the row is tapped. Null renders the row as non-interactive,
  /// which is what a read-only field wants.
  final VoidCallback? onTap;

  /// Paints the error treatment: a `warningSubtle` fill with a `warning` hairline
  /// (`docs/Design.md` §5.8).
  final bool isError;

  @override
  State<FormFieldSurface> createState() => _FormFieldSurfaceState();
}

class _FormFieldSurfaceState extends State<FormFieldSurface> {
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
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final resolvedValue = widget.value;
    // A row shows a value when it has *either* a rich widget or plain text.
    // `??` would be wrong here: it yields the Widget, not a bool.
    final showValue = widget.valueWidget != null || resolvedValue != null;

    final content = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: widget.isError ? colors.warningSubtle : colors.surfaceSubtle,
        borderRadius: AppRadius.borderMd,
        border: widget.isError ? Border.all(color: colors.warning) : null,
      ),
      child: Row(
        children: <Widget>[
          if (widget.leading case final leadingWidget?) ...<Widget>[
            leadingWidget,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (showValue) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  widget.valueWidget ??
                      Text(
                        resolvedValue ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                ],
              ],
            ),
          ),
          if (widget.trailing case final trailingWidget?) ...<Widget>[
            const SizedBox(width: AppSpacing.md),
            trailingWidget,
          ],
        ],
      ),
    );

    if (widget.onTap == null) return content;

    if (AppPlatform.resolve().usesCupertino) {
      // iOS: quiet opacity press feedback, not an ink ripple (docs/Platform.md §3).
      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: () {
          AppFeedback.selection();
          widget.onTap?.call();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.92 : 1.0,
          duration: AppMotion.micro,
          curve: AppMotion.standard,
          child: content,
        ),
      );
    }

    // Material/Web keep an ink response over the same rounded form surface.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppFeedback.selection();
          widget.onTap?.call();
        },
        borderRadius: AppRadius.borderMd,
        child: content,
      ),
    );
  }
}

/// The disclosure chevron used at the trailing edge of a navigable field.
///
/// Mirrored on iOS so it always points in the reading direction — a chevron is
/// a direction glyph, not decoration (`docs/Platform.md` §3).
class FormFieldChevron extends StatelessWidget {
  /// Creates a chevron.
  const FormFieldChevron({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Icon(
      AppIcons.chevronRight,
      size: 20,
      color: colors.textTertiary,
      textDirection: Directionality.of(context),
    );
  }
}

/// An inline validation message, rendered under the field it belongs to.
///
/// Positioned below in `caption` with `warning` text, per `docs/Design.md` §5.8,
/// rather than `colorScheme.error`: the design system has its own warning token
/// and using the M3 error colour here would drift from the palette.
class FormFieldError extends StatelessWidget {
  /// Creates an inline error message.
  const FormFieldError({required this.message, super.key});

  /// The already-localized message.
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(color: colors.warning),
      ),
    );
  }
}
