import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/presentation/providers/profile_providers.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar.dart';
import 'package:material_ui/material_ui.dart';

/// Builds an avatar one slot at a time.
///
/// The only piece of local state is the **draft** config: the user is composing
/// something, and until they save it nothing should reach the settings table.
/// That is the one legitimate exception to "the stream is the source of truth"
/// (`docs/Architecture.md` §5) — the alternative is five writes per tap and a
/// profile that changes under a swipe-back.
///
/// Because the draft is local, the page **must** be seeded from the stored
/// avatar exactly once, in [initState]'s equivalent for a `ConsumerStatefulWidget`.
/// Watching [currentAvatarProvider] in `build` and copying it into state would
/// discard the user's edits on the next stream emission — a stale-write bug that
/// only shows up when a save lands mid-edit.
class AvatarEditorPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const AvatarEditorPage({super.key});

  @override
  ConsumerState<AvatarEditorPage> createState() => _AvatarEditorPageState();
}

class _AvatarEditorPageState extends ConsumerState<AvatarEditorPage> {
  /// Null until seeded on the first build.
  AvatarConfig? _draft;

  /// Whether a save is in flight, so the button can show progress and cannot be
  /// double-tapped.
  bool _saving = false;

  /// The config being edited.
  ///
  /// Seeded lazily from the stored avatar on the first build rather than watched
  /// in `build`: watching [currentAvatarProvider] would let the next stream
  /// emission overwrite whatever the user had picked, which is the classic
  /// stale-write bug and only shows up when a save lands mid-edit.
  AvatarConfig get _draft$ {
    final existing = _draft;
    if (existing != null) return existing;
    final seeded = ref.read(currentAvatarProvider);
    _draft = seeded;
    return seeded;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);
    final config = _draft$;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings('avatarEditorTitle')),
        actions: <Widget>[
          TextButton(
            onPressed: _saving ? null : _shuffle,
            child: Text(strings('avatarEditorRandom')),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal(
              MediaQuery.sizeOf(context).width,
            ),
            vertical: AppSpacing.lg,
          ),
          children: <Widget>[
            _Preview(config: config, colors: colors),
            const SizedBox(height: AppSpacing.xl),
            // Every slot is a row of swatches: one tap = one choice, no sheet,
            // because the whole point of the editor is to see combinations.
            for (final part in AvatarPart.values) ...<Widget>[
              _PartRow(
                part: part,
                selectedIndex: config.indexOf(part),
                onSelected: (index) =>
                    setState(() => _draft = config.withPart(part, index)),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: _saving ? null : () => _save(config, strings),
              child: _saving
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.textOnBrand,
                      ),
                    )
                  : Text(strings('avatarEditorSave')),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  /// Replaces every slot with a random pick.
  ///
  /// Seeded from [avatarRandomProvider] so the shuffle is reproducible under
  /// test; in production it is a plain `Random()`.
  void _shuffle() {
    final random = ref.read(avatarRandomProvider);
    setState(() => _draft = AvatarCatalog.random(random));
  }

  /// Persists the draft and pops on success.
  ///
  /// Pops only after the write succeeds: leaving the page on a failure would
  /// show the *old* avatar on the profile and read as a silent data loss.
  Future<void> _save(
    AvatarConfig config,
    String Function(String key) strings,
  ) async {
    setState(() => _saving = true);

    final result = await ref.read(saveAvatarActionProvider)((avatar: config));
    if (!mounted) return;
    setState(() => _saving = false);

    if (result.isErr) {
      // Same message for every failure: the user's only recovery is to try
      // again, and naming the storage engine would not change that.
      _notify(strings('profileAvatarSaveFailed'));
      return;
    }

    Navigator.of(context).pop();
    _notify(strings('profileAvatarSaved'));
  }

  /// Shows a short-lived confirmation or failure message.
  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}

/// The live preview at the top of the editor.
class _Preview extends StatelessWidget {
  const _Preview({required this.config, required this.colors});

  final AvatarConfig config;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Center(
      child: Column(
        children: <Widget>[
          Avatar(
            config: config,
            size: 160,
            // The avatar is a picture: without a label a screen reader reads
            // the surrounding rows and never says what was just generated.
            semanticLabel: strings('profileAvatarLabel'),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            strings('avatarEditorPreview'),
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colors.textSecondary, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}

/// One slot: a label plus a horizontal strip of tappable swatches.
///
/// A strip rather than a dropdown because every option is a *picture*, and a
/// list of names ("Circle, Rounded square, Teardrop, Hexagon") makes the user
/// translate words into shapes instead of recognising them.
class _PartRow extends StatelessWidget {
  const _PartRow({
    required this.part,
    required this.selectedIndex,
    required this.onSelected,
  });

  final AvatarPart part;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);
    final label = strings(_labelKey(part));
    final count = AvatarCatalog.optionCount(part);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: colors.textSecondary, letterSpacing: 0.8),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: count,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) => _Swatch(
              part: part,
              index: index,
              selected: index == selectedIndex,
              // The swatch shows the *whole* avatar with only this slot changed,
              // so the effect of the choice is visible in context rather than as
              // an abstract chip.
              config: AvatarConfig.initial.withPart(part, index),
              // Filled through the ARB placeholder pair rather than a
              // concatenation, so a translator controls the word order
              // (`docs/Conventions.md` §5).
              semanticLabel: AppStrings.fill(
                context,
                'avatarEditorOptionLabel',
                {'part': label, 'number': index + 1},
              ),
              onTap: () => onSelected(index),
            ),
          ),
        ),
      ],
    );
  }

  /// The ARB key naming [part].
  ///
  /// A switch rather than a `part.name` interpolation so a renamed enum value
  /// becomes a compile error instead of a missing translation.
  static String _labelKey(AvatarPart part) => switch (part) {
    AvatarPart.background => 'avatarEditorBackground',
    AvatarPart.backdrop => 'avatarEditorBackdrop',
    AvatarPart.shape => 'avatarEditorShape',
    AvatarPart.eyes => 'avatarEditorEyes',
    AvatarPart.mouth => 'avatarEditorMouth',
  };
}

/// A single tappable option.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.part,
    required this.index,
    required this.selected,
    required this.config,
    required this.semanticLabel,
    required this.onTap,
  });

  final AvatarPart part;
  final int index;
  final bool selected;
  final AvatarConfig config;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: AnimatedContainer(
          duration: AppMotion.short,
          curve: AppMotion.standard,
          // The border is the selection indicator, not a background: a filled
          // background would fight the swatch's own colours.
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderLg,
            border: Border.all(
              color: selected ? colors.brandPrimary : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.xs + AppSpacing.xxs),
          child: Avatar(config: config, size: 52),
        ),
      ),
    );
  }
}
