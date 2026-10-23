import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveBlurView, BlurStyle, PlatformInfo;
import 'package:cupertino_ui/cupertino_ui.dart' show showCupertinoModalPopup;
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:material_ui/material_ui.dart';

/// An adaptive modal bottom sheet.
///
/// * iOS 26+: Liquid Glass floating modal sheet using [AdaptiveBlurView]
///   with floating card layout, smooth rounded corners, and drag indicator.
/// * iOS < 26: Cupertino modal slide-up popup using [showCupertinoModalPopup].
/// * Material / Web: M3 [showModalBottomSheet] with rounded top corners.
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
    bool? isIOS26,
  }) {
    final resolvedPlatform = platform ?? AppPlatform.resolve();
    final effectiveIsIOS26 = isIOS26 ?? PlatformInfo.isIOS26OrHigher();

    if (resolvedPlatform.usesCupertino) {
      if (effectiveIsIOS26) {
        final colors = AppThemeColors.of(context);
        return showCupertinoModalPopup<T>(
          context: context,
          useRootNavigator: useRootNavigator,
          builder: (popupContext) => SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(AppRadius.radiusXl),
                child: AdaptiveBlurView(
                  blurStyle: BlurStyle.systemMaterial,
                  borderRadius: const BorderRadius.all(AppRadius.radiusXl),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (backgroundColor ?? colors.surfaceRaised)
                          .withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.all(AppRadius.radiusXl),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(height: 8),
                        Container(
                          width: 36,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colors.textTertiary.withValues(alpha: 0.4),
                            borderRadius: AppRadius.borderFull,
                          ),
                        ),
                        Flexible(
                          child: Material(
                            type: MaterialType.transparency,
                            child: builder(popupContext),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

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
