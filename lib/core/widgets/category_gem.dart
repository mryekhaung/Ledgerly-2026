import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/features/categories/presentation/category_catalog.dart';
import 'package:material_ui/material_ui.dart';

/// Sizes a [CategoryGem] can render at (`docs/Design.md` §5.3).
enum CategoryGemSize {
  /// 20 — inline beside a dense list row.
  sm(20, 11),

  /// 28 — the default list-row leading.
  md(28, 15),

  /// 40 — the form preview and section headers.
  lg(40, 22),

  /// 56 — the day summary's hero gem.
  xl(56, 31);

  const CategoryGemSize(this.diameter, this.iconSize);

  /// The gem's diameter in logical pixels.
  final double diameter;

  /// The glyph size — 55% of [diameter], rounded (`docs/Design.md` §5.3).
  final double iconSize;
}

/// The coloured circle that stands for a category.
///
/// The glyph is drawn over a solid fill of the category's own colour, so a
/// category is identifiable before its name is read. Colour is supplied as a
/// plain ARGB int (the stored form) rather than a `Color`, so no call site has
/// to remember the conversion.
///
/// **Never** place one on a background of the same hue (`docs/Design.md` §5.3) —
/// callers are responsible for that, since this widget cannot know its parent.
class CategoryGem extends StatelessWidget {
  /// Creates a gem.
  const CategoryGem({
    required this.colorValue,
    this.iconKey,
    this.size = CategoryGemSize.md,
    this.semanticsLabel,
    super.key,
  });

  /// The category's stored colour, as ARGB.
  final int colorValue;

  /// The category's stable icon key. An unknown key falls back rather than
  /// rendering nothing (`CategoryIcons.iconFor`).
  final String? iconKey;

  /// Render size.
  final CategoryGemSize size;

  /// Localized category name for screen readers. Omitted means decorative.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final hasColor = CategoryPalette.isValid(colorValue);
    final gemColor = hasColor
        ? Color(colorValue)
        : AppThemeColors.of(context).brandSubtle;

    return Semantics(
      label: semanticsLabel,
      // The glyph carries no information a screen reader needs beyond the name,
      // so it is excluded to avoid announcing "tag" after every row.
      excludeSemantics: semanticsLabel != null,
      child: Container(
        width: size.diameter,
        height: size.diameter,
        decoration: BoxDecoration(
          color: gemColor,
          shape: BoxShape.circle,
          // A hairline keeps a pale gem from dissolving into a pale surface.
          border: hasColor
              ? null
              : Border.all(color: AppThemeColors.of(context).border),
        ),
        alignment: Alignment.center,
        child: Icon(
          CategoryIcons.iconFor(iconKey),
          size: size.iconSize,
          // Fixed white on a saturated fill; the palette values are all dark
          // enough that this stays legible.
          color: Colors.white,
        ),
      ),
    );
  }
}

/// A `CategoryGem` with the category's name beside it — the list-row leading.
///
/// Bundled because the two are always used together and the text style must
/// match the gem size; separate widgets would let a `lg` gem sit next to `sm`
/// text.
class CategoryGemLabel extends StatelessWidget {
  /// Creates a gem plus label.
  const CategoryGemLabel({
    required this.name,
    required this.colorValue,
    this.iconKey,
    this.size = CategoryGemSize.md,
    this.subtitle,
    super.key,
  });

  /// The category name.
  final String name;

  /// The category's stored colour, as ARGB.
  final int colorValue;

  /// The category's stable icon key.
  final String? iconKey;

  /// Gem size; the text scales with it.
  final CategoryGemSize size;

  /// Optional secondary line.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final isLarge = size.index >= CategoryGemSize.lg.index;

    return Row(
      children: <Widget>[
        CategoryGem(
          colorValue: colorValue,
          iconKey: iconKey,
          size: size,
          semanticsLabel: name,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (isLarge
                            ? theme.textTheme.titleMedium
                            : theme.textTheme.bodyLarge)
                        ?.copyWith(color: colors.textPrimary),
              ),
              if (subtitle case final subtitle?) ...<Widget>[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
