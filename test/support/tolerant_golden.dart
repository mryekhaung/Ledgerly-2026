import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A golden comparator that tolerates small cross-platform rasterizer drift.
///
/// A golden PNG is generated once and then compared on whatever machine happens
/// to run the suite — a Windows dev box, a Linux CI runner, an Apple silicon
/// Mac. The same tree rasterises slightly differently on each (font hinting,
/// subpixel coverage, Impeller vs Skia), so the default comparator fails on a
/// single differing pixel. That turns a green suite into a platform lottery and
/// trains everyone to re-run `--update-goldens` until it passes, which is the
/// one behaviour a golden test exists to prevent.
///
/// 2 % is the budget: large enough to absorb antialiasing noise, small enough
/// that a real change — a moved row, a recoloured card, a wrong glyph, a
/// missing locale — differs by far more and still fails.
///
/// Every golden test must install this through [useTolerantGoldens] so a new
/// golden file cannot silently opt into exact matching.
class TolerantGoldenComparator extends LocalFileComparator {
  /// Creates a comparator whose [tolerance] defaults to the suite budget.
  TolerantGoldenComparator(super.testFile, {this.tolerance = defaultTolerance});

  /// The suite-wide tolerance: 2 % of pixels may differ.
  static const double defaultTolerance = 0.02;

  /// The fraction of differing pixels still treated as a pass.
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

/// Installs [TolerantGoldenComparator] for the calling golden test file.
///
/// Call this from `setUpAll`:
///
/// ```dart
/// void main() {
///   setUpAll(() => useTolerantGoldens('goals_golden_test.dart'));
///   // ...
/// }
/// ```
///
/// [testFileName] only names the file in failure output; the directory is
/// inherited from whatever comparator the runner installed, so goldens keep
/// resolving next to the test file rather than needing a path here.
void useTolerantGoldens(String testFileName) {
  final current = goldenFileComparator as LocalFileComparator;
  goldenFileComparator = TolerantGoldenComparator(
    Uri.parse('${current.basedir}$testFileName'),
    tolerance: TolerantGoldenComparator.defaultTolerance,
  );
}
