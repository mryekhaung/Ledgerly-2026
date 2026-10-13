import 'package:flutter/widgets.dart';
import 'package:ledgerly/l10n/generated/app_localizations.dart';

/// Key-based access to the app's translations.
///
/// The generated `AppLocalizations` exposes one getter per key — type-safe, but
/// unable to serve a key that is only known at runtime. The validation layer
/// hands back exactly that: `ValidationFailure.fieldErrors` maps a field to a
/// validator key, which `AppLocalization.validationKeyFor` bridges to an ARB
/// key. `lookup` is the single place that turns such a key into text, so no
/// widget builds a user-facing string by concatenation
/// (`docs/Conventions.md` §5).
///
/// Backed by an [InheritedWidget] rather than a global so a locale change
/// rebuilds every dependent widget.
abstract final class AppStrings {
  const AppStrings._();

  /// The lookup for the current locale.
  ///
  /// Throws when used above [AppStringsScope]: a missing scope is a wiring bug,
  /// and quietly falling back to English would hide it in every locale.
  static String Function(String key) of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStringsScope>();
    if (scope == null) {
      throw FlutterError(
        'AppStrings.of() was called with a context that does not contain an '
        'AppStringsScope. Wrap the app in one. See lib/app/app.dart.',
      );
    }
    return scope.lookup;
  }

  /// Fills the placeholders of the ARB key [key] for the current locale.
  ///
  /// The generated `AppLocalizations` gives each parameterised key its own typed
  /// method, which a key-based lookup cannot reach. This is the bridge: the few
  /// keys that take arguments are named here, so a translator can reorder
  /// `{part}` and `{number}` without any Dart change, and no call site is ever
  /// tempted to build the sentence by concatenation (`docs/Conventions.md` §5).
  ///
  /// A missing [values] entry is a wiring bug and throws, rather than pasting the
  /// literal `{placeholder}` into the UI.
  static String fill(
    BuildContext context,
    String key,
    Map<String, Object> values,
  ) {
    final l10n = AppLocalizations.of(context);
    return switch (key) {
      'avatarEditorOptionLabel' => l10n.avatarEditorOptionLabel(
        _require(values, 'part') as String,
        _require(values, 'number') as int,
      ),
      'avatarEditorPartSelected' => l10n.avatarEditorPartSelected(
        _require(values, 'part') as String,
        _require(values, 'value') as String,
      ),
      'monthStartsOnCurrentPeriod' => l10n.monthStartsOnCurrentPeriod(
        _require(values, 'range') as String,
      ),
      'monthStartsOnPreviousPeriod' => l10n.monthStartsOnPreviousPeriod(
        _require(values, 'range') as String,
      ),
      'monthStartsOnDayFormat' => l10n.monthStartsOnDayFormat(
        _require(values, 'day') as int,
      ),
      _ => throw FlutterError(
        'AppStrings.fill() has no case for "$key". Add one in '
        'lib/core/presentation/app_strings.dart.',
      ),
    };
  }

  /// Reads a required placeholder, or throws naming the key.
  static Object _require(Map<String, Object> values, String name) {
    final value = values[name];
    if (value == null) {
      throw FlutterError(
        'AppStrings.fill() is missing the "$name" placeholder.',
      );
    }
    return value;
  }
}

/// Provides the [AppStrings] lookup to the widget tree.
///
/// Sits just inside the `MaterialApp` so it always resolves against the active
/// locale.
class AppStringsScope extends InheritedWidget {
  /// Creates the scope.
  const AppStringsScope({
    required this.lookup,
    required super.child,
    super.key,
  });

  /// Resolves an ARB key to its translated string for the active locale.
  final String Function(String key) lookup;

  /// A locale change replaces [lookup], so dependents must rebuild.
  @override
  bool updateShouldNotify(AppStringsScope oldWidget) =>
      !identical(lookup, oldWidget.lookup);
}

/// Adapts the generated [AppLocalizations] to a key → string lookup.
///
/// Kept separate from [AppStringsScope] so the scope stays testable with a fake
/// lookup and this adapter is the only code that has to know the generated API.
abstract final class AppStringLookup {
  const AppStringLookup._();

  /// Builds a lookup over [l10n] for the current locale.
  ///
  /// Every key the app can produce at runtime must appear here; the switch is
  /// exhaustive over the ARB, and `flutter gen-l10n`'s own key set is what makes
  /// a missing case a compile error rather than a silent `key` echoed to the
  /// user.
  static String Function(String key) of(AppLocalizations l10n) =>
      (key) => _resolve(l10n, key);

  static String _resolve(AppLocalizations l10n, String key) => switch (key) {
    'categoriesNameRequired' => l10n.categoriesNameRequired,
    'categoriesNameTooLong' => l10n.categoriesNameTooLong,
    'categoriesNameTaken' => l10n.categoriesNameTaken,
    'categoriesIconRequired' => l10n.categoriesIconRequired,
    'categoriesColorInvalid' => l10n.categoriesColorInvalid,
    'transactionAmountZero' => l10n.transactionAmountZero,
    'transactionAmountTooLarge' => l10n.transactionAmountTooLarge,
    'transactionNoteTooLong' => l10n.transactionNoteTooLong,
    'transactionCategoryRequired' => l10n.transactionCategoryRequired,
    'transactionDirectionUnsupported' => l10n.transactionDirectionUnsupported,
    'profileNameTooLong' => l10n.profileNameTooLong,
    'profileNameInvalid' => l10n.profileNameInvalid,
    'failureValidation' => l10n.failureValidation,
    'failureStorage' => l10n.failureStorage,
    'failureNetwork' => l10n.failureNetwork,
    'failureAuth' => l10n.failureAuth,
    'failureNotFound' => l10n.failureNotFound,
    'failureConflict' => l10n.failureConflict,
    'failureParse' => l10n.failureParse,
    'failureUnexpected' => l10n.failureUnexpected,
    'stateErrorTitle' => l10n.stateErrorTitle,
    'stateErrorBody' => l10n.stateErrorBody,
    'stateErrorRetry' => l10n.stateErrorRetry,
    'categoriesTitle' => l10n.categoriesTitle,
    'categoriesEmptyTitle' => l10n.categoriesEmptyTitle,
    'categoriesEmptyBody' => l10n.categoriesEmptyBody,
    'categoriesArchived' => l10n.categoriesArchived,
    'categoriesSelectHint' => l10n.categoriesSelectHint,
    'categoriesNew' => l10n.categoriesNew,
    'categoriesEdit' => l10n.categoriesEdit,
    'categoriesArchive' => l10n.categoriesArchive,
    'categoriesUnarchive' => l10n.categoriesUnarchive,
    'categoriesDelete' => l10n.categoriesDelete,
    'categoriesDeleted' => l10n.categoriesDeleted,
    'categoriesDeleteConfirmTitle' => l10n.categoriesDeleteConfirmTitle,
    'categoriesDeleteConfirmBody' => l10n.categoriesDeleteConfirmBody,
    'categoriesNameLabel' => l10n.categoriesNameLabel,
    'categoriesNameHint' => l10n.categoriesNameHint,
    'categoriesIconLabel' => l10n.categoriesIconLabel,
    'categoriesColorLabel' => l10n.categoriesColorLabel,
    'categoriesKindLabel' => l10n.categoriesKindLabel,
    'categoriesPreview' => l10n.categoriesPreview,
    'transactionNew' => l10n.transactionNew,
    'transactionEdit' => l10n.transactionEdit,
    'transactionAmountLabel' => l10n.transactionAmountLabel,
    'transactionCategoryLabel' => l10n.transactionCategoryLabel,
    'transactionCategoryChoose' => l10n.transactionCategoryChoose,
    'transactionDateLabel' => l10n.transactionDateLabel,
    'transactionNoteLabel' => l10n.transactionNoteLabel,
    'transactionNoteHint' => l10n.transactionNoteHint,
    'transactionDirectionExpense' => l10n.transactionDirectionExpense,
    'transactionDirectionIncome' => l10n.transactionDirectionIncome,
    'transactionSave' => l10n.transactionSave,
    'transactionSaved' => l10n.transactionSaved,
    'transactionDeleted' => l10n.transactionDeleted,
    'transactionUndo' => l10n.transactionUndo,
    'transactionFuture' => l10n.transactionFuture,
    'actionCancel' => l10n.actionCancel,
    'actionSave' => l10n.actionSave,
    'actionDelete' => l10n.actionDelete,
    'actionDone' => l10n.actionDone,
    'stateEmptyTitle' => l10n.stateEmptyTitle,
    'stateEmptyBody' => l10n.stateEmptyBody,
    'stateComingSoon' => l10n.stateComingSoon,
    'calendarSpentToday' => l10n.calendarSpentToday,
    'calendarIncome' => l10n.calendarIncome,
    'calendarExpense' => l10n.calendarExpense,
    'calendarNet' => l10n.calendarNet,
    'calendarToday' => l10n.calendarToday,
    'calendarEmptyDay' => l10n.calendarEmptyDay,
    'calendarSelectDay' => l10n.calendarSelectDay,
    'calendarPreviousMonth' => l10n.calendarPreviousMonth,
    'calendarNextMonth' => l10n.calendarNextMonth,
    'calendarPickMonth' => l10n.calendarPickMonth,
    'calendarPickMonthHint' => l10n.calendarPickMonthHint,
    'calendarPreviousYear' => l10n.calendarPreviousYear,
    'calendarNextYear' => l10n.calendarNextYear,
    'navigationCalendar' => l10n.navigationCalendar,
    'navigationCategories' => l10n.navigationCategories,
    'navigationInsights' => l10n.navigationInsights,
    'navigationSettings' => l10n.navigationSettings,
    'settingsTitle' => l10n.settingsTitle,
    'settingsPreferencesSection' => l10n.settingsPreferencesSection,
    'settingsCurrencyLabel' => l10n.settingsCurrencyLabel,
    'settingsCurrencyBody' => l10n.settingsCurrencyBody,
    'settingsLanguageLabel' => l10n.settingsLanguageLabel,
    'settingsLanguageSystem' => l10n.settingsLanguageSystem,
    'settingsThemeLabel' => l10n.settingsThemeLabel,
    'settingsThemeSystem' => l10n.settingsThemeSystem,
    'settingsThemeLight' => l10n.settingsThemeLight,
    'settingsThemeDark' => l10n.settingsThemeDark,
    'settingsWeekStartLabel' => l10n.settingsWeekStartLabel,
    'settingsWeekStartMonday' => l10n.settingsWeekStartMonday,
    'settingsWeekStartSunday' => l10n.settingsWeekStartSunday,
    'settingsSaved' => l10n.settingsSaved,
    'settingsSaveFailed' => l10n.settingsSaveFailed,
    'settingsAboutSection' => l10n.settingsAboutSection,
    'settingsVersionLabel' => l10n.settingsVersionLabel,
    'settingsCreditsTitle' => l10n.settingsCreditsTitle,
    'settingsCreditsAvatar' => l10n.settingsCreditsAvatar,
    'settingsMonthStartsOn' => l10n.settingsMonthStartsOn,
    'settingsMonthStartsOnDescription' => l10n.settingsMonthStartsOnDescription,
    'monthStartsOnTitle' => l10n.monthStartsOnTitle,
    'monthStartsOnDescription' => l10n.monthStartsOnDescription,
    'monthStartsOnTransactionsNotice' => l10n.monthStartsOnTransactionsNotice,
    'calendarPayCycle' => l10n.calendarPayCycle,
    'calendarThisPeriod' => l10n.calendarThisPeriod,
    'calendarSpentThisPeriod' => l10n.calendarSpentThisPeriod,
    'profileTitle' => l10n.profileTitle,
    'profileGuestBadge' => l10n.profileGuestBadge,
    'profileGuestBody' => l10n.profileGuestBody,
    'profileSignedOutBody' => l10n.profileSignedOutBody,
    'profileNameLabel' => l10n.profileNameLabel,
    'profileNameHint' => l10n.profileNameHint,
    'profileNamePlaceholder' => l10n.profileNamePlaceholder,
    'profileEditName' => l10n.profileEditName,
    'profileNameSaved' => l10n.profileNameSaved,
    'profileAvatarLabel' => l10n.profileAvatarLabel,
    'profileEditAvatar' => l10n.profileEditAvatar,
    'profileAvatarSaved' => l10n.profileAvatarSaved,
    'profileAvatarSaveFailed' => l10n.profileAvatarSaveFailed,
    'avatarEditorTitle' => l10n.avatarEditorTitle,
    'avatarEditorBackground' => l10n.avatarEditorBackground,
    'avatarEditorBackdrop' => l10n.avatarEditorBackdrop,
    'avatarEditorShape' => l10n.avatarEditorShape,
    'avatarEditorEyes' => l10n.avatarEditorEyes,
    'avatarEditorMouth' => l10n.avatarEditorMouth,
    'avatarEditorRandom' => l10n.avatarEditorRandom,
    'avatarEditorPreview' => l10n.avatarEditorPreview,
    'avatarEditorSave' => l10n.avatarEditorSave,
    'avatarEditorTabHead' => l10n.avatarEditorTabHead,
    'avatarEditorTabFace' => l10n.avatarEditorTabFace,
    'avatarEditorTabGlasses' => l10n.avatarEditorTabGlasses,
    'avatarEditorTabItem' => l10n.avatarEditorTabItem,
    'avatarEditorTabColors' => l10n.avatarEditorTabColors,
    'avatarEditorBeard' => l10n.avatarEditorBeard,
    'avatarEditorColorOutline' => l10n.avatarEditorColorOutline,
    'avatarEditorColorHair' => l10n.avatarEditorColorHair,
    'avatarEditorColorSkin' => l10n.avatarEditorColorSkin,
    'avatarEditorColorOutfit' => l10n.avatarEditorColorOutfit,
    'avatarEditorNone' => l10n.avatarEditorNone,
    'avatarEditorItemsComingSoon' => l10n.avatarEditorItemsComingSoon,
    'avatarEditorDiscardTitle' => l10n.avatarEditorDiscardTitle,
    'avatarEditorDiscardMessage' => l10n.avatarEditorDiscardMessage,
    'avatarEditorDiscardConfirm' => l10n.avatarEditorDiscardConfirm,
    'avatarEditorKeepEditing' => l10n.avatarEditorKeepEditing,
    'appTitle' => l10n.appTitle,
    'insightsTitle' => l10n.insightsTitle,
    'insightsTotalIncome' => l10n.insightsTotalIncome,
    'insightsTotalExpense' => l10n.insightsTotalExpense,
    'insightsNetSavings' => l10n.insightsNetSavings,
    'insightsVsPreviousPeriod' => l10n.insightsVsPreviousPeriod,
    'insightsSpendingByCategory' => l10n.insightsSpendingByCategory,
    'insightsIncomeVsExpense' => l10n.insightsIncomeVsExpense,
    'insightsCashFlowTrend' => l10n.insightsCashFlowTrend,
    'insightsTopCategories' => l10n.insightsTopCategories,
    'insightsNoDataTitle' => l10n.insightsNoDataTitle,
    'insightsNoDataBody' => l10n.insightsNoDataBody,
    'insightsPreviousPeriod' => l10n.insightsPreviousPeriod,
    'insightsNextPeriod' => l10n.insightsNextPeriod,
    // Unknown keys resolve to the generic validation message rather than the raw
    // key: a validator added ahead of its translation should read like an error,
    // not like a bug report.
    _ => l10n.failureValidation,
  };
}
