import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_palette.dart';
import 'package:ledgerly/features/profile/presentation/providers/profile_providers.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:material_ui/material_ui.dart';

/// The 5 tabs of the Avatar Editor (docs/Avatar.md §6).
enum AvatarEditorTab { head, face, glasses, item, colors }

/// Builds an Open Peeps avatar through the 5-tab editor.
///
/// Spec: `docs/Avatar.md` §6.
/// - Top bar: ✕ (cancel with confirmation if unsaved edits exist) · title · Save footer.
/// - Pinned circular preview (160 px) + Generate randomly button.
/// - Tabs: Head · Face · Glasses · Item · Colors.
/// - Responsive: compact = stacked under preview; medium+ = two panes via [TwoPaneLayout].
/// - Haptics: [AppFeedback.selection] on change, [AppFeedback.success] on save.
class AvatarEditorPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const AvatarEditorPage({super.key});

  @override
  ConsumerState<AvatarEditorPage> createState() => _AvatarEditorPageState();
}

class _AvatarEditorPageState extends ConsumerState<AvatarEditorPage> {
  /// The working draft. Null until lazily seeded.
  AvatarConfig? _draft;

  /// The original config loaded on open, used for unsaved discard check.
  AvatarConfig? _initialConfig;

  /// Currently active tab.
  AvatarEditorTab _currentTab = AvatarEditorTab.head;

  /// Whether a save write is in flight.
  bool _saving = false;

  /// Seeded lazily from [currentAvatarProvider] on the first build.
  AvatarConfig get _draft$ {
    final existing = _draft;
    if (existing != null) return existing;
    final seeded = ref.read(currentAvatarProvider);
    _initialConfig = seeded;
    _draft = seeded;
    return seeded;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);
    final config = _draft$;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = WindowSizeClass.of(context).isTwoPaneCapable;

    final saveButton = FilledButton(
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
    );

    final Widget bodyContent;
    if (isWide) {
      bodyContent = Expanded(
        child: TwoPaneLayout(
          master: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal(width),
              vertical: AppSpacing.lg,
            ),
            child: _PreviewSection(
              config: config,
              onShuffle: _shuffle,
              saving: _saving,
            ),
          ),
          detail: Column(
            children: <Widget>[
              const SizedBox(height: AppSpacing.lg),
              _TabChipsRow(
                currentTab: _currentTab,
                onTabSelected: (tab) => setState(() => _currentTab = tab),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _TabBody(
                  currentTab: _currentTab,
                  config: config,
                  onConfigChanged: (updated) =>
                      setState(() => _draft = updated),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      bodyContent = Expanded(
        child: Column(
          children: <Widget>[
            _PreviewSection(
              config: config,
              onShuffle: _shuffle,
              saving: _saving,
            ),
            const SizedBox(height: AppSpacing.md),
            _TabChipsRow(
              currentTab: _currentTab,
              onTabSelected: (tab) => setState(() => _currentTab = tab),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: _TabBody(
                currentTab: _currentTab,
                config: config,
                onConfigChanged: (updated) => setState(() => _draft = updated),
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: _draft$ == _initialConfig || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_onCancel());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _saving ? null : () => unawaited(_onCancel()),
            tooltip: strings('actionCancel'),
          ),
          title: Text(strings('avatarEditorTitle')),
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              bodyContent,
              _SaveBar(child: saveButton),
            ],
          ),
        ),
      ),
    );
  }

  void _shuffle() {
    AppFeedback.selection();
    final random = ref.read(avatarRandomProvider);
    setState(() => _draft = AvatarCatalog.random(random));
  }

  Future<void> _onCancel() async {
    if (_draft$ == _initialConfig || _saving) {
      Navigator.of(context).pop();
      return;
    }
    await _showDiscardConfirmDialog();
  }

  Future<void> _showDiscardConfirmDialog() async {
    final strings = AppStrings.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings('avatarEditorDiscardTitle')),
        content: Text(strings('avatarEditorDiscardMessage')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings('avatarEditorKeepEditing')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings('avatarEditorDiscardConfirm')),
          ),
        ],
      ),
    );

    if (discard == true && mounted) {
      AppFeedback.destructive();
      Navigator.of(context).pop();
    }
  }

  Future<void> _save(
    AvatarConfig config,
    String Function(String key) strings,
  ) async {
    setState(() => _saving = true);

    final result = await ref.read(saveAvatarActionProvider)((avatar: config));
    if (!mounted) return;
    setState(() => _saving = false);

    if (result.isErr) {
      AppFeedback.failure(context, message: strings('profileAvatarSaveFailed'));
      return;
    }

    AppFeedback.success();
    Navigator.of(context).pop();
    AppFeedback.confirm(context, message: strings('profileAvatarSaved'));
  }
}

/// The pinned Save footer of the editor (docs/Avatar.md §2 step 0).
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.child});

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

/// The 160 px circular live preview + Shuffle button.
class _PreviewSection extends StatelessWidget {
  const _PreviewSection({
    required this.config,
    required this.onShuffle,
    required this.saving,
  });

  final AvatarConfig config;
  final VoidCallback onShuffle;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: AppSpacing.xxl),
          Avatar(
            config: config,
            size: 160,
            shape: AvatarShape.circle,
            semanticLabel: strings('profileAvatarLabel'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: saving ? null : onShuffle,
            icon: const Icon(Icons.shuffle_rounded, size: 18),
            label: Text(strings('avatarEditorRandom')),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scrollable chip row for the 5 tabs (docs/Design.md §5.5).
class _TabChipsRow extends StatelessWidget {
  const _TabChipsRow({required this.currentTab, required this.onTabSelected});

  final AvatarEditorTab currentTab;
  final ValueChanged<AvatarEditorTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal(width),
      ),
      child: Row(
        children: <Widget>[
          for (final tab in AvatarEditorTab.values) ...<Widget>[
            _TabChip(
              tab: tab,
              label: strings(_tabLabelKey(tab)),
              isSelected: tab == currentTab,
              onTap: () {
                AppFeedback.selection();
                onTabSelected(tab);
              },
            ),
            if (tab != AvatarEditorTab.colors)
              const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  static String _tabLabelKey(AvatarEditorTab tab) => switch (tab) {
    AvatarEditorTab.head => 'avatarEditorTabHead',
    AvatarEditorTab.face => 'avatarEditorTabFace',
    AvatarEditorTab.glasses => 'avatarEditorTabGlasses',
    AvatarEditorTab.item => 'avatarEditorTabItem',
    AvatarEditorTab.colors => 'avatarEditorTabColors',
  };
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.tab,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final AvatarEditorTab tab;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderFull,
        child: AnimatedContainer(
          duration: AppMotion.short,
          curve: AppMotion.standard,
          height: 36,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderFull,
            color: isSelected ? colors.brandSubtle : Colors.transparent,
            border: Border.all(
              color: isSelected ? colors.brandPrimary : colors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              color: isSelected ? colors.brandPrimary : colors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// The main content area of the selected tab.
class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.currentTab,
    required this.config,
    required this.onConfigChanged,
  });

  final AvatarEditorTab currentTab;
  final AvatarConfig config;
  final ValueChanged<AvatarConfig> onConfigChanged;

  @override
  Widget build(BuildContext context) {
    return switch (currentTab) {
      AvatarEditorTab.head => _HeadTab(
        config: config,
        onConfigChanged: onConfigChanged,
      ),
      AvatarEditorTab.face => _FaceTab(
        config: config,
        onConfigChanged: onConfigChanged,
      ),
      AvatarEditorTab.glasses => _GlassesTab(
        config: config,
        onConfigChanged: onConfigChanged,
      ),
      AvatarEditorTab.item => _ItemTab(
        config: config,
        onConfigChanged: onConfigChanged,
      ),
      AvatarEditorTab.colors => _ColorsTab(
        config: config,
        onConfigChanged: onConfigChanged,
      ),
    };
  }
}

/// Head options (48 variants).
class _HeadTab extends StatelessWidget {
  const _HeadTab({required this.config, required this.onConfigChanged});

  final AvatarConfig config;
  final ValueChanged<AvatarConfig> onConfigChanged;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal(width),
        vertical: AppSpacing.md,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.0,
      ),
      itemCount: AvatarCatalog.heads.length,
      itemBuilder: (context, index) {
        final headId = AvatarCatalog.heads[index];
        final isSelected = config.headId == headId;
        return _PartTile(
          group: 'head',
          id: headId,
          isSelected: isSelected,
          config: config.copyWith(headId: headId),
          semanticLabel: AppStrings.fill(context, 'avatarEditorOptionLabel', {
            'part': AppStrings.of(context)('avatarEditorTabHead'),
            'number': index + 1,
          }),
          onTap: () {
            AppFeedback.selection();
            onConfigChanged(config.copyWith(headId: headId));
          },
        );
      },
    );
  }
}

/// Face tab: Expressions (30 variants) + Facial Hair (16 variants + None).
class _FaceTab extends StatelessWidget {
  const _FaceTab({required this.config, required this.onConfigChanged});

  final AvatarConfig config;
  final ValueChanged<AvatarConfig> onConfigChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal(width),
            vertical: AppSpacing.md,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final faceId = AvatarCatalog.expressions[index];
              final isSelected = config.faceId == faceId;
              return _PartTile(
                group: 'expression',
                id: faceId,
                isSelected: isSelected,
                config: config.copyWith(faceId: faceId),
                semanticLabel: AppStrings.fill(
                  context,
                  'avatarEditorOptionLabel',
                  {'part': strings('avatarEditorTabFace'), 'number': index + 1},
                ),
                onTap: () {
                  AppFeedback.selection();
                  onConfigChanged(config.copyWith(faceId: faceId));
                },
              );
            }, childCount: AvatarCatalog.expressions.length),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal(width),
              vertical: AppSpacing.md,
            ),
            child: Text(
              strings('avatarEditorBeard').toUpperCase(),
              style: AppTypography.overline.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            left: AppSpacing.pageHorizontal(width),
            right: AppSpacing.pageHorizontal(width),
            bottom: AppSpacing.lg,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == 0) {
                final isNone = config.facialHairId == null;
                return _NoneTile(
                  isSelected: isNone,
                  onTap: () {
                    AppFeedback.selection();
                    onConfigChanged(config.copyWith(facialHairId: null));
                  },
                );
              }
              final beardId = AvatarCatalog.facialHairs[index - 1];
              final isSelected = config.facialHairId == beardId;
              return _PartTile(
                group: 'facial_hair',
                id: beardId,
                isSelected: isSelected,
                config: config.copyWith(facialHairId: beardId),
                semanticLabel: AppStrings.fill(
                  context,
                  'avatarEditorOptionLabel',
                  {'part': strings('avatarEditorBeard'), 'number': index},
                ),
                onTap: () {
                  AppFeedback.selection();
                  onConfigChanged(config.copyWith(facialHairId: beardId));
                },
              );
            }, childCount: AvatarCatalog.facialHairs.length + 1),
          ),
        ),
      ],
    );
  }
}

/// Glasses tab (8 accessory variants + None).
class _GlassesTab extends StatelessWidget {
  const _GlassesTab({required this.config, required this.onConfigChanged});

  final AvatarConfig config;
  final ValueChanged<AvatarConfig> onConfigChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal(width),
        vertical: AppSpacing.md,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.0,
      ),
      itemCount: AvatarCatalog.accessories.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          final isNone = config.accessoryId == null;
          return _NoneTile(
            isSelected: isNone,
            onTap: () {
              AppFeedback.selection();
              onConfigChanged(config.copyWith(accessoryId: null));
            },
          );
        }
        final accId = AvatarCatalog.accessories[index - 1];
        final isSelected = config.accessoryId == accId;
        return _PartTile(
          group: 'accessories',
          id: accId,
          isSelected: isSelected,
          config: config.copyWith(accessoryId: accId),
          semanticLabel: AppStrings.fill(context, 'avatarEditorOptionLabel', {
            'part': strings('avatarEditorTabGlasses'),
            'number': index,
          }),
          onTap: () {
            AppFeedback.selection();
            onConfigChanged(config.copyWith(accessoryId: accId));
          },
        );
      },
    );
  }
}

/// Item tab (None + Coming Soon placeholder).
class _ItemTab extends StatelessWidget {
  const _ItemTab({required this.config, required this.onConfigChanged});

  final AvatarConfig config;
  final ValueChanged<AvatarConfig> onConfigChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal(width),
        vertical: AppSpacing.md,
      ),
      children: <Widget>[
        SizedBox(
          height: 100,
          child: Row(
            children: <Widget>[
              SizedBox.square(
                dimension: 100,
                child: _NoneTile(
                  isSelected: config.itemId == null,
                  onTap: () {
                    AppFeedback.selection();
                    onConfigChanged(config.copyWith(itemId: null));
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 48,
                  color: colors.textSecondary.withValues(alpha: 0.6),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  strings('avatarEditorItemsComingSoon'),
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Colors tab (Background, Outline, Hair, Skin tone, Outfit).
class _ColorsTab extends StatelessWidget {
  const _ColorsTab({required this.config, required this.onConfigChanged});

  final AvatarConfig config;
  final ValueChanged<AvatarConfig> onConfigChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: <Widget>[
        _ColorSection(
          label: strings('avatarEditorBackground'),
          colors: AvatarPalette.backgrounds,
          selectedColor: config.colors.background,
          onColorSelected: (argb) {
            AppFeedback.selection();
            onConfigChanged(
              config.copyWith(colors: config.colors.copyWith(background: argb)),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _ColorSection(
          label: strings('avatarEditorColorOutline'),
          colors: AvatarPalette.inks,
          selectedColor: config.colors.ink,
          onColorSelected: (argb) {
            AppFeedback.selection();
            onConfigChanged(
              config.copyWith(colors: config.colors.copyWith(ink: argb)),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _ColorSection(
          label: strings('avatarEditorColorHair'),
          colors: AvatarPalette.hairs,
          selectedColor: config.colors.hair,
          onColorSelected: (argb) {
            AppFeedback.selection();
            onConfigChanged(
              config.copyWith(colors: config.colors.copyWith(hair: argb)),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _ColorSection(
          label: strings('avatarEditorColorSkin'),
          colors: AvatarPalette.skins,
          selectedColor: config.colors.skin,
          onColorSelected: (argb) {
            AppFeedback.selection();
            onConfigChanged(
              config.copyWith(colors: config.colors.copyWith(skin: argb)),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _ColorSection(
          label: strings('avatarEditorColorOutfit'),
          colors: AvatarPalette.outfits,
          selectedColor: config.colors.clothing,
          onColorSelected: (argb) {
            AppFeedback.selection();
            onConfigChanged(
              config.copyWith(colors: config.colors.copyWith(clothing: argb)),
            );
          },
        ),
      ],
    );
  }
}

/// One swatch section: header + horizontal strip of circles.
class _ColorSection extends StatelessWidget {
  const _ColorSection({
    required this.label,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final String label;
  final List<int> colors;
  final int selectedColor;
  final ValueChanged<int> onColorSelected;

  @override
  Widget build(BuildContext context) {
    final themeColors = AppThemeColors.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal(width),
          ),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.overline.copyWith(
              color: themeColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal(width),
            ),
            itemCount: colors.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final argb = colors[index];
              final isSelected = argb == selectedColor;
              return _ColorSwatch(
                argb: argb,
                isSelected: isSelected,
                onTap: () => onColorSelected(argb),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A circular color swatch with selected ring.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.argb,
    required this.isSelected,
    required this.onTap,
  });

  final int argb;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final themeColors = AppThemeColors.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderFull,
        child: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? themeColors.brandPrimary : themeColors.border,
              width: isSelected ? 2.5 : 1.0,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(argb),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single option tile in a 3-column grid.
class _PartTile extends StatelessWidget {
  const _PartTile({
    required this.group,
    required this.id,
    required this.isSelected,
    required this.config,
    required this.semanticLabel,
    required this.onTap,
  });

  final String group;
  final String id;
  final bool isSelected;
  final AvatarConfig config;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: AnimatedContainer(
          duration: AppMotion.short,
          curve: AppMotion.standard,
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderLg,
            color: colors.surfaceSubtle,
            border: Border.all(
              color: isSelected ? colors.brandPrimary : colors.border,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.xs),
          alignment: Alignment.center,
          child: Avatar(
            config: config,
            size: 64,
            shape: AvatarShape.circle,
            thumbnailGroup: group,
            thumbnailId: id,
          ),
        ),
      ),
    );
  }
}

/// The "None" (⊘) tile for optional layers.
class _NoneTile extends StatelessWidget {
  const _NoneTile({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: strings('avatarEditorNone'),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: AnimatedContainer(
          duration: AppMotion.short,
          curve: AppMotion.standard,
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderLg,
            color: colors.surfaceSubtle,
            border: Border.all(
              color: isSelected ? colors.brandPrimary : colors.border,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.block_rounded,
                color: isSelected ? colors.brandPrimary : colors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                strings('avatarEditorNone'),
                style: AppTypography.caption.copyWith(
                  color: isSelected
                      ? colors.brandPrimary
                      : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
