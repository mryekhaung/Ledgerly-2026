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
    'transactionsTitle' => l10n.transactionsTitle,
    'transactionsSearchHint' => l10n.transactionsSearchHint,
    'filterTitle' => l10n.filterTitle,
    'filterAll' => l10n.filterAll,
    'filterIncome' => l10n.filterIncome,
    'filterExpense' => l10n.filterExpense,
    'filterCategory' => l10n.filterCategory,
    'filterDateRange' => l10n.filterDateRange,
    'filterStartDate' => l10n.filterStartDate,
    'filterEndDate' => l10n.filterEndDate,
    'filterAmount' => l10n.filterAmount,
    'filterMinAmount' => l10n.filterMinAmount,
    'filterMaxAmount' => l10n.filterMaxAmount,
    'filterClearAll' => l10n.filterClearAll,
    'filterApply' => l10n.filterApply,
    'transactionsNoResultsTitle' => l10n.transactionsNoResultsTitle,
    'transactionsNoResultsBody' => l10n.transactionsNoResultsBody,
    'welcomeTitle' => l10n.welcomeTitle,
    'welcomeSubtitle' => l10n.welcomeSubtitle,
    'welcomeMonthStartQuestion' => l10n.welcomeMonthStartQuestion,
    'welcomeMonthStartHelp' => l10n.welcomeMonthStartHelp,
    'welcomeGetStarted' => l10n.welcomeGetStarted,
    'welcomeSkip' => l10n.welcomeSkip,
    'continueAsGuest' => l10n.continueAsGuest,
    'signInWithGoogle' => l10n.signInWithGoogle,
    'signInWithApple' => l10n.signInWithApple,
    'signInWithEmail' => l10n.signInWithEmail,
    'signInTitle' => l10n.signInTitle,
    'signUpTitle' => l10n.signUpTitle,
    'emailLabel' => l10n.emailLabel,
    'passwordLabel' => l10n.passwordLabel,
    'displayNameLabel' => l10n.displayNameLabel,
    'forgotPassword' => l10n.forgotPassword,
    'noAccountPrompt' => l10n.noAccountPrompt,
    'haveAccountPrompt' => l10n.haveAccountPrompt,
    'accountTitle' => l10n.accountTitle,
    'accountGuestBadge' => l10n.accountGuestBadge,
    'accountLinkedBadge' => l10n.accountLinkedBadge,
    'accountLinkBannerTitle' => l10n.accountLinkBannerTitle,
    'accountLinkBannerBody' => l10n.accountLinkBannerBody,
    'accountLinkGoogle' => l10n.accountLinkGoogle,
    'accountLinkApple' => l10n.accountLinkApple,
    'accountSignOut' => l10n.accountSignOut,
    'accountSignOutConfirm' => l10n.accountSignOutConfirm,
    'accountDeleteTitle' => l10n.accountDeleteTitle,
    'accountDeleteBody' => l10n.accountDeleteBody,
    'accountDeleteConfirm' => l10n.accountDeleteConfirm,
    'accountDeletedSuccess' => l10n.accountDeletedSuccess,
    'authErrorInvalidCredentials' => l10n.authErrorInvalidCredentials,
    'authErrorEmailAlreadyInUse' => l10n.authErrorEmailAlreadyInUse,
    'settingsDataTransfer' => l10n.settingsDataTransfer,
    'settingsDataTransferSubtitle' => l10n.settingsDataTransferSubtitle,
    'dataTransferTitle' => l10n.dataTransferTitle,
    'dataTransferTabExport' => l10n.dataTransferTabExport,
    'dataTransferTabImport' => l10n.dataTransferTabImport,
    'dataTransferTabBackup' => l10n.dataTransferTabBackup,
    'exportFormatLabel' => l10n.exportFormatLabel,
    'exportRangeLabel' => l10n.exportRangeLabel,
    'exportPresetThisPeriod' => l10n.exportPresetThisPeriod,
    'exportPresetLastPeriod' => l10n.exportPresetLastPeriod,
    'exportPresetAllTime' => l10n.exportPresetAllTime,
    'exportPresetCustom' => l10n.exportPresetCustom,
    'exportSummaryTitle' => l10n.exportSummaryTitle,
    'exportActionExport' => l10n.exportActionExport,
    'exportSuccessCopied' => l10n.exportSuccessCopied,
    'exportTotalRecords' => l10n.exportTotalRecords,
    'exportTotalIncome' => l10n.exportTotalIncome,
    'exportTotalExpense' => l10n.exportTotalExpense,
    'importSourceLabel' => l10n.importSourceLabel,
    'importPasteHint' => l10n.importPasteHint,
    'importActionParse' => l10n.importActionParse,
    'importPreviewTitle' => l10n.importPreviewTitle,
    'importTotalRows' => l10n.importTotalRows,
    'importValidRows' => l10n.importValidRows,
    'importDuplicateRows' => l10n.importDuplicateRows,
    'importNewCategories' => l10n.importNewCategories,
    'importSkipDuplicates' => l10n.importSkipDuplicates,
    'importAutoCreateCategories' => l10n.importAutoCreateCategories,
    'importActionExecute' => l10n.importActionExecute,
    'importSuccess' => l10n.importSuccess,
    'backupTitle' => l10n.backupTitle,
    'backupDescription' => l10n.backupDescription,
    'backupActionCreate' => l10n.backupActionCreate,
    'backupCreatedSuccess' => l10n.backupCreatedSuccess,
    'restoreTitle' => l10n.restoreTitle,
    'restorePasteHint' => l10n.restorePasteHint,
    'restoreActionParse' => l10n.restoreActionParse,
    'restoreActionExecute' => l10n.restoreActionExecute,
    'restoreModeMerge' => l10n.restoreModeMerge,
    'restoreModeOverwrite' => l10n.restoreModeOverwrite,
    'restoreOverwriteWarning' => l10n.restoreOverwriteWarning,
    'restoreSuccess' => l10n.restoreSuccess,
    'accountsTitle' => l10n.accountsTitle,
    'accountsSubtitle' => l10n.accountsSubtitle,
    'accountsNetWorth' => l10n.accountsNetWorth,
    'accountsActiveTab' => l10n.accountsActiveTab,
    'accountsArchivedTab' => l10n.accountsArchivedTab,
    'accountsEmptyTitle' => l10n.accountsEmptyTitle,
    'accountsEmptyBody' => l10n.accountsEmptyBody,
    'accountsAddButton' => l10n.accountsAddButton,
    'accountsEditTitle' => l10n.accountsEditTitle,
    'accountsNewTitle' => l10n.accountsNewTitle,
    'accountsTransferButton' => l10n.accountsTransferButton,
    'accountsTransferTitle' => l10n.accountsTransferTitle,
    'accountsTransferFrom' => l10n.accountsTransferFrom,
    'accountsTransferTo' => l10n.accountsTransferTo,
    'accountsTransferAmount' => l10n.accountsTransferAmount,
    'accountsTransferDate' => l10n.accountsTransferDate,
    'accountsTransferNote' => l10n.accountsTransferNote,
    'accountsTransferSubmit' => l10n.accountsTransferSubmit,
    'accountsTransferSuccess' => l10n.accountsTransferSuccess,
    'accountFieldName' => l10n.accountFieldName,
    'accountFieldType' => l10n.accountFieldType,
    'accountFieldCurrency' => l10n.accountFieldCurrency,
    'accountFieldOpeningBalance' => l10n.accountFieldOpeningBalance,
    'accountFieldIcon' => l10n.accountFieldIcon,
    'accountFieldColor' => l10n.accountFieldColor,
    'accountFieldIncludeInTotal' => l10n.accountFieldIncludeInTotal,
    'accountTypeCash' => l10n.accountTypeCash,
    'accountTypeBank' => l10n.accountTypeBank,
    'accountTypeCredit' => l10n.accountTypeCredit,
    'accountTypeSavings' => l10n.accountTypeSavings,
    'accountTypeEwallet' => l10n.accountTypeEwallet,
    'accountSavedSuccess' => l10n.accountSavedSuccess,
    'accountArchiveSuccess' => l10n.accountArchiveSuccess,
    'accountUnarchiveSuccess' => l10n.accountUnarchiveSuccess,
    'accountConfirmDelete' => l10n.accountConfirmDelete,
    'accountConfirmDeleteMessage' => l10n.accountConfirmDeleteMessage,
    'accountsNameRequired' => l10n.accountsNameRequired,
    'accountsNameTooLong' => l10n.accountsNameTooLong,
    'accountsNameTaken' => l10n.accountsNameTaken,
    'accountsTransferSameAccount' => l10n.accountsTransferSameAccount,
    'accountsTransferAmountInvalid' => l10n.accountsTransferAmountInvalid,
    'budgetsTitle' => l10n.budgetsTitle,
    'budgetsTotal' => l10n.budgetsTotal,
    'budgetsCategory' => l10n.budgetsCategory,
    'budgetsNew' => l10n.budgetsNew,
    'budgetsEdit' => l10n.budgetsEdit,
    'budgetsDelete' => l10n.budgetsDelete,
    'budgetsEmptyTitle' => l10n.budgetsEmptyTitle,
    'budgetsEmptyBody' => l10n.budgetsEmptyBody,
    'budgetFieldCategory' => l10n.budgetFieldCategory,
    'budgetFieldAmount' => l10n.budgetFieldAmount,
    'budgetFieldPeriod' => l10n.budgetFieldPeriod,
    'budgetFieldThreshold' => l10n.budgetFieldThreshold,
    'budgetTotalOption' => l10n.budgetTotalOption,
    'budgetSpent' => l10n.budgetSpent,
    'budgetRemaining' => l10n.budgetRemaining,
    'budgetDailyRemaining' => l10n.budgetDailyRemaining,
    'budgetStatusSafe' => l10n.budgetStatusSafe,
    'budgetStatusWarning' => l10n.budgetStatusWarning,
    'budgetStatusExceeded' => l10n.budgetStatusExceeded,
    'budgetSavedSuccess' => l10n.budgetSavedSuccess,
    'budgetDeletedSuccess' => l10n.budgetDeletedSuccess,
    'budgetArchiveSuccess' => l10n.budgetArchiveSuccess,
    'budgetUnarchiveSuccess' => l10n.budgetUnarchiveSuccess,
    'budgetConfirmDelete' => l10n.budgetConfirmDelete,
    'budgetConfirmDeleteMessage' => l10n.budgetConfirmDeleteMessage,
    'budgetAmountInvalid' => l10n.budgetAmountInvalid,
    'budgetThresholdInvalid' => l10n.budgetThresholdInvalid,
    'budgetDuplicateCategory' => l10n.budgetDuplicateCategory,
    'budgetDuplicateTotal' => l10n.budgetDuplicateTotal,
    'budgetOverallSummary' => l10n.budgetOverallSummary,
    'recurringTitle' => l10n.recurringTitle,
    'recurringSubtitle' => l10n.recurringSubtitle,
    'recurringNew' => l10n.recurringNew,
    'recurringEdit' => l10n.recurringEdit,
    'recurringEmptyTitle' => l10n.recurringEmptyTitle,
    'recurringEmptyBody' => l10n.recurringEmptyBody,
    'recurringProcessNow' => l10n.recurringProcessNow,
    'recurringFrequencyDaily' => l10n.recurringFrequencyDaily,
    'recurringFrequencyWeekly' => l10n.recurringFrequencyWeekly,
    'recurringFrequencyMonthly' => l10n.recurringFrequencyMonthly,
    'recurringFrequencyYearly' => l10n.recurringFrequencyYearly,
    'recurringFieldFrequency' => l10n.recurringFieldFrequency,
    'recurringFieldStartDate' => l10n.recurringFieldStartDate,
    'recurringFieldEndDate' => l10n.recurringFieldEndDate,
    'recurringFieldHasEndDate' => l10n.recurringFieldHasEndDate,
    'recurringFieldAutoAdd' => l10n.recurringFieldAutoAdd,
    'recurringFieldAutoAddDesc' => l10n.recurringFieldAutoAddDesc,
    'recurringDueToday' => l10n.recurringDueToday,
    'recurringDueTomorrow' => l10n.recurringDueTomorrow,
    'recurringActionSkip' => l10n.recurringActionSkip,
    'recurringActionPause' => l10n.recurringActionPause,
    'recurringActionResume' => l10n.recurringActionResume,
    'recurringActionDelete' => l10n.recurringActionDelete,
    'recurringSkippedSuccess' => l10n.recurringSkippedSuccess,
    'recurringSavedSuccess' => l10n.recurringSavedSuccess,
    'recurringDeletedSuccess' => l10n.recurringDeletedSuccess,
    'recurringConfirmDelete' => l10n.recurringConfirmDelete,
    'recurringConfirmDeleteMessage' => l10n.recurringConfirmDeleteMessage,
    'recurringErrorAmountPositive' => l10n.recurringErrorAmountPositive,
    'recurringErrorCategoryRequired' => l10n.recurringErrorCategoryRequired,
    'recurringErrorEndDateBeforeStart' => l10n.recurringErrorEndDateBeforeStart,
    'recurringPendingBannerTitle' => l10n.recurringPendingBannerTitle,
    'recurringPendingActionConfirm' => l10n.recurringPendingActionConfirm,
    // Unknown keys resolve to the generic validation message rather than the raw
    // key: a validator added ahead of its translation should read like an error,
    // not like a bug report.
    _ => l10n.failureValidation,
  };
}
