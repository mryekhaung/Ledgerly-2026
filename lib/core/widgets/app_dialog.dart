import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoAlertDialog,
        CupertinoDialogAction,
        showCupertinoDialog;
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:material_ui/material_ui.dart';

/// An adaptive alert and confirmation dialog.
///
/// * iOS: [CupertinoAlertDialog] styled with design tokens.
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
    final colors = AppThemeColors.of(context);
    final resolvedPlatform = platform ?? AppPlatform.resolve();

    if (resolvedPlatform.usesCupertino) {
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(message, style: TextStyle(color: colors.textSecondary)),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                cancelLabel ?? 'Cancel',
                style: TextStyle(color: colors.brandPrimary),
              ),
            ),
            CupertinoDialogAction(
              isDestructiveAction: isDestructive,
              isDefaultAction: !isDestructive,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                confirmLabel,
                style: TextStyle(
                  color: isDestructive ? colors.moneyOut : colors.brandPrimary,
                  fontWeight: isDestructive
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
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
    final colors = AppThemeColors.of(context);
    final resolvedPlatform = platform ?? AppPlatform.resolve();
    final child =
        contentWidget ??
        (content != null
            ? Text(content, style: TextStyle(color: colors.textSecondary))
            : null);

    if (resolvedPlatform.usesCupertino) {
      return showCupertinoDialog<T>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: child != null
              ? Padding(padding: const EdgeInsets.only(top: 8.0), child: child)
              : null,
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
