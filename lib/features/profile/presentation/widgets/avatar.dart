import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_painter.dart';
import 'package:material_ui/material_ui.dart';

/// Renders an [AvatarConfig] at a given size.
///
/// The single entry point for drawing an avatar anywhere in the app — the profile
/// list, the editor preview, and every option swatch. Going through one widget is
/// what keeps those three from drifting apart as the painter gains parts
/// (`docs/Agent.md` §6: one widget per visual concept).
class Avatar extends StatelessWidget {
  /// Creates an avatar.
  const Avatar({
    required this.config,
    this.size = 48,
    this.semanticLabel,
    super.key,
  });

  /// The composition to draw.
  final AvatarConfig config;

  /// The edge length of the square. The avatar is always square; a non-square
  /// box would stretch the face.
  final double size;

  /// An optional accessibility label.
  ///
  /// Null leaves the avatar decorative — correct for a swatch in a picker, where
  /// announcing "avatar" per option is noise. The profile surfaces pass a label
  /// because there the avatar *is* the user's identity.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    final painted = CustomPaint(
      size: Size.square(size),
      painter: AvatarPainter(config: config, colors: colors),
      // The painter never paints outside its box, and marking the layer opaque
      // lets the compositor skip blending it against what's behind.
      isComplex: false,
    );

    if (semanticLabel == null) return painted;

    return Semantics(label: semanticLabel, image: true, child: painted);
  }
}
