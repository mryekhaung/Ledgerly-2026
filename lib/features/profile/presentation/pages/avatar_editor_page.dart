import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:ledgerly/core/widgets/app_dialog.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/presentation/providers/profile_providers.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/editor_tab.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/preview_section.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/save_bar.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/tab_body.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar_editor/tab_chips_row.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:material_ui/material_ui.dart';

/// Builds an Open Peeps avatar through the 5-tab editor.
///
/// Spec: `docs/Avatar.md` §6.
/// - Top bar: ✕ (cancel with confirmation if unsaved edits exist) · title · Save footer.
/// - Pinned circular preview (160 px) + Generate randomly button.
/// - Tabs: Head · Face · Glasses · Item · Colors.
/// - Responsive: compact = stacked under preview; medium+ = two panes via [TwoPaneLayout].
/// - Haptics: [AppFeedback.selection] on change, [AppFeedback.success] on save.
///
/// Composition root only: preview, tabs and tiles live in
/// `widgets/avatar_editor/` (`docs/Conventions.md` §1).
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
    final config = _draft$;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = WindowSizeClass.of(context).isTwoPaneCapable;

    final saveButton = AppButton(
      label: strings('avatarEditorSave'),
      onPressed: _saving ? null : () => _save(config, strings),
      isLoading: _saving,
      isExpanded: true,
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
            child: EditorPreviewSection(
              config: config,
              onShuffle: _shuffle,
              saving: _saving,
            ),
          ),
          detail: Column(
            children: <Widget>[
              const SizedBox(height: AppSpacing.lg),
              EditorTabChipsRow(
                currentTab: _currentTab,
                onTabSelected: (tab) => setState(() => _currentTab = tab),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: EditorTabBody(
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
            EditorPreviewSection(
              config: config,
              onShuffle: _shuffle,
              saving: _saving,
            ),
            const SizedBox(height: AppSpacing.md),
            EditorTabChipsRow(
              currentTab: _currentTab,
              onTabSelected: (tab) => setState(() => _currentTab = tab),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: EditorTabBody(
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
      child: AppScaffold(
        title: strings('avatarEditorTitle'),
        leading: IconButton(
          icon: const Icon(AppIcons.close),
          onPressed: _saving ? null : () => unawaited(_onCancel()),
          tooltip: strings('actionCancel'),
        ),
        useSafeArea: false,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              bodyContent,
              EditorSaveBar(child: saveButton),
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
      context.pop();
      return;
    }
    await _showDiscardConfirmDialog();
  }

  Future<void> _showDiscardConfirmDialog() async {
    final strings = AppStrings.of(context);
    final discard = await AppDialog.confirm(
      context: context,
      title: strings('avatarEditorDiscardTitle'),
      message: strings('avatarEditorDiscardMessage'),
      confirmLabel: strings('avatarEditorDiscardConfirm'),
      cancelLabel: strings('avatarEditorKeepEditing'),
      isDestructive: true,
    );

    if (discard == true && mounted) {
      AppFeedback.destructive();
      context.pop();
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
    context.pop();
    AppFeedback.confirm(context, message: strings('profileAvatarSaved'));
  }
}
