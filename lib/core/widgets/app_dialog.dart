import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoAlertDialog, CupertinoDialogAction, showCupertinoDialog;
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:material_ui/material_ui.dart';

/// An adaptive alert dialog.
///
/// iOS renders a Cupertino alert; Material/Web renders the M3 `AlertDialog`.
/// Same title/content/actions contract either way.
class AppDialog {
  const AppDialog._();

  /// Shows an adaptive dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String content,
    List<Widget>? actions,
  }) {
    final platform = AppPlatform.resolve();
    if (platform.usesCupertino) {
      return showCupertinoDialog<T>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
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
        content: Text(content),
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
