import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoButton,
        CupertinoDatePicker,
        CupertinoDatePickerMode,
        showCupertinoModalPopup;
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:material_ui/material_ui.dart';

/// An adaptive date picker (docs/Design.md §5).
///
/// * iOS: Cupertino modal wheel date picker.
/// * Material / Web: Material 3 date picker dialog.
class AppDatePicker {
  const AppDatePicker._();

  /// Shows an adaptive date picker dialog or bottom sheet.
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String? cancelLabel,
    String? doneLabel,
    AppPlatform? platform,
  }) async {
    final resolvedPlatform = platform ?? AppPlatform.resolve();

    if (resolvedPlatform.usesCupertino) {
      DateTime tempDate = initialDate;
      final colors = AppThemeColors.of(context);

      return showCupertinoModalPopup<DateTime>(
        context: context,
        builder: (sheetContext) {
          return Container(
            height: 300,
            color: colors.surfaceRaised,
            child: SafeArea(
              top: false,
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      CupertinoButton(
                        child: Text(cancelLabel ?? 'Cancel'),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                      CupertinoButton(
                        child: Text(doneLabel ?? 'Done'),
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(tempDate),
                      ),
                    ],
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: initialDate,
                      minimumDate: firstDate,
                      maximumDate: lastDate,
                      onDateTimeChanged: (date) => tempDate = date,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      cancelText: cancelLabel,
      confirmText: doneLabel,
    );
  }
}
