import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoAlertDialog,
        CupertinoColors,
        CupertinoDialogAction,
        showCupertinoDialog;
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:material_ui/material_ui.dart';

/// An adaptive alert and confirmation dialog.
///
/// * iOS 26+: [IOS26AlertDialog] with Liquid Glass.
/// * iOS <= 18: [CupertinoAlertDialog].
/// * Material / Web: M3 [AlertDialog].
class AppDialog {
  const AppDialog._();

  /// Shows an adaptive confirmation dialog.
  ///
  /// Returns `true` if confirmed, `false` if cancelled or dismissed.
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    String? cancelLabel,
    bool isDestructive = false,
    AppPlatform? platform,
  }) async {
    final resolvedPlatform = platform ?? AppPlatform.resolve();
    if (resolvedPlatform.usesCupertino) {
      if (PlatformInfo.isIOS26OrHigher()) {
        bool result = false;
        await showCupertinoDialog<void>(
          context: context,
          barrierColor: CupertinoColors.transparent,
          builder: (dialogContext) => IOS26AlertDialog(
            title: title,
            message: message,
            actions: <AlertAction>[
              AlertAction(
                title: cancelLabel ?? 'Cancel',
                style: AlertActionStyle.cancel,
                onPressed: () {
                  result = false;
                },
              ),
              AlertAction(
                title: confirmLabel,
                style: isDestructive
                    ? AlertActionStyle.destructive
                    : AlertActionStyle.primary,
                onPressed: () {
                  result = true;
                },
              ),
            ],
          ),
        );
        return result;
      }

      // iOS 18 and below (Cupertino)
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel ?? 'Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: isDestructive,
              isDefaultAction: !isDestructive,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
      return result ?? false;
    }

    // Material / Web
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = AppThemeColors.of(context);
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: isDestructive
                  ? FilledButton.styleFrom(backgroundColor: colors.moneyOut)
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Shows an adaptive dialog with custom content or action widgets.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? content,
    Widget? contentWidget,
    List<Widget>? actions,
    AppPlatform? platform,
  }) {
    final resolvedPlatform = platform ?? AppPlatform.resolve();
    final child = contentWidget ?? (content != null ? Text(content) : null);

    if (resolvedPlatform.usesCupertino) {
      return showCupertinoDialog<T>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(title),
          content: child,
          actions: <Widget>[
            for (final action in actions ?? <Widget>[])
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: action,
              ),
          ],
        ),
      );
    }

    return showDialog<T>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: child,
        actions:
            actions ??
            <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  MaterialLocalizations.of(dialogContext).okButtonLabel,
                ),
              ),
            ],
      ),
    );
  }
}
