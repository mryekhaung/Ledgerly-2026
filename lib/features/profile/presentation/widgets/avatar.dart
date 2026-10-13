import 'package:flutter_svg/flutter_svg.dart';
import 'package:ledgerly/features/profile/data/datasources/avatar_svg_composer.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:material_ui/material_ui.dart';

export 'package:ledgerly/features/profile/data/datasources/avatar_svg_composer.dart'
    show AvatarShape;

/// Renders an [AvatarConfig] as an Open Peeps SVG vector graphic at a given size.
///
/// Spec: `docs/Avatar.md` §5.
/// Wrapped in a [RepaintBoundary], clipped to a circle or squircle, and memoized
/// via [AvatarSvgComposer].
class Avatar extends StatelessWidget {
  /// Creates an avatar.
  const Avatar({
    required this.config,
    this.size = 48,
    this.shape = AvatarShape.circle,
    this.semanticLabel,
    this.thumbnailGroup,
    this.thumbnailId,
    super.key,
  });

  /// The composition to draw.
  final AvatarConfig config;

  /// The edge length of the square box.
  final double size;

  /// The clipping shape (circle by default, or squircle).
  final AvatarShape shape;

  /// An optional accessibility label.
  final String? semanticLabel;

  /// Optional group name when used as a part thumbnail in the editor.
  final String? thumbnailGroup;

  /// Optional part ID when used as a part thumbnail in the editor.
  final String? thumbnailId;

  @override
  Widget build(BuildContext context) {
    final String? cachedSvg;
    final Future<String> svgFuture;
    if (thumbnailGroup != null && thumbnailId != null) {
      cachedSvg = AvatarSvgComposer.instance.getCachedPartThumbnail(
        group: thumbnailGroup!,
        id: thumbnailId!,
        config: config,
      );
      svgFuture = AvatarSvgComposer.instance.composePartThumbnail(
        group: thumbnailGroup!,
        id: thumbnailId!,
        config: config,
      );
    } else {
      cachedSvg = AvatarSvgComposer.instance.getCached(config, shape: shape);
      svgFuture = AvatarSvgComposer.instance.compose(config, shape: shape);
    }

    final Widget content;
    if (cachedSvg != null) {
      content = SvgPicture.string(cachedSvg, width: size, height: size);
    } else {
      content = FutureBuilder<String>(
        future: svgFuture,
        builder: (context, snapshot) {
          final svg = snapshot.data;
          if (svg != null) {
            return SvgPicture.string(svg, width: size, height: size);
          }
          return SizedBox.square(
            dimension: size,
            child: ColoredBox(color: Color(config.colors.background)),
          );
        },
      );
    }

    final clipped = RepaintBoundary(
      child: ClipPath(clipper: _AvatarClipper(shape), child: content),
    );

    if (semanticLabel == null) return clipped;

    return Semantics(label: semanticLabel, image: true, child: clipped);
  }
}

class _AvatarClipper extends CustomClipper<Path> {
  const _AvatarClipper(this.shape);

  final AvatarShape shape;

  @override
  Path getClip(Size size) {
    final rect = Offset.zero & size;
    return switch (shape) {
      AvatarShape.circle => Path()..addOval(rect),
      AvatarShape.squircle =>
        Path()..addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.28)),
        ),
    };
  }

  @override
  bool shouldReclip(covariant _AvatarClipper oldClipper) =>
      oldClipper.shape != shape;
}
