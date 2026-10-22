import 'package:cupertino_ui/cupertino_ui.dart' show showCupertinoModalPopup;
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:material_ui/material_ui.dart';

/// An adaptive modal bottom sheet.
///
/// * iOS: Uses [showCupertinoModalPopup] with Cupertino modal slide-up transition,
///   natural bounce curve, and safe-area insets.
/// * Material / Web: Uses M3 [showModalBottomSheet] with rounded top corners.
class AppBottomSheet {
  const AppBottomSheet._();

  /// Shows an adaptive modal bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool useRootNavigator = true,
    Color? backgroundColor,
    ShapeBorder? shape,
    AppPlatform? platform,
  }) {
    final resolvedPlatform = platform ?? AppPlatform.resolve();

    if (resolvedPlatform.usesCupertino) {
      return showCupertinoModalPopup<T>(
        context: context,
        useRootNavigator: useRootNavigator,
        builder: (popupContext) => Material(
          type: MaterialType.transparency,
          child: SafeArea(top: false, child: builder(popupContext)),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor ?? Colors.transparent,
      shape:
          shape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: AppRadius.radiusXl),
          ),
      builder: builder,
    );
  }
}
