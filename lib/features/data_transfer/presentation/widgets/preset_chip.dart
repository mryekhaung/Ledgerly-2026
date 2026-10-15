import 'package:material_ui/material_ui.dart';

/// A single range-preset chip.
///
/// Extracted from `data_transfer_page.dart` (`docs/Conventions.md` §1).
class PresetChip extends StatelessWidget {
  /// Creates a [PresetChip].
  const PresetChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  /// The visible label.
  final String label;

  /// Whether this preset is active.
  final bool isSelected;

  /// Called when the chip is tapped.
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}
