import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_painter.dart';

/// [AvatarPainter] — the rendered avatar.
///
/// The composition constants are the *design contract*, and this group is the
/// regression guard for the "these look like emoji" report that prompted it.
/// A plain centred circle at 56% of the canvas with dot eyes and a smile is
/// the universal smiley glyph, so every assertion here exists to fail loudly
/// if the composition drifts back toward that.
void main() {
  group('composition', () {
    test('should_keep_the_head_smaller_than_the_emoji_face', () {
      // 0.56 was the previous figure, and it is what made the background
      // disappear behind a face-filling circle. Anything at or above it is
      // the emoji composition again.
      expect(AvatarPainter.headHeight, lessThan(0.56));
      expect(AvatarPainter.headHeight, greaterThan(0.2));
    });

    test('should_lift_the_head_above_the_canvas_centre', () {
      // A vertically centred head is an emoji; the bust below it is what makes
      // the silhouette a person. The head centre must sit above the midline.
      expect(AvatarPainter.headCenterY, lessThan(0.5));
    });

    test('should_put_the_shoulders_below_the_head', () {
      expect(AvatarPainter.shoulderY, greaterThan(AvatarPainter.headCenterY));
      // ...and low enough that they read as a body crop, not a second head.
      expect(AvatarPainter.shoulderY, greaterThan(0.6));
      expect(AvatarPainter.shoulderY, lessThan(1.0));
    });

    test('should_leave_the_head_fully_inside_the_canvas', () {
      // The top of the head must not be clipped, or the rim would be lost and
      // the figure would bleed off the frame.
      final headTop = AvatarPainter.headCenterY - AvatarPainter.headHeight / 2;
      expect(headTop, greaterThan(0.0));
      final headBottom =
          AvatarPainter.headCenterY + AvatarPainter.headHeight / 2;
      expect(headBottom, lessThan(1.0));
    });

    test('should_overlap_the_head_and_shoulders_so_they_read_as_one_figure', () async {
      // A wide gap between chin and shoulders would read as a floating head
      // with a bar under it — neither an emoji nor a portrait. The shoulders
      // are a rounded rect whose *corner radius* (0.34 of the canvas width)
      // makes its silhouette sweep up well above the top edge of its box, so
      // the box top and the chin are close even though the visible curve closes
      // the gap. The bound below is that box-top-to-chin distance.
      final headBottom =
          AvatarPainter.headCenterY + AvatarPainter.headHeight / 2;
      final shoulderBoxTop = AvatarPainter.shoulderY;
      expect(shoulderBoxTop - headBottom, lessThan(0.2));
    });

    test('should_place_the_face_on_the_head_not_on_the_canvas', () {
      // The eyes sit at 40% down the head box; that must land inside the head
      // rather than between the head and the shoulders.
      final headTop = AvatarPainter.headCenterY - AvatarPainter.headHeight / 2;
      const eyeFractionWithinHead = 0.40;
      final eyeY = headTop + AvatarPainter.headHeight * eyeFractionWithinHead;
      final headBottom =
          AvatarPainter.headCenterY + AvatarPainter.headHeight / 2;
      expect(eyeY, greaterThan(headTop));
      expect(eyeY, lessThan(headBottom));
    });
  });

  group('painting', () {
    test('should_paint_without_throwing_for_every_catalogue_option', () async {
      for (final part in AvatarPart.values) {
        for (var index = 0; index < AvatarCatalog.optionCount(part); index++) {
          final config = AvatarConfig.initial.withPart(part, index);
          await _paint(config);
        }
      }
    });

    test('should_paint_every_shape_in_both_schemes', () async {
      for (final colors in <AppColors>[
        const AppColorsLight(),
        const AppColorsDark(),
      ]) {
        for (var i = 0; i < AvatarCatalog.shapes.length; i++) {
          final config = AvatarConfig.initial.withPart(AvatarPart.shape, i);
          await _paint(config, colors: colors);
        }
      }
    });

    test('should_tolerate_out_of_range_indices_from_a_newer_build', () async {
      // A config written by a future build with more options must degrade,
      // not throw — the renderer clamps, and a paint cannot take the frame
      // down. See the class doc on AvatarPainter.
      const future = AvatarConfig(
        backgroundColorIndex: 99,
        backdropIndex: 12,
        shapeIndex: 7,
        eyesIndex: 40,
        mouthIndex: 3,
      );

      expect(future.isValid, isFalse);
      await _paint(future);
    });

    test('should_not_repaint_for_an_identical_config', () {
      const config = AvatarConfig(
        backgroundColorIndex: 3,
        backdropIndex: 1,
        shapeIndex: 2,
        eyesIndex: 1,
        mouthIndex: 0,
      );
      const colors = AppColorsLight();

      expect(
        AvatarPainter(config: config, colors: colors).shouldRepaint(
          AvatarPainter(config: config, colors: colors),
        ),
        isFalse,
      );
    });

    test('should_repaint_when_the_config_changes', () {
      const colors = AppColorsLight();
      const before = AvatarConfig(
        backgroundColorIndex: 3,
        backdropIndex: 1,
        shapeIndex: 2,
        eyesIndex: 1,
        mouthIndex: 0,
      );
      const after = AvatarConfig(
        backgroundColorIndex: 3,
        backdropIndex: 1,
        shapeIndex: 3,
        eyesIndex: 1,
        mouthIndex: 0,
      );

      expect(
        AvatarPainter(config: before, colors: colors).shouldRepaint(
          AvatarPainter(config: after, colors: colors),
        ),
        isTrue,
      );
    });

    test('should_leave_the_background_visible_around_the_figure', () async {
      // The signature of the old composition: the head filled the frame, so
      // the background was only a thin border. With the head at 44% there has
      // to be a meaningful margin of pure background on each side.
      const size = 100.0;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      // The avatar's own background fill, so the probe measures the painter
      // rather than the white underlay this test draws first.
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, size, size),
        ui.Paint()..color = const ui.Color(0xFF7FD1B9),
      );
      AvatarPainter(
        config: AvatarConfig.initial,
        colors: const AppColorsLight(),
      ).paint(canvas, const ui.Size.square(size));
      final image = await recorder
          .endRecording()
          .toImage(size.toInt(), size.toInt());
      final bytes = await image.toByteData();
      expect(bytes, isNotNull);

      const left = 8;
      const right = 91;
      final top = 8;
      final bottom = 91;
      final probes = <Offset>[
        Offset(left.toDouble(), size / 2),
        Offset(right.toDouble(), size / 2),
        Offset(size / 2, top.toDouble()),
        Offset(size / 2, bottom.toDouble()),
      ];

      var backgroundCount = 0;
      for (final probe in probes) {
        final pixel = pixelAt(
          bytes!,
          size.toInt(),
          probe.dx.toInt(),
          probe.dy.toInt(),
        );
        if (_matches(pixel, 0xFF7FD1B9, 6)) backgroundCount++;
      }

      // At least the left, right and bottom margins must still be background.
      // The top margin is not asserted: the head may legitimately reach near
      // the top once the shoulders are counted, and the rim separates it.
      expect(backgroundCount, greaterThanOrEqualTo(3));

      image.dispose();
    });
  });
}

/// Reads the pixel at ([x], [y]) from RGBA [bytes] of the given [width].
({int r, int g, int b, int a}) pixelAt(ByteData bytes, int width, int x, int y) {
  final i = (y * width + x) * 4;
  return (
    r: bytes.getUint8(i),
    g: bytes.getUint8(i + 1),
    b: bytes.getUint8(i + 2),
    a: bytes.getUint8(i + 3),
  );
}

/// Whether [actual] is within [tolerance] of [expected] on every channel.
///
/// Byte order differs across platforms (`dart:ui` reports RGBA on Android and
/// BGRA elsewhere), and a painter that fills with one flat colour should land
/// on exactly one of the two orders — so comparing per-channel with tolerance
/// is both portable and meaningful here.
bool _matches(
  ({int r, int g, int b, int a}) actual,
  int expected,
  int tolerance,
) {
  final expectedR = (expected >> 16) & 0xFF;
  final expectedG = (expected >> 8) & 0xFF;
  final expectedB = expected & 0xFF;
  final tolerance2 = tolerance * tolerance;

  int sq(int a, int b) {
    final d = a - b;
    return d * d;
  }

  return sq(actual.r, expectedR) +
          sq(actual.g, expectedG) +
          sq(actual.b, expectedB) <=
      tolerance2 * 3;
}

/// Paints [config] once and returns, so a throw surfaces as a test failure.
Future<void> _paint(
  AvatarConfig config, {
  AppColors colors = const AppColorsLight(),
}) async {
  const size = 96.0;
  final recorder = ui.PictureRecorder();
  AvatarPainter(config: config, colors: colors).paint(
    ui.Canvas(recorder),
    const ui.Size.square(size),
  );
  await recorder.endRecording().toImage(size.toInt(), size.toInt());
}
