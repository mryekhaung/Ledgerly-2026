import 'package:material_ui/material_ui.dart';

/// The largest share of a row a trailing value may take before it ellipsizes.
///
/// `docs/Design.md` §8 requires every screen to survive 2× type at 360 px. In
/// rows shaped `[icon][label] … [value][menu]` the value is what has to give way
/// there — the label is `Expanded` and already absorbs whatever is left.
///
/// **Why a cap rather than `Flexible`.** A flex share is allocated at *every*
/// width, so it binds at 1× and on wide screens too, where the row already fits.
/// And because the label is `Expanded` (tight) it takes exactly its share while
/// a loose `Flexible` value takes only `min(intrinsic, share)` — so whenever the
/// value is narrower than its share the row is left with unused space and the
/// value is pulled off the right edge. A cap is inert until the row genuinely
/// cannot fit, which is what keeps 1× and wide layouts byte-identical to what
/// shipped.
///
/// 0.6 is a judgment call, not a measurement: it leaves the leading group 40 %
/// and is comfortably above what the values in the shipped fixtures need at 1×
/// (the widest account balance is ~46 % of its row, the widest budget status
/// pill ~47 %), so it does not bind until type doubles.
const double kTrailingValueMaxFraction = 0.6;

/// Lays out a `Row` and hands [builder] the width a trailing value may use.
///
/// Use it for a row whose last-but-one child is data or status that must not
/// overflow at 2× type, and wrap that child in a `ConstrainedBox` with the width
/// given here.
///
/// The `LayoutBuilder` has to wrap the *row*: placed inside it, the builder
/// would itself be a non-flex child and so be measured with an unbounded main
/// axis, reporting an infinite width. (If the row's own parent is unbounded the
/// cap comes out infinite too, which correctly makes it inert.)
class CappedRow extends StatelessWidget {
  /// Creates a [CappedRow].
  const CappedRow({
    required this.builder,
    this.fraction = kTrailingValueMaxFraction,
    super.key,
  });

  /// Builds the row, given the maximum width its trailing value may take.
  final Widget Function(BuildContext context, double trailingMaxWidth) builder;

  /// Override for rows whose trailing value is proportionally wider than
  /// [kTrailingValueMaxFraction] allows at 1×.
  final double fraction;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        builder(context, constraints.maxWidth * fraction),
  );
}
