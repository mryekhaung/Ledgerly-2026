import 'dart:math' as math;

import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_palette.dart';
import 'package:material_ui/material_ui.dart';

/// Draws an [AvatarConfig] into a square canvas.
///
/// Parts are painted in the order of [AvatarPart]: background, backdrop, head,
/// eyes, mouth. The whole thing is laid out on a **normalised 1.0 unit square**
/// and scaled to whatever size the caller asks for, so one painter serves the
/// 96 px profile avatar and the 200 px editor preview identically.
///
/// **Reading as a person, not as a smiley.** The obvious composition — a large
/// centred circle with two dot eyes and a smiling mouth — is the universal
/// emoji glyph, and at swatch size that is exactly what it looks like: a grid
/// of 🙂. Two things keep it on the side of "illustrated avatar":
///
/// * the figure is a **bust** (shoulders + a proportionate head) rather than a
///   floating ball, so the silhouette is a person rather than a face;
/// * the head is **off-centre and smaller** than the emoji's face-filling
///   circle, which leaves the background visible as a frame.
///
/// Both are composition choices, not decoration — changing either back to a
/// centred 56% circle is what reintroduces the emoji read.
///
/// Every index is clamped before use. The domain validates on write
/// (`AvatarConfig.isValid`), but the renderer is also reachable with a config
/// decoded from an older install, and a paint method that can throw would take
/// the whole frame down — a wrong-looking avatar is strictly better.
class AvatarPainter extends CustomPainter {
  /// Creates a painter for [config] using the colours in [colors].
  const AvatarPainter({required this.config, required this.colors});

  /// The composition to draw.
  final AvatarConfig config;

  /// The active theme's semantic colours — the palette resolves against these so
  /// dark mode gets contrast-corrected fills.
  final AppColors colors;

  /// Height of the head as a fraction of the canvas.
  ///
  /// Deliberately well under the emoji's face-filling circle: the background
  /// has to read *around* the figure, and a head that fills the frame is the
  /// single biggest contributor to the "this is a smiley" impression.
  static const double headHeight = 0.44;

  /// Where the head's centre sits, as a fraction of the canvas height.
  ///
  /// Above the canvas centre, because the bust below it takes up the rest. A
  /// vertically centred head is an emoji; a head sitting on shoulders is a
  /// portrait.
  static const double headCenterY = 0.44;

  /// Where the shoulders sit, as a fraction of the canvas height.
  static const double shoulderY = 0.80;

  @override
  void paint(Canvas canvas, Size size) {
    // Square canvas, centred: a non-square box would stretch the figure.
    final side = math.min(size.width, size.height);
    if (side <= 0) return;

    final origin = Offset((size.width - side) / 2, (size.height - side) / 2);
    final rect = Rect.fromLTWH(origin.dx, origin.dy, side, side);

    canvas
      ..save()
      ..clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(side * 0.22)));

    final background = AvatarPalette.resolve(
      colors,
      AvatarCatalog
          .backgroundColors[config.backgroundColorIndex.clamp(
            0,
            AvatarCatalog.backgroundColors.length - 1,
          )]
          .palette,
    );

    _paintBackground(canvas, rect, background);
    _paintBackdrop(canvas, rect, background);
    _paintShoulders(canvas, rect, background);
    _paintShape(canvas, rect, background);
    _paintEyes(canvas, rect);
    _paintMouth(canvas, rect);

    canvas.restore();
  }

  /// The full-bleed backdrop fill.
  void _paintBackground(Canvas canvas, Rect rect, Color background) {
    canvas.drawRect(rect, Paint()..color = background);
  }

  /// The decorative shape behind the figure.
  ///
  /// Always drawn in the **background's own family** (`AvatarPalette.headFor`)
  /// rather than the option's palette slot: a backdrop in an unrelated hue is
  /// what produced the grey square behind the head in earlier builds. The slot
  /// is still recorded on each option — it is part of the persisted catalogue —
  /// but the renderer derives the tint so the avatar stays one palette.
  void _paintBackdrop(Canvas canvas, Rect rect, Color background) {
    final option =
        AvatarCatalog.backdrops[config.backdropIndex.clamp(
          0,
          AvatarCatalog.backdrops.length - 1,
        )];
    if (option.kind == BackdropKind.none) return;

    final tint = AvatarPalette.headFor(colors, background);
    final paint = Paint()
      ..color = tint.withValues(alpha: colors.isDark ? 0.35 : 0.45)
      ..style = PaintingStyle.fill;

    switch (option.kind) {
      case BackdropKind.none:
        break;
      case BackdropKind.circle:
        canvas.drawCircle(
          Offset(rect.left + rect.width * 0.70, rect.top + rect.height * 0.26),
          rect.width * 0.30,
          paint,
        );
      case BackdropKind.stripes:
        // Two rounded bars at a diagonal, for a bit of motion.
        final barPaint = Paint()
          ..color = tint.withValues(alpha: colors.isDark ? 0.28 : 0.38)
          ..style = PaintingStyle.fill;
        for (var i = 0; i < 2; i++) {
          final y = rect.top + rect.height * (0.20 + i * 0.15);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                rect.left + rect.width * 0.10,
                y,
                rect.width * 0.80,
                rect.height * 0.07,
              ),
              Radius.circular(rect.height * 0.035),
            ),
            barPaint,
          );
        }
      case BackdropKind.ring:
        canvas.drawCircle(
          Offset(rect.center.dx, rect.top + rect.height * 0.38),
          rect.width * 0.33,
          Paint()
            ..color = tint.withValues(alpha: colors.isDark ? 0.4 : 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = rect.width * 0.045,
        );
    }
  }

  /// The shoulder arc under the head.
  ///
  /// This is what turns "a ball with a face" into a figure. It is painted in the
  /// same tint as the head so the two read as one silhouette, and it is clipped
  /// by the rounded square the caller drew — the shoulders should run off the
  /// bottom edge like a portrait crop, not float as an ellipse.
  void _paintShoulders(Canvas canvas, Rect rect, Color background) {
    final head = AvatarPalette.headFor(colors, background);
    final bodyTop = rect.top + rect.height * shoulderY;
    // A wide, shallow arc: the top of a torso, not a second head.
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        rect.left + rect.width * 0.12,
        bodyTop,
        rect.width * 0.76,
        rect.height * 0.60,
      ),
      Radius.circular(rect.width * 0.34),
    );

    canvas
      ..drawRRect(body, Paint()..color = head)
      ..drawRRect(
        body,
        Paint()
          ..color = AvatarPalette.rimFor(colors)
          ..style = PaintingStyle.stroke
          ..strokeWidth = rect.width * 0.012,
      );
  }

  /// The head silhouette, with a rim so it separates from the background.
  void _paintShape(Canvas canvas, Rect rect, Color background) {
    final option = AvatarCatalog
        .shapes[config.shapeIndex.clamp(0, AvatarCatalog.shapes.length - 1)];
    final head = AvatarPalette.headFor(colors, background);
    final fill = Paint()..color = head;
    final rim = Paint()
      ..color = AvatarPalette.rimFor(colors)
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.012;

    // Smaller than the emoji's face-filling circle and lifted off the canvas
    // centre, so the background reads as a frame around the figure.
    final box = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.top + rect.height * headCenterY),
      width: rect.width * headHeight,
      height: rect.height * headHeight,
    );

    switch (option.kind) {
      case ShapeKind.circle:
        canvas
          ..drawCircle(box.center, box.width / 2, fill)
          ..drawCircle(box.center, box.width / 2, rim);
      case ShapeKind.roundedSquare:
        final square = RRect.fromRectAndRadius(
          box,
          Radius.circular(box.width * 0.30),
        );
        canvas
          ..drawRRect(square, fill)
          ..drawRRect(square, rim);
      case ShapeKind.teardrop:
        // Wider at the top: a circle for the crown, tapering to a point below.
        final path = Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(box.center.dx, box.top + box.height * 0.34),
              width: box.width,
              height: box.height * 0.72,
            ),
          );
        canvas
          ..drawPath(path, fill)
          ..drawPath(path, rim);
      case ShapeKind.hexagon:
        final path = Path();
        for (var i = 0; i < 6; i++) {
          // -90° start so the hexagon sits flat-topped rather than pointy.
          final angle = (math.pi / 3) * i - math.pi / 2;
          final point = Offset(
            box.center.dx + math.cos(angle) * box.width / 2,
            box.center.dy + math.sin(angle) * box.height / 2,
          );
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas
          ..drawPath(path, fill)
          ..drawPath(path, rim);
    }
  }

  /// The eye pair.
  ///
  /// Tied to the head box rather than to the canvas: the features have to move
  /// with the head when it is resized, or a smaller head would end up with eyes
  /// floating below its chin.
  void _paintEyes(Canvas canvas, Rect rect) {
    final option = AvatarCatalog
        .eyes[config.eyesIndex.clamp(0, AvatarCatalog.eyes.length - 1)];
    final ink = AvatarPalette.inkFor(colors);

    // Head geometry, repeated from `_paintShape` so the face lands on the head.
    final headTop = rect.top + rect.height * (headCenterY - headHeight / 2);
    final headWidth = rect.width * headHeight;
    final inkAlpha = colors.isDark ? 1.0 : 0.86;

    final eyeY = headTop + headWidth * 0.40;
    final leftX = rect.center.dx - headWidth * 0.20;
    final rightX = rect.center.dx + headWidth * 0.20;
    final radius = headWidth * 0.075;

    final fill = Paint()..color = ink.withValues(alpha: inkAlpha);
    final stroke = Paint()
      ..color = ink.withValues(alpha: inkAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = headWidth * 0.062
      ..strokeCap = StrokeCap.round;

    switch (option.kind) {
      case EyesKind.dots:
        canvas
          ..drawCircle(Offset(leftX, eyeY), radius, fill)
          ..drawCircle(Offset(rightX, eyeY), radius, fill);
      case EyesKind.lines:
        for (final x in <double>[leftX, rightX]) {
          canvas.drawLine(
            Offset(x - radius * 1.2, eyeY),
            Offset(x + radius * 1.2, eyeY),
            stroke,
          );
        }
      case EyesKind.happy:
        // Upward arcs: the control point above the endpoints makes a smile-eye.
        for (final x in <double>[leftX, rightX]) {
          canvas.drawPath(
            Path()
              ..moveTo(x - radius * 1.3, eyeY + radius * 0.5)
              ..quadraticBezierTo(
                x,
                eyeY - radius * 1.1,
                x + radius * 1.3,
                eyeY + radius * 0.5,
              ),
            stroke,
          );
        }
      case EyesKind.sparkle:
        for (final x in <double>[leftX, rightX]) {
          canvas
            ..drawCircle(Offset(x, eyeY), radius, fill)
            // A small glint in the upper-left of each pupil.
            ..drawCircle(
              Offset(x - radius * 0.35, eyeY - radius * 0.35),
              radius * 0.32,
              Paint()..color = AvatarPalette.eyeHighlightFor(colors),
            );
        }
    }
  }

  /// The mouth.
  void _paintMouth(Canvas canvas, Rect rect) {
    final option = AvatarCatalog
        .mouths[config.mouthIndex.clamp(0, AvatarCatalog.mouths.length - 1)];
    final ink = AvatarPalette.inkFor(colors);

    final headTop = rect.top + rect.height * (headCenterY - headHeight / 2);
    final headWidth = rect.width * headHeight;
    final inkAlpha = colors.isDark ? 1.0 : 0.86;

    final mouthY = headTop + headWidth * 0.66;
    final halfWidth = headWidth * 0.15;

    final stroke = Paint()
      ..color = ink.withValues(alpha: inkAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = headWidth * 0.062
      ..strokeCap = StrokeCap.round;

    switch (option.kind) {
      case MouthKind.smile:
        canvas.drawPath(
          Path()
            ..moveTo(rect.center.dx - halfWidth, mouthY - headWidth * 0.022)
            ..quadraticBezierTo(
              rect.center.dx,
              mouthY + headWidth * 0.080,
              rect.center.dx + halfWidth,
              mouthY - headWidth * 0.022,
            ),
          stroke,
        );
      case MouthKind.neutral:
        canvas.drawLine(
          Offset(rect.center.dx - halfWidth, mouthY),
          Offset(rect.center.dx + halfWidth, mouthY),
          stroke,
        );
      case MouthKind.dot:
        canvas.drawCircle(
          Offset(rect.center.dx, mouthY + headWidth * 0.022),
          headWidth * 0.058,
          Paint()..color = ink.withValues(alpha: inkAlpha),
        );
      case MouthKind.frown:
        canvas.drawPath(
          Path()
            ..moveTo(rect.center.dx - halfWidth, mouthY + headWidth * 0.040)
            ..quadraticBezierTo(
              rect.center.dx,
              mouthY - headWidth * 0.062,
              rect.center.dx + halfWidth,
              mouthY + headWidth * 0.040,
            ),
          stroke,
        );
    }
  }

  /// Repaints only when the composition or the scheme changes.
  @override
  bool shouldRepaint(AvatarPainter oldDelegate) =>
      oldDelegate.config != config || oldDelegate.colors != colors;
}
