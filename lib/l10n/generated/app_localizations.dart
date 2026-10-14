import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_my.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('my'),
  ];

  /// The application name shown in the task switcher and stores.
  ///
  /// In en, this message translates to:
  /// **'Ledgerly'**
  String get appTitle;

  /// Primary navigation destination label.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navigationCalendar;

  /// Primary navigation destination label.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navigationInsights;

  /// Primary navigation destination label.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navigationCategories;

  /// Primary navigation destination label.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navigationSettings;

  /// Generic empty-state heading.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get stateEmptyTitle;

  /// Generic empty-state supporting text.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first transaction.'**
  String get stateEmptyBody;

  /// Inline error banner heading.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get stateErrorTitle;

  /// Inline error banner supporting text.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this. Please try again.'**
  String get stateErrorBody;

  /// Retry button in the error banner.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get stateErrorRetry;

  /// Body for a destination whose feature has not shipped.
  ///
  /// In en, this message translates to:
  /// **'This part isn\'t built yet. It\'s planned and coming.'**
  String get stateComingSoon;

  /// Maps StorageFailure to user-facing text.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read your saved data. Please try again.'**
  String get failureStorage;

  /// Maps NetworkFailure to user-facing text.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get failureNetwork;

  /// Maps AuthFailure to user-facing text.
  ///
  /// In en, this message translates to:
  /// **'Sign-in didn\'t complete. Please try again.'**
  String get failureAuth;

  /// Maps ValidationFailure to user-facing text.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields.'**
  String get failureValidation;

  /// Maps NotFoundFailure to user-facing text.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that item.'**
  String get failureNotFound;

  /// Maps ConflictFailure to user-facing text.
  ///
  /// In en, this message translates to:
  /// **'That conflicts with something already saved.'**
  String get failureConflict;

  /// Maps ParseFailure to user-facing text.
  ///
  /// In en, this message translates to:
  /// **'This file couldn\'t be read. Check the format and try again.'**
  String get failureParse;

  /// Maps UnexpectedFailure to user-facing text.
  ///
  /// In en, this message translates to:
  /// **'Something unexpected happened. Please try again.'**
  String get failureUnexpected;

  /// Eyebrow above the hero amount on the calendar summary card.
  ///
  /// In en, this message translates to:
  /// **'Spent today'**
  String get calendarSpentToday;

  /// Summary card column label for money in.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get calendarIncome;

  /// Summary card column label for money out.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get calendarExpense;

  /// Summary card column label for net (income minus expense).
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get calendarNet;

  /// Button that jumps the calendar back to the current month.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// Empty state heading for the selected-day transaction list.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day'**
  String get calendarEmptyDay;

  /// Two-pane placeholder shown before a day has been picked.
  ///
  /// In en, this message translates to:
  /// **'Select a day'**
  String get calendarSelectDay;

  /// Accessibility label for the previous-month arrow.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPreviousMonth;

  /// Accessibility label for the next-month arrow.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNextMonth;

  /// App-bar title of the month/year picker opened from the calendar header.
  ///
  /// In en, this message translates to:
  /// **'Jump to month'**
  String get calendarPickMonth;

  /// Supporting hint at the bottom of the month/year picker.
  ///
  /// In en, this message translates to:
  /// **'Pick any month to jump straight to it.'**
  String get calendarPickMonthHint;

  /// Accessibility label for the previous-year arrow in the month picker.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get calendarPreviousYear;

  /// Accessibility label for the next-year arrow in the month picker.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get calendarNextYear;

  /// App-bar title of the categories list page.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// Empty-state heading when the user has no categories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get categoriesEmptyTitle;

  /// Empty-state supporting text for the categories list.
  ///
  /// In en, this message translates to:
  /// **'Create one to start logging your spending.'**
  String get categoriesEmptyBody;

  /// Placeholder in the wide layout's detail pane before a category is selected.
  ///
  /// In en, this message translates to:
  /// **'Pick a category to edit, or create a new one.'**
  String get categoriesSelectHint;

  /// Section heading above archived categories.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get categoriesArchived;

  /// Action that opens the category form in create mode.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoriesNew;

  /// App-bar title of the category form in edit mode.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get categoriesEdit;

  /// Menu action that archives a category.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get categoriesArchive;

  /// Menu action that restores an archived category.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get categoriesUnarchive;

  /// Menu action that soft-deletes a category.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get categoriesDelete;

  /// Snack-bar confirmation after deleting a category; carries an Undo action.
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get categoriesDeleted;

  /// Confirmation dialog heading before deleting a category.
  ///
  /// In en, this message translates to:
  /// **'Delete this category?'**
  String get categoriesDeleteConfirmTitle;

  /// Confirmation dialog body explaining deletion keeps history.
  ///
  /// In en, this message translates to:
  /// **'Transactions already filed under it keep their history.'**
  String get categoriesDeleteConfirmBody;

  /// Text-field label for the category name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get categoriesNameLabel;

  /// Placeholder example inside the category name field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Groceries'**
  String get categoriesNameHint;

  /// Section label above the icon grid.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoriesIconLabel;

  /// Section label above the color palette.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get categoriesColorLabel;

  /// Section label above the income/expense segmented control.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get categoriesKindLabel;

  /// Section label above the live preview of the category row.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get categoriesPreview;

  /// Validation message when the category name is blank.
  ///
  /// In en, this message translates to:
  /// **'Give the category a name.'**
  String get categoriesNameRequired;

  /// Validation message when the category name is too long.
  ///
  /// In en, this message translates to:
  /// **'Keep the name under 60 characters.'**
  String get categoriesNameTooLong;

  /// Validation message when the category name is a duplicate.
  ///
  /// In en, this message translates to:
  /// **'Another category already uses that name.'**
  String get categoriesNameTaken;

  /// Validation message when no icon has been chosen.
  ///
  /// In en, this message translates to:
  /// **'Pick an icon.'**
  String get categoriesIconRequired;

  /// Validation message when no color has been chosen.
  ///
  /// In en, this message translates to:
  /// **'Pick a color.'**
  String get categoriesColorInvalid;

  /// App-bar title of the add-transaction page.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get transactionNew;

  /// App-bar title of the edit-transaction page.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get transactionEdit;

  /// Label above the amount keypad display.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionAmountLabel;

  /// Label of the category picker row.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get transactionCategoryLabel;

  /// Placeholder in the category picker when nothing is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get transactionCategoryChoose;

  /// Label of the date picker row.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactionDateLabel;

  /// Label of the optional note field.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get transactionNoteLabel;

  /// Placeholder inside the optional note field.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get transactionNoteHint;

  /// Segmented-control label for money out.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionDirectionExpense;

  /// Segmented-control label for money in.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionDirectionIncome;

  /// Primary action that saves the transaction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get transactionSave;

  /// Snack-bar confirmation after saving a transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved'**
  String get transactionSaved;

  /// Snack-bar confirmation after deleting a transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionDeleted;

  /// Snack-bar action that restores a just-deleted transaction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get transactionUndo;

  /// Validation message when the amount is zero.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount.'**
  String get transactionAmountZero;

  /// Validation message when the amount exceeds the safe digit limit.
  ///
  /// In en, this message translates to:
  /// **'That amount is too large.'**
  String get transactionAmountTooLarge;

  /// Validation message when the note is too long.
  ///
  /// In en, this message translates to:
  /// **'Keep the note under 500 characters.'**
  String get transactionNoteTooLong;

  /// Validation message when no category has been chosen.
  ///
  /// In en, this message translates to:
  /// **'Pick a category.'**
  String get transactionCategoryRequired;

  /// Validation message for the transfer direction in v1.
  ///
  /// In en, this message translates to:
  /// **'Transfers aren\'t available yet.'**
  String get transactionDirectionUnsupported;

  /// Warning shown when the chosen date is ahead of today.
  ///
  /// In en, this message translates to:
  /// **'That date is in the future.'**
  String get transactionFuture;

  /// Generic cancel action in dialogs and sheets.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Generic save action.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Generic destructive action.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Generic dismiss/confirm action for sheets.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// Settings page title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Section header for the currency/language/theme/week-start group.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferencesSection;

  /// Settings row label for the display currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrencyLabel;

  /// Supporting text under the currency setting.
  ///
  /// In en, this message translates to:
  /// **'How amounts are shown throughout the app.'**
  String get settingsCurrencyBody;

  /// Settings row label for the display language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageLabel;

  /// Language option that follows the device setting.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// Settings row label for light/dark mode.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsThemeLabel;

  /// Theme option that follows the device setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Light theme option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Dark theme option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Settings row label for the first day of the calendar week.
  ///
  /// In en, this message translates to:
  /// **'Week starts on'**
  String get settingsWeekStartLabel;

  /// Week-start option: Monday first.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get settingsWeekStartMonday;

  /// Week-start option: Sunday first.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get settingsWeekStartSunday;

  /// Confirmation shown after a preference is stored.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get settingsSaved;

  /// Shown when writing a preference fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that. Please try again.'**
  String get settingsSaveFailed;

  /// Section header for the version/build info group.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutSection;

  /// About row label for the app version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersionLabel;

  /// App bar title for the Profile page.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Badge shown when the user has not signed in.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get profileGuestBadge;

  /// Explains the guest state on the Profile page.
  ///
  /// In en, this message translates to:
  /// **'You\'re using Ledgerly as a guest. Your data stays on this device.'**
  String get profileGuestBody;

  /// Placeholder for the future account state.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync across devices.'**
  String get profileSignedOutBody;

  /// Profile row label for the display name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileNameLabel;

  /// Placeholder when the user has not set a name.
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get profileNameHint;

  /// Text field placeholder in the name dialog.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get profileNamePlaceholder;

  /// Action that opens the name editor.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get profileEditName;

  /// Confirmation after the name is stored.
  ///
  /// In en, this message translates to:
  /// **'Name saved.'**
  String get profileNameSaved;

  /// Validation error for an over-long display name.
  ///
  /// In en, this message translates to:
  /// **'That name is a bit long. Try 40 characters or fewer.'**
  String get profileNameTooLong;

  /// Validation error for control characters in a display name.
  ///
  /// In en, this message translates to:
  /// **'That name has characters we can\'t use. Try text only.'**
  String get profileNameInvalid;

  /// Profile row label for the avatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get profileAvatarLabel;

  /// Action that opens the Avatar Editor.
  ///
  /// In en, this message translates to:
  /// **'Edit avatar'**
  String get profileEditAvatar;

  /// Confirmation after the avatar is stored.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated.'**
  String get profileAvatarSaved;

  /// Fallback error when a profile write fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that. Please try again.'**
  String get profileAvatarSaveFailed;

  /// App bar title for the Avatar Editor page.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatarEditorTitle;

  /// Avatar editor section for the background colour.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get avatarEditorBackground;

  /// Avatar editor section for the decorative backdrop.
  ///
  /// In en, this message translates to:
  /// **'Backdrop'**
  String get avatarEditorBackdrop;

  /// Avatar editor section for the head shape.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get avatarEditorShape;

  /// Avatar editor section for the eye style.
  ///
  /// In en, this message translates to:
  /// **'Eyes'**
  String get avatarEditorEyes;

  /// Avatar editor section for the mouth style.
  ///
  /// In en, this message translates to:
  /// **'Mouth'**
  String get avatarEditorMouth;

  /// Button that generates a random avatar.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get avatarEditorRandom;

  /// Accessibility label for the avatar preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get avatarEditorPreview;

  /// Save action in the Avatar Editor.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get avatarEditorSave;

  /// Accessibility label for one avatar option swatch.
  ///
  /// In en, this message translates to:
  /// **'{part} option {number}'**
  String avatarEditorOptionLabel(String part, int number);

  /// Accessibility label for a chosen avatar part.
  ///
  /// In en, this message translates to:
  /// **'{part}: {value}'**
  String avatarEditorPartSelected(String part, String value);

  /// Tab label for head and hair variants in the avatar editor.
  ///
  /// In en, this message translates to:
  /// **'Head'**
  String get avatarEditorTabHead;

  /// Tab label for facial expression variants in the avatar editor.
  ///
  /// In en, this message translates to:
  /// **'Face'**
  String get avatarEditorTabFace;

  /// Tab label for glasses and accessories in the avatar editor.
  ///
  /// In en, this message translates to:
  /// **'Glasses'**
  String get avatarEditorTabGlasses;

  /// Tab label for item props in the avatar editor.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get avatarEditorTabItem;

  /// Tab label for palette colors in the avatar editor.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get avatarEditorTabColors;

  /// Section label for facial hair options in the avatar editor.
  ///
  /// In en, this message translates to:
  /// **'Facial Hair'**
  String get avatarEditorBeard;

  /// Color swatch section label for outline ink.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get avatarEditorColorOutline;

  /// Color swatch section label for hair color.
  ///
  /// In en, this message translates to:
  /// **'Hair'**
  String get avatarEditorColorHair;

  /// Color swatch section label for skin tone.
  ///
  /// In en, this message translates to:
  /// **'Skin tone'**
  String get avatarEditorColorSkin;

  /// Color swatch section label for outfit color.
  ///
  /// In en, this message translates to:
  /// **'Outfit'**
  String get avatarEditorColorOutfit;

  /// Option label to remove an optional accessory or overlay.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get avatarEditorNone;

  /// Empty state hint for the avatar Item tab.
  ///
  /// In en, this message translates to:
  /// **'More items coming soon'**
  String get avatarEditorItemsComingSoon;

  /// Confirmation title when leaving avatar editor with unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get avatarEditorDiscardTitle;

  /// Confirmation message when leaving avatar editor with unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them?'**
  String get avatarEditorDiscardMessage;

  /// Confirm button label to discard unsaved avatar edits.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get avatarEditorDiscardConfirm;

  /// Cancel button label to stay in the avatar editor.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get avatarEditorKeepEditing;

  /// Label for the credits and attributions entry in Settings.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get settingsCreditsTitle;

  /// Attribution credit for Open Peeps avatar artwork.
  ///
  /// In en, this message translates to:
  /// **'Avatar art: Open Peeps by Pablo Stanley (CC0 1.0), via DiceBear'**
  String get settingsCreditsAvatar;

  /// Label for the month-start day preference in Settings.
  ///
  /// In en, this message translates to:
  /// **'Month starts on'**
  String get settingsMonthStartsOn;

  /// Subtitle describing the month-start day preference in Settings.
  ///
  /// In en, this message translates to:
  /// **'Align budget cycles with your pay day'**
  String get settingsMonthStartsOnDescription;

  /// App bar title for the month-start day picker page.
  ///
  /// In en, this message translates to:
  /// **'Month starts on'**
  String get monthStartsOnTitle;

  /// Explanatory caption on the month-start day picker page.
  ///
  /// In en, this message translates to:
  /// **'Choose the day of the month your budget begins (1–28). Days 29–31 are excluded so February is never ambiguous.'**
  String get monthStartsOnDescription;

  /// Preview of the current budget period in the month start day picker.
  ///
  /// In en, this message translates to:
  /// **'Current period: {range}'**
  String monthStartsOnCurrentPeriod(String range);

  /// Preview of the previous budget period in the month start day picker.
  ///
  /// In en, this message translates to:
  /// **'Previous: {range}'**
  String monthStartsOnPreviousPeriod(String range);

  /// Notice confirming that changing the pay cycle does not alter stored transactions.
  ///
  /// In en, this message translates to:
  /// **'Your transactions are not changed.'**
  String get monthStartsOnTransactionsNotice;

  /// Format for a day number.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String monthStartsOnDayFormat(int day);

  /// Subtitle shown under the period header when month start day is not 1.
  ///
  /// In en, this message translates to:
  /// **'Pay cycle'**
  String get calendarPayCycle;

  /// Eyebrow label for summary card in pay-cycle mode.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get calendarThisPeriod;

  /// Hero label for period summary when viewing in pay-cycle mode.
  ///
  /// In en, this message translates to:
  /// **'Spent this period'**
  String get calendarSpentThisPeriod;

  /// App bar title for the Insights screen.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// Label for period total income.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get insightsTotalIncome;

  /// Label for period total expense.
  ///
  /// In en, this message translates to:
  /// **'Total Expense'**
  String get insightsTotalExpense;

  /// Label for period net balance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get insightsNetSavings;

  /// Caption comparing current period figures to previous period.
  ///
  /// In en, this message translates to:
  /// **'vs previous period'**
  String get insightsVsPreviousPeriod;

  /// Heading for category spending donut chart.
  ///
  /// In en, this message translates to:
  /// **'Spending Breakdown'**
  String get insightsSpendingByCategory;

  /// Heading for income vs expense bar chart.
  ///
  /// In en, this message translates to:
  /// **'Income vs Expense'**
  String get insightsIncomeVsExpense;

  /// Heading for cumulative cash flow trend line chart.
  ///
  /// In en, this message translates to:
  /// **'Cash Flow Trend'**
  String get insightsCashFlowTrend;

  /// Heading for top spending categories list.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get insightsTopCategories;

  /// Empty state title when period has no transactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get insightsNoDataTitle;

  /// Empty state body for insights.
  ///
  /// In en, this message translates to:
  /// **'Add transactions in this period to see your financial analytics.'**
  String get insightsNoDataBody;

  /// Tooltip for previous period button.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get insightsPreviousPeriod;

  /// Tooltip for next period button.
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get insightsNextPeriod;

  /// App bar title for the transactions list and search screen.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// Placeholder text inside the transaction search bar.
  ///
  /// In en, this message translates to:
  /// **'Search note or category...'**
  String get transactionsSearchHint;

  /// Title of the transaction filter bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterTitle;

  /// Filter chip label for showing all transactions.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Filter chip label for filtering income transactions.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get filterIncome;

  /// Filter chip label for filtering expense transactions.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get filterExpense;

  /// Label for category filter.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterCategory;

  /// Label for date range filter.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get filterDateRange;

  /// Label for date filter start date.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get filterStartDate;

  /// Label for date filter end date.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get filterEndDate;

  /// Label for amount range filter.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get filterAmount;

  /// Label for minimum amount filter input.
  ///
  /// In en, this message translates to:
  /// **'Min amount'**
  String get filterMinAmount;

  /// Label for maximum amount filter input.
  ///
  /// In en, this message translates to:
  /// **'Max amount'**
  String get filterMaxAmount;

  /// Button label to clear all active search and filter criteria.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get filterClearAll;

  /// Button label to apply active filters.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// Title when search query or filters match no transactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get transactionsNoResultsTitle;

  /// Body message when search query or filters match no transactions.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters to find what you\'re looking for.'**
  String get transactionsNoResultsBody;

  /// Main title on welcome/onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Ledgerly'**
  String get welcomeTitle;

  /// Subtitle on welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Master your money, effortlessly.'**
  String get welcomeSubtitle;

  /// First-run onboarding question for pay-cycle start day.
  ///
  /// In en, this message translates to:
  /// **'When does your month start?'**
  String get welcomeMonthStartQuestion;

  /// Supporting explanation for pay cycle start day.
  ///
  /// In en, this message translates to:
  /// **'Choose the day your income or pay cycle begins. You can change this anytime.'**
  String get welcomeMonthStartHelp;

  /// Button to start using the app.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get welcomeGetStarted;

  /// Button to skip onboarding and continue directly.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get welcomeSkip;

  /// Button to use the app anonymously without an account.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// Button label for Google sign-in.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// Button label for Apple sign-in.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// Button label for Email sign-in.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get signInWithEmail;

  /// Title for sign-in page.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInTitle;

  /// Title for create account page.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUpTitle;

  /// Label for email input field.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailLabel;

  /// Label for password input field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Label for name input field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get displayNameLabel;

  /// Link button for password recovery.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Prompt on sign-in page to switch to sign-up.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccountPrompt;

  /// Prompt on sign-up page to switch to sign-in.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccountPrompt;

  /// Title of the account management page.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// Badge showing account is running in guest mode.
  ///
  /// In en, this message translates to:
  /// **'Guest Account'**
  String get accountGuestBadge;

  /// Badge showing account is linked to an identity provider.
  ///
  /// In en, this message translates to:
  /// **'Synced Account'**
  String get accountLinkedBadge;

  /// Title of the prompt inviting guests to link their account.
  ///
  /// In en, this message translates to:
  /// **'Save your data securely'**
  String get accountLinkBannerTitle;

  /// Explanation of guest account linking benefits.
  ///
  /// In en, this message translates to:
  /// **'Link your guest account to keep your finances backed up across devices.'**
  String get accountLinkBannerBody;

  /// Button to link current guest session to Google.
  ///
  /// In en, this message translates to:
  /// **'Link Google Account'**
  String get accountLinkGoogle;

  /// Button to link current guest session to Apple.
  ///
  /// In en, this message translates to:
  /// **'Link Apple ID'**
  String get accountLinkApple;

  /// Button to sign out of the current account.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get accountSignOut;

  /// Confirmation prompt before signing out.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get accountSignOutConfirm;

  /// Button and title for deleting account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get accountDeleteTitle;

  /// Warning body for account deletion dialog.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all associated local and cloud data. This action cannot be undone.'**
  String get accountDeleteBody;

  /// Destructive confirm button for account deletion.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get accountDeleteConfirm;

  /// Feedback message after account is deleted.
  ///
  /// In en, this message translates to:
  /// **'Account successfully deleted'**
  String get accountDeletedSuccess;

  /// Error when email or password is incorrect.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get authErrorInvalidCredentials;

  /// Error when registering with an existing email.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use'**
  String get authErrorEmailAlreadyInUse;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'my'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'my':
      return AppLocalizationsMy();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
