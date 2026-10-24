import 'package:flutter/material.dart'
    as flutter_material
    show Material, MaterialType;
import 'package:material_ui/material_ui.dart'
    show BuildContext, StatelessWidget, Widget;

/// Supplies the SDK Material ancestor required by adaptive widgets' fallback.
class AppMaterialAncestor extends StatelessWidget {
  /// Creates a Material ancestor around [child].
  const AppMaterialAncestor({required this.child, super.key});

  /// The widget that needs a Material ancestor.
  final Widget child;

  @override
  Widget build(BuildContext context) => flutter_material.Material(
    type: flutter_material.MaterialType.transparency,
    child: child,
  );
}
