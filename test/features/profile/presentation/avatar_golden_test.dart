import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar.dart';
import 'package:material_ui/material_ui.dart';

/// Tolerant comparator allowing minor rasterizer difference across OSes (docs/Conventions.md §6).
class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile, {this.tolerance = 0.02});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed && result.diffPercent > tolerance) {
      final error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    return result.passed || result.diffPercent <= tolerance;
  }
}

void main() {
  setUpAll(() {
    final current = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenComparator(
      Uri.parse('${current.basedir}avatar_golden_test.dart'),
      tolerance: 0.02,
    );
  });

  Widget host({
    required AvatarShape shape,
    required bool isDark,
    AvatarConfig config = AvatarConfig.initial,
  }) {
    final themeColors = isDark ? const AppColorsDark() : const AppColorsLight();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDark ? AppTheme.dark() : AppTheme.light(),
      home: AppThemeColors(
        colors: themeColors,
        child: ColoredBox(
          color: themeColors.surface,
          child: Center(
            child: RepaintBoundary(
              child: Container(
                width: 200,
                height: 200,
                color: themeColors.surface,
                alignment: Alignment.center,
                child: Avatar(config: config, size: 160, shape: shape),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Avatar golden tests', () {
    testWidgets('circle avatar in light theme', (tester) async {
      await tester.pumpWidget(host(shape: AvatarShape.circle, isDark: false));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Avatar),
        matchesGoldenFile('goldens/avatar_circle_light.png'),
      );
    });

    testWidgets('circle avatar in dark theme', (tester) async {
      await tester.pumpWidget(host(shape: AvatarShape.circle, isDark: true));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Avatar),
        matchesGoldenFile('goldens/avatar_circle_dark.png'),
      );
    });

    testWidgets('squircle avatar in light theme', (tester) async {
      await tester.pumpWidget(host(shape: AvatarShape.squircle, isDark: false));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Avatar),
        matchesGoldenFile('goldens/avatar_squircle_light.png'),
      );
    });

    testWidgets('squircle avatar in dark theme', (tester) async {
      await tester.pumpWidget(host(shape: AvatarShape.squircle, isDark: true));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Avatar),
        matchesGoldenFile('goldens/avatar_squircle_dark.png'),
      );
    });
  });
}
