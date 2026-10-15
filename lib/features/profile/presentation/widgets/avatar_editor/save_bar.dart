import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// The pinned Save footer of the editor (docs/Avatar.md §2 step 0).
///
/// Extracted from `avatar_editor_page.dart` (`docs/Conventions.md` §1).
class EditorSaveBar extends StatelessWidget {
  /// Creates an [EditorSaveBar].
  const EditorSaveBar({required this.child, super.key});

  /// The save button (or its loading spinner).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Divider(height: 1, thickness: 1),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal(width),
            vertical: AppSpacing.md,
          ),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ],
    );
  }
}
