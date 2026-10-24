import 'dart:math' as math;

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
///   with floating card layout, smooth rounded corners, and a draggable handle.
/// * iOS < 26: Cupertino modal slide-up popup using [showCupertinoModalPopup].
/// * Material / Web: M3 [showModalBottomSheet] with rounded top corners.
///
/// Every sheet leaves clearance above the surface for the native status/app
/// bar and exposes the same downward drag-to-dismiss handle.
class AppBottomSheet {
  const AppBottomSheet._();

  /// Keeps modal surfaces below the status area and native app bar.
  static const double _topClearance = 88;
  static const double _handleWidth = 36;
  static const double _handleHeight = 5;

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
          builder: (popupContext) {
            final maxHeight = _maxSheetHeight(popupContext);
            return SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                      bottom: 10,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(AppRadius.radiusXl),
                      child: AdaptiveBlurView(
                        blurStyle: BlurStyle.systemUltraThinMaterial,
                        borderRadius: const BorderRadius.all(
                          AppRadius.radiusXl,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              AppRadius.radiusXl,
                            ),
                            border: Border.all(
                              color: colors.border.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: _sheetContents(
                            popupContext,
                            builder,
                            handleColor: colors.textTertiary.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }

      return showCupertinoModalPopup<T>(
        context: context,
        useRootNavigator: useRootNavigator,
        builder: (popupContext) {
          final colors = AppThemeColors.of(context);
          return SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: _maxSheetHeight(popupContext),
                ),
                child: Material(
                  color: backgroundColor ?? colors.surfaceRaised,
                  borderRadius: const BorderRadius.vertical(
                    top: AppRadius.radiusXl,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _sheetContents(
                    popupContext,
                    builder,
                    handleColor: colors.textTertiary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: isScrollControlled,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: backgroundColor ?? Colors.transparent,
      shape:
          shape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: AppRadius.radiusXl),
          ),
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: _maxSheetHeight(sheetContext)),
        child: Material(
          type: MaterialType.transparency,
          child: _sheetContents(
            sheetContext,
            builder,
            handleColor: AppThemeColors.of(context).textTertiary
                .withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  static double _maxSheetHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return math.max(
      0,
      mediaQuery.size.height -
          mediaQuery.padding.top -
          _topClearance -
          mediaQuery.padding.bottom,
    );
  }

  static Widget _sheetContents(
    BuildContext sheetContext,
    WidgetBuilder builder, {
    required Color handleColor,
  }) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      _DragHandle(color: handleColor),
      Flexible(
        child: Material(
          type: MaterialType.transparency,
          child: builder(sheetContext),
        ),
      ),
    ],
  );
}

class _DragHandle extends StatefulWidget {
  const _DragHandle({required this.color});

  final Color color;

  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> {
  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey<String>('app-bottom-sheet-drag-handle'),
    behavior: HitTestBehavior.opaque,
    onVerticalDragUpdate: (details) {
      _dragDistance += details.delta.dy;
    },
    onVerticalDragEnd: (details) {
      if (_dragDistance >= 64 || (details.primaryVelocity ?? 0) >= 600) {
        Navigator.of(context).maybePop();
      }
      _dragDistance = 0;
    },
    child: SizedBox(
      width: double.infinity,
      height: 24,
      child: Center(
        child: Container(
          width: AppBottomSheet._handleWidth,
          height: AppBottomSheet._handleHeight,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: AppRadius.borderFull,
          ),
        ),
      ),
    ),
  );
}
