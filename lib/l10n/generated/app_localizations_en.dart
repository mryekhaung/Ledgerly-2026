// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ledgerly';

  @override
  String get navigationCalendar => 'Calendar';

  @override
  String get navigationInsights => 'Insights';

  @override
  String get navigationCategories => 'Categories';

  @override
  String get navigationSettings => 'Settings';

  @override
  String get stateEmptyTitle => 'Nothing here yet';

  @override
  String get stateEmptyBody => 'Tap + to add your first transaction.';

  @override
  String get stateErrorTitle => 'Something went wrong';

  @override
  String get stateErrorBody => 'We couldn\'t load this. Please try again.';

  @override
  String get stateErrorRetry => 'Retry';

  @override
  String get stateComingSoon =>
      'This part isn\'t built yet. It\'s planned and coming.';

  @override
  String get failureStorage =>
      'Couldn\'t read your saved data. Please try again.';

  @override
  String get failureNetwork =>
      'No connection. Check your network and try again.';

  @override
  String get failureAuth => 'Sign-in didn\'t complete. Please try again.';

  @override
  String get failureValidation => 'Please check the highlighted fields.';

  @override
  String get failureNotFound => 'We couldn\'t find that item.';

  @override
  String get failureConflict => 'That conflicts with something already saved.';

  @override
  String get failureParse =>
      'This file couldn\'t be read. Check the format and try again.';

  @override
  String get failureUnexpected =>
      'Something unexpected happened. Please try again.';

  @override
  String get calendarSpentToday => 'Spent today';

  @override
  String get calendarIncome => 'Income';

  @override
  String get calendarExpense => 'Expense';

  @override
  String get calendarNet => 'Net';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarEmptyDay => 'Nothing on this day';

  @override
  String get calendarSelectDay => 'Select a day';

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarPickMonth => 'Jump to month';

  @override
  String get calendarPickMonthHint => 'Pick any month to jump straight to it.';

  @override
  String get calendarPreviousYear => 'Previous year';

  @override
  String get calendarNextYear => 'Next year';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesEmptyTitle => 'No categories yet';

  @override
  String get categoriesEmptyBody =>
      'Create one to start logging your spending.';

  @override
  String get categoriesSelectHint =>
      'Pick a category to edit, or create a new one.';

  @override
  String get categoriesArchived => 'Archived';

  @override
  String get categoriesNew => 'New category';

  @override
  String get categoriesEdit => 'Edit category';

  @override
  String get categoriesArchive => 'Archive';

  @override
  String get categoriesUnarchive => 'Unarchive';

  @override
  String get categoriesDelete => 'Delete';

  @override
  String get categoriesDeleted => 'Category deleted';

  @override
  String get categoriesDeleteConfirmTitle => 'Delete this category?';

  @override
  String get categoriesDeleteConfirmBody =>
      'Transactions already filed under it keep their history.';

  @override
  String get categoriesNameLabel => 'Name';

  @override
  String get categoriesNameHint => 'e.g. Groceries';

  @override
  String get categoriesIconLabel => 'Icon';

  @override
  String get categoriesColorLabel => 'Color';

  @override
  String get categoriesKindLabel => 'Type';

  @override
  String get categoriesPreview => 'Preview';

  @override
  String get categoriesNameRequired => 'Give the category a name.';

  @override
  String get categoriesNameTooLong => 'Keep the name under 60 characters.';

  @override
  String get categoriesNameTaken => 'Another category already uses that name.';

  @override
  String get categoriesIconRequired => 'Pick an icon.';

  @override
  String get categoriesColorInvalid => 'Pick a color.';

  @override
  String get transactionNew => 'Add transaction';

  @override
  String get transactionEdit => 'Edit transaction';

  @override
  String get transactionAmountLabel => 'Amount';

  @override
  String get transactionCategoryLabel => 'Category';

  @override
  String get transactionCategoryChoose => 'Choose a category';

  @override
  String get transactionDateLabel => 'Date';

  @override
  String get transactionNoteLabel => 'Note';

  @override
  String get transactionNoteHint => 'Optional';

  @override
  String get transactionDirectionExpense => 'Expense';

  @override
  String get transactionDirectionIncome => 'Income';

  @override
  String get transactionSave => 'Save';

  @override
  String get transactionSaved => 'Transaction saved';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String get transactionUndo => 'Undo';

  @override
  String get transactionAmountZero => 'Enter an amount.';

  @override
  String get transactionAmountTooLarge => 'That amount is too large.';

  @override
  String get transactionNoteTooLong => 'Keep the note under 500 characters.';

  @override
  String get transactionCategoryRequired => 'Pick a category.';

  @override
  String get transactionDirectionUnsupported =>
      'Transfers aren\'t available yet.';

  @override
  String get transactionFuture => 'That date is in the future.';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionDone => 'Done';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPreferencesSection => 'Preferences';

  @override
  String get settingsCurrencyLabel => 'Currency';

  @override
  String get settingsCurrencyBody =>
      'How amounts are shown throughout the app.';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsThemeLabel => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsWeekStartLabel => 'Week starts on';

  @override
  String get settingsWeekStartMonday => 'Monday';

  @override
  String get settingsWeekStartSunday => 'Sunday';

  @override
  String get settingsSaved => 'Settings saved.';

  @override
  String get settingsSaveFailed => 'Couldn\'t save that. Please try again.';

  @override
  String get settingsAboutSection => 'About';

  @override
  String get settingsVersionLabel => 'Version';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileGuestBadge => 'Guest';

  @override
  String get profileGuestBody =>
      'You\'re using Ledgerly as a guest. Your data stays on this device.';

  @override
  String get profileSignedOutBody => 'Sign in to sync across devices.';

  @override
  String get profileNameLabel => 'Name';

  @override
  String get profileNameHint => 'Add your name';

  @override
  String get profileNamePlaceholder => 'Your name';

  @override
  String get profileEditName => 'Edit name';

  @override
  String get profileNameSaved => 'Name saved.';

  @override
  String get profileNameTooLong =>
      'That name is a bit long. Try 40 characters or fewer.';

  @override
  String get profileNameInvalid =>
      'That name has characters we can\'t use. Try text only.';

  @override
  String get profileAvatarLabel => 'Avatar';

  @override
  String get profileEditAvatar => 'Edit avatar';

  @override
  String get profileAvatarSaved => 'Avatar updated.';

  @override
  String get profileAvatarSaveFailed =>
      'Couldn\'t save that. Please try again.';

  @override
  String get avatarEditorTitle => 'Avatar';

  @override
  String get avatarEditorBackground => 'Background';

  @override
  String get avatarEditorBackdrop => 'Backdrop';

  @override
  String get avatarEditorShape => 'Shape';

  @override
  String get avatarEditorEyes => 'Eyes';

  @override
  String get avatarEditorMouth => 'Mouth';

  @override
  String get avatarEditorRandom => 'Shuffle';

  @override
  String get avatarEditorPreview => 'Preview';

  @override
  String get avatarEditorSave => 'Save';

  @override
  String avatarEditorOptionLabel(String part, int number) {
    return '$part option $number';
  }

  @override
  String avatarEditorPartSelected(String part, String value) {
    return '$part: $value';
  }

  @override
  String get avatarEditorTabHead => 'Head';

  @override
  String get avatarEditorTabFace => 'Face';

  @override
  String get avatarEditorTabGlasses => 'Glasses';

  @override
  String get avatarEditorTabItem => 'Item';

  @override
  String get avatarEditorTabColors => 'Colors';

  @override
  String get avatarEditorBeard => 'Facial Hair';

  @override
  String get avatarEditorColorOutline => 'Outline';

  @override
  String get avatarEditorColorHair => 'Hair';

  @override
  String get avatarEditorColorSkin => 'Skin tone';

  @override
  String get avatarEditorColorOutfit => 'Outfit';

  @override
  String get avatarEditorNone => 'None';

  @override
  String get avatarEditorItemsComingSoon => 'More items coming soon';

  @override
  String get avatarEditorDiscardTitle => 'Discard changes?';

  @override
  String get avatarEditorDiscardMessage =>
      'You have unsaved changes. Do you want to discard them?';

  @override
  String get avatarEditorDiscardConfirm => 'Discard';

  @override
  String get avatarEditorKeepEditing => 'Keep editing';

  @override
  String get settingsCreditsTitle => 'Credits';

  @override
  String get settingsCreditsAvatar =>
      'Avatar art: Open Peeps by Pablo Stanley (CC0 1.0), via DiceBear';

  @override
  String get settingsMonthStartsOn => 'Month starts on';

  @override
  String get settingsMonthStartsOnDescription =>
      'Align budget cycles with your pay day';

  @override
  String get monthStartsOnTitle => 'Month starts on';

  @override
  String get monthStartsOnDescription =>
      'Choose the day of the month your budget begins (1–28). Days 29–31 are excluded so February is never ambiguous.';

  @override
  String monthStartsOnCurrentPeriod(String range) {
    return 'Current period: $range';
  }

  @override
  String monthStartsOnPreviousPeriod(String range) {
    return 'Previous: $range';
  }

  @override
  String get monthStartsOnTransactionsNotice =>
      'Your transactions are not changed.';

  @override
  String monthStartsOnDayFormat(int day) {
    return 'Day $day';
  }

  @override
  String get calendarPayCycle => 'Pay cycle';

  @override
  String get calendarThisPeriod => 'This period';

  @override
  String get calendarSpentThisPeriod => 'Spent this period';

  @override
  String get insightsTitle => 'Insights';

  @override
  String get insightsTotalIncome => 'Total Income';

  @override
  String get insightsTotalExpense => 'Total Expense';

  @override
  String get insightsNetSavings => 'Net Balance';

  @override
  String get insightsVsPreviousPeriod => 'vs previous period';

  @override
  String get insightsSpendingByCategory => 'Spending Breakdown';

  @override
  String get insightsIncomeVsExpense => 'Income vs Expense';

  @override
  String get insightsCashFlowTrend => 'Cash Flow Trend';

  @override
  String get insightsTopCategories => 'Top Categories';

  @override
  String get insightsNoDataTitle => 'No transactions yet';

  @override
  String get insightsNoDataBody =>
      'Add transactions in this period to see your financial analytics.';

  @override
  String get insightsPreviousPeriod => 'Previous period';

  @override
  String get insightsNextPeriod => 'Next period';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get transactionsSearchHint => 'Search note or category...';

  @override
  String get filterTitle => 'Filters';

  @override
  String get filterAll => 'All';

  @override
  String get filterIncome => 'Income';

  @override
  String get filterExpense => 'Expense';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterDateRange => 'Date Range';

  @override
  String get filterStartDate => 'Start date';

  @override
  String get filterEndDate => 'End date';

  @override
  String get filterAmount => 'Amount';

  @override
  String get filterMinAmount => 'Min amount';

  @override
  String get filterMaxAmount => 'Max amount';

  @override
  String get filterClearAll => 'Clear all';

  @override
  String get filterApply => 'Apply';

  @override
  String get transactionsNoResultsTitle => 'No transactions found';

  @override
  String get transactionsNoResultsBody =>
      'Try adjusting your search or filters to find what you\'re looking for.';

  @override
  String get welcomeTitle => 'Welcome to Ledgerly';

  @override
  String get welcomeSubtitle => 'Master your money, effortlessly.';

  @override
  String get welcomeMonthStartQuestion => 'When does your month start?';

  @override
  String get welcomeMonthStartHelp =>
      'Choose the day your income or pay cycle begins. You can change this anytime.';

  @override
  String get welcomeGetStarted => 'Get Started';

  @override
  String get welcomeSkip => 'Skip for now';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get signInWithEmail => 'Sign in with Email';

  @override
  String get signInTitle => 'Sign In';

  @override
  String get signUpTitle => 'Create Account';

  @override
  String get emailLabel => 'Email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get displayNameLabel => 'Name';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccountPrompt => 'Don\'t have an account? Sign up';

  @override
  String get haveAccountPrompt => 'Already have an account? Sign in';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountGuestBadge => 'Guest Account';

  @override
  String get accountLinkedBadge => 'Synced Account';

  @override
  String get accountLinkBannerTitle => 'Save your data securely';

  @override
  String get accountLinkBannerBody =>
      'Link your guest account to keep your finances backed up across devices.';

  @override
  String get accountLinkGoogle => 'Link Google Account';

  @override
  String get accountLinkApple => 'Link Apple ID';

  @override
  String get accountSignOut => 'Sign Out';

  @override
  String get accountSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get accountDeleteTitle => 'Delete Account';

  @override
  String get accountDeleteBody =>
      'This will permanently delete your account and all associated local and cloud data. This action cannot be undone.';

  @override
  String get accountDeleteConfirm => 'Delete permanently';

  @override
  String get accountDeletedSuccess => 'Account successfully deleted';

  @override
  String get authErrorInvalidCredentials => 'Invalid email or password';

  @override
  String get authErrorEmailAlreadyInUse => 'This email is already in use';
}
