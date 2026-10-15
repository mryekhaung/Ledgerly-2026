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

  /// Screen-reader label for a pay-cycle start day chip.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String welcomeDayChipLabel(int day);

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

  /// Divider between email and provider sign-in buttons.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get signInOrDivider;

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

  /// Fallback when account linking fails without details.
  ///
  /// In en, this message translates to:
  /// **'Account linking failed'**
  String get accountLinkFailed;

  /// Confirmation when account linking succeeds.
  ///
  /// In en, this message translates to:
  /// **'Account successfully linked'**
  String get accountLinkSuccess;

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

  /// Snackbar shown when account is deleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
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

  /// Generic fallback when sign-in fails without details.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Please try again.'**
  String get authErrorSignInFailed;

  /// Label for data transfer and backup row in settings.
  ///
  /// In en, this message translates to:
  /// **'Data & Backup'**
  String get settingsDataTransfer;

  /// Subtitle for data transfer and backup row in settings.
  ///
  /// In en, this message translates to:
  /// **'Export, import, and backup database'**
  String get settingsDataTransferSubtitle;

  /// App bar title for Data Transfer page.
  ///
  /// In en, this message translates to:
  /// **'Data Transfer'**
  String get dataTransferTitle;

  /// Tab label for Export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get dataTransferTabExport;

  /// Tab label for Import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get dataTransferTabImport;

  /// Tab label for Backup & Restore.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get dataTransferTabBackup;

  /// Button that pastes clipboard text into the import or restore field.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get dataTransferPaste;

  /// Label for export format choice.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get exportFormatLabel;

  /// Label for export date range.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get exportRangeLabel;

  /// Export range preset for this pay period.
  ///
  /// In en, this message translates to:
  /// **'This Period'**
  String get exportPresetThisPeriod;

  /// Export range preset for last pay period.
  ///
  /// In en, this message translates to:
  /// **'Last Period'**
  String get exportPresetLastPeriod;

  /// Export range preset for all transactions.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get exportPresetAllTime;

  /// Export range preset for custom dates.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get exportPresetCustom;

  /// Title above export count and totals.
  ///
  /// In en, this message translates to:
  /// **'Export Summary'**
  String get exportSummaryTitle;

  /// Button to trigger export and copy content to clipboard.
  ///
  /// In en, this message translates to:
  /// **'Export & Copy'**
  String get exportActionExport;

  /// Snackbar feedback when export is copied.
  ///
  /// In en, this message translates to:
  /// **'Exported data copied to clipboard'**
  String get exportSuccessCopied;

  /// Count of transactions in export.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get exportTotalRecords;

  /// Total income in export summary.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get exportTotalIncome;

  /// Total expense in export summary.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get exportTotalExpense;

  /// Label above import input field.
  ///
  /// In en, this message translates to:
  /// **'CSV / JSON Source'**
  String get importSourceLabel;

  /// Placeholder for import text input.
  ///
  /// In en, this message translates to:
  /// **'Paste CSV or JSON transaction records here...'**
  String get importPasteHint;

  /// Button to parse import source.
  ///
  /// In en, this message translates to:
  /// **'Parse Data'**
  String get importActionParse;

  /// Title above import preview results.
  ///
  /// In en, this message translates to:
  /// **'Import Preview'**
  String get importPreviewTitle;

  /// Total rows found in imported content.
  ///
  /// In en, this message translates to:
  /// **'Total Rows'**
  String get importTotalRows;

  /// Valid rows ready to be imported.
  ///
  /// In en, this message translates to:
  /// **'Valid Rows'**
  String get importValidRows;

  /// Duplicate rows detected.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Rows'**
  String get importDuplicateRows;

  /// New categories detected from import.
  ///
  /// In en, this message translates to:
  /// **'New Categories'**
  String get importNewCategories;

  /// Checkbox to skip duplicate records.
  ///
  /// In en, this message translates to:
  /// **'Skip duplicate records'**
  String get importSkipDuplicates;

  /// Checkbox to auto-create categories.
  ///
  /// In en, this message translates to:
  /// **'Automatically create new categories'**
  String get importAutoCreateCategories;

  /// Button to commit import to database.
  ///
  /// In en, this message translates to:
  /// **'Import Transactions'**
  String get importActionExecute;

  /// Success message after import completes.
  ///
  /// In en, this message translates to:
  /// **'Transactions successfully imported'**
  String get importSuccess;

  /// Title for full app backup section.
  ///
  /// In en, this message translates to:
  /// **'Full App Backup'**
  String get backupTitle;

  /// Description of full backup archive.
  ///
  /// In en, this message translates to:
  /// **'Create a complete, offline JSON archive containing all your settings, categories, and transaction history.'**
  String get backupDescription;

  /// Button to create full backup archive.
  ///
  /// In en, this message translates to:
  /// **'Create Full Backup'**
  String get backupActionCreate;

  /// Success message when backup is created.
  ///
  /// In en, this message translates to:
  /// **'Backup created & copied to clipboard'**
  String get backupCreatedSuccess;

  /// Title for restore section.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get restoreTitle;

  /// Loaded backup payload summary with record counts.
  ///
  /// In en, this message translates to:
  /// **'Backup Metadata: {categories} categories, {transactions} transactions'**
  String backupMetadataSummary(int categories, int transactions);

  /// Placeholder for restore JSON input.
  ///
  /// In en, this message translates to:
  /// **'Paste Ledgerly backup JSON archive here...'**
  String get restorePasteHint;

  /// Button to inspect backup JSON.
  ///
  /// In en, this message translates to:
  /// **'Load Backup'**
  String get restoreActionParse;

  /// Button to execute restore.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreActionExecute;

  /// Radio option to merge backup data.
  ///
  /// In en, this message translates to:
  /// **'Merge with existing data'**
  String get restoreModeMerge;

  /// Radio option to overwrite all database data.
  ///
  /// In en, this message translates to:
  /// **'Replace all existing data'**
  String get restoreModeOverwrite;

  /// Destructive warning for overwrite restore mode.
  ///
  /// In en, this message translates to:
  /// **'Warning: Replacing will erase all existing categories and transactions.'**
  String get restoreOverwriteWarning;

  /// Success message after backup restoration.
  ///
  /// In en, this message translates to:
  /// **'Backup successfully restored'**
  String get restoreSuccess;

  /// Title for accounts and wallets management.
  ///
  /// In en, this message translates to:
  /// **'Accounts & Wallets'**
  String get accountsTitle;

  /// Subtitle for accounts section in settings.
  ///
  /// In en, this message translates to:
  /// **'Manage bank accounts, wallets, and track net worth'**
  String get accountsSubtitle;

  /// Label for net worth card.
  ///
  /// In en, this message translates to:
  /// **'Total Net Worth'**
  String get accountsNetWorth;

  /// Tab or section label for active accounts.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get accountsActiveTab;

  /// Tab or section label for archived accounts.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get accountsArchivedTab;

  /// Empty state title for accounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get accountsEmptyTitle;

  /// Empty state description for accounts.
  ///
  /// In en, this message translates to:
  /// **'Add your cash, bank accounts, or e-wallets to track your balances and transfers.'**
  String get accountsEmptyBody;

  /// Button to create a new account.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get accountsAddButton;

  /// Page title when editing an account.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get accountsEditTitle;

  /// Page title when creating an account.
  ///
  /// In en, this message translates to:
  /// **'New Account'**
  String get accountsNewTitle;

  /// Button to start fund transfer between accounts.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get accountsTransferButton;

  /// Page title for transferring funds between accounts.
  ///
  /// In en, this message translates to:
  /// **'Transfer Funds'**
  String get accountsTransferTitle;

  /// Source account selector label.
  ///
  /// In en, this message translates to:
  /// **'From Account'**
  String get accountsTransferFrom;

  /// Tooltip for swapping source and destination accounts.
  ///
  /// In en, this message translates to:
  /// **'Swap accounts'**
  String get accountsTransferSwap;

  /// Destination account selector label.
  ///
  /// In en, this message translates to:
  /// **'To Account'**
  String get accountsTransferTo;

  /// Amount field label for transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer Amount'**
  String get accountsTransferAmount;

  /// Date field label for transfer.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get accountsTransferDate;

  /// Optional note for transfer.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get accountsTransferNote;

  /// Submit button for transfer.
  ///
  /// In en, this message translates to:
  /// **'Execute Transfer'**
  String get accountsTransferSubmit;

  /// Snackbar shown when transfer succeeds.
  ///
  /// In en, this message translates to:
  /// **'Transfer completed successfully'**
  String get accountsTransferSuccess;

  /// Label for account name field.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountFieldName;

  /// Hint for account name field.
  ///
  /// In en, this message translates to:
  /// **'e.g. KBZ Bank, Wallet, Cash'**
  String get accountNameHint;

  /// Label for account type field.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountFieldType;

  /// Label for account currency field.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get accountFieldCurrency;

  /// Label for opening balance field.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get accountFieldOpeningBalance;

  /// Label for account icon picker.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get accountFieldIcon;

  /// Label for account color picker.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get accountFieldColor;

  /// Toggle to include account balance in total net worth.
  ///
  /// In en, this message translates to:
  /// **'Include in Net Worth'**
  String get accountFieldIncludeInTotal;

  /// Account type cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// Account type bank.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get accountTypeBank;

  /// Account type credit card.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get accountTypeCredit;

  /// Account type savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get accountTypeSavings;

  /// Account type e-wallet.
  ///
  /// In en, this message translates to:
  /// **'E-Wallet'**
  String get accountTypeEwallet;

  /// Snackbar shown when account is saved.
  ///
  /// In en, this message translates to:
  /// **'Account saved successfully'**
  String get accountSavedSuccess;

  /// Snackbar shown when account is archived.
  ///
  /// In en, this message translates to:
  /// **'Account archived'**
  String get accountArchiveSuccess;

  /// Snackbar shown when account is unarchived.
  ///
  /// In en, this message translates to:
  /// **'Account restored from archive'**
  String get accountUnarchiveSuccess;

  /// Title for account delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get accountConfirmDelete;

  /// Message for account delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this account? Existing transactions will remain intact.'**
  String get accountConfirmDeleteMessage;

  /// Validation error when account name is empty.
  ///
  /// In en, this message translates to:
  /// **'Account name is required'**
  String get accountsNameRequired;

  /// Validation error when account name is too long.
  ///
  /// In en, this message translates to:
  /// **'Account name cannot exceed 60 characters'**
  String get accountsNameTooLong;

  /// Validation error when account name is already in use.
  ///
  /// In en, this message translates to:
  /// **'An account with this name already exists'**
  String get accountsNameTaken;

  /// Validation error when from and to accounts are identical.
  ///
  /// In en, this message translates to:
  /// **'Source and destination accounts must be different'**
  String get accountsTransferSameAccount;

  /// Validation error when transfer amount is non-positive.
  ///
  /// In en, this message translates to:
  /// **'Transfer amount must be greater than zero'**
  String get accountsTransferAmountInvalid;

  /// App bar title and page title for Budgets feature.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgetsTitle;

  /// Label for overall total spending limit budget.
  ///
  /// In en, this message translates to:
  /// **'Total Budget'**
  String get budgetsTotal;

  /// Label for category specific budget.
  ///
  /// In en, this message translates to:
  /// **'Category Budget'**
  String get budgetsCategory;

  /// Title for new budget creation page.
  ///
  /// In en, this message translates to:
  /// **'New Budget'**
  String get budgetsNew;

  /// Title for edit budget page.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get budgetsEdit;

  /// Label for delete budget action.
  ///
  /// In en, this message translates to:
  /// **'Delete Budget'**
  String get budgetsDelete;

  /// Title shown when no budgets are defined for the period.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get budgetsEmptyTitle;

  /// Body message shown when no budgets are defined.
  ///
  /// In en, this message translates to:
  /// **'Set spending limits for categories or an overall cap to stay on track with your finances.'**
  String get budgetsEmptyBody;

  /// Form label for budget category selection.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get budgetFieldCategory;

  /// Form label for budget limit amount.
  ///
  /// In en, this message translates to:
  /// **'Budget Limit'**
  String get budgetFieldAmount;

  /// Form label for budget period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get budgetFieldPeriod;

  /// Form label for budget alert threshold slider.
  ///
  /// In en, this message translates to:
  /// **'Alert Warning Threshold'**
  String get budgetFieldThreshold;

  /// Explains what the alert threshold slider does.
  ///
  /// In en, this message translates to:
  /// **'Notify with a warning alert when spending reaches {percent}% of your budget.'**
  String budgetThresholdHint(int percent);

  /// Live readout under the threshold slider.
  ///
  /// In en, this message translates to:
  /// **'Warning alert triggers at {percent}%'**
  String budgetThresholdLive(int percent);

  /// Option in category picker to set an overall total budget.
  ///
  /// In en, this message translates to:
  /// **'Overall (Total Expenses)'**
  String get budgetTotalOption;

  /// Label for spent amount.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetSpent;

  /// Label for remaining budget amount.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get budgetRemaining;

  /// Label for daily remaining spending capacity.
  ///
  /// In en, this message translates to:
  /// **'Daily Safe Spend'**
  String get budgetDailyRemaining;

  /// Status text for safe budget level.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get budgetStatusSafe;

  /// Status text for budget near alert threshold.
  ///
  /// In en, this message translates to:
  /// **'Near Limit'**
  String get budgetStatusWarning;

  /// Status text for exceeded budget.
  ///
  /// In en, this message translates to:
  /// **'Over Budget'**
  String get budgetStatusExceeded;

  /// Snackbar shown when budget is saved.
  ///
  /// In en, this message translates to:
  /// **'Budget saved successfully'**
  String get budgetSavedSuccess;

  /// Snackbar shown when budget is deleted.
  ///
  /// In en, this message translates to:
  /// **'Budget deleted'**
  String get budgetDeletedSuccess;

  /// Snackbar shown when budget is archived.
  ///
  /// In en, this message translates to:
  /// **'Budget archived'**
  String get budgetArchiveSuccess;

  /// Snackbar shown when budget is restored.
  ///
  /// In en, this message translates to:
  /// **'Budget restored'**
  String get budgetUnarchiveSuccess;

  /// Title for budget delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete Budget?'**
  String get budgetConfirmDelete;

  /// Message for budget delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this budget?'**
  String get budgetConfirmDeleteMessage;

  /// Validation error when budget amount is non-positive.
  ///
  /// In en, this message translates to:
  /// **'Budget limit must be greater than zero'**
  String get budgetAmountInvalid;

  /// Validation error when threshold is outside 0.1 to 1.0.
  ///
  /// In en, this message translates to:
  /// **'Alert threshold must be between 10% and 100%'**
  String get budgetThresholdInvalid;

  /// Validation error when budget already exists for category.
  ///
  /// In en, this message translates to:
  /// **'A budget already exists for this category in this period'**
  String get budgetDuplicateCategory;

  /// Validation error when total budget already exists.
  ///
  /// In en, this message translates to:
  /// **'A total budget already exists for this period'**
  String get budgetDuplicateTotal;

  /// Header for overall period budget card.
  ///
  /// In en, this message translates to:
  /// **'Overall Budget'**
  String get budgetOverallSummary;

  /// Title of recurring transactions list page.
  ///
  /// In en, this message translates to:
  /// **'Recurring Transactions'**
  String get recurringTitle;

  /// Subtitle of recurring transactions feature.
  ///
  /// In en, this message translates to:
  /// **'Scheduled subscriptions, bills, and recurring income'**
  String get recurringSubtitle;

  /// Action button to create a new recurring rule.
  ///
  /// In en, this message translates to:
  /// **'New Recurring'**
  String get recurringNew;

  /// Active recurring rules tab label with rule count.
  ///
  /// In en, this message translates to:
  /// **'Active ({count})'**
  String recurringActiveTab(int count);

  /// Paused recurring rules tab label with rule count.
  ///
  /// In en, this message translates to:
  /// **'Paused ({count})'**
  String recurringPausedTab(int count);

  /// Title for editing recurring rule.
  ///
  /// In en, this message translates to:
  /// **'Edit Recurring'**
  String get recurringEdit;

  /// Title for empty recurring list state.
  ///
  /// In en, this message translates to:
  /// **'No recurring transactions'**
  String get recurringEmptyTitle;

  /// Body description for empty recurring list state.
  ///
  /// In en, this message translates to:
  /// **'Add recurring subscriptions, salary, rent, or utilities to automate your tracking.'**
  String get recurringEmptyBody;

  /// Action button to manually trigger recurring scheduler.
  ///
  /// In en, this message translates to:
  /// **'Process Due'**
  String get recurringProcessNow;

  /// Daily recurrence cadence label.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurringFrequencyDaily;

  /// Weekly recurrence cadence label.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurringFrequencyWeekly;

  /// Monthly recurrence cadence label.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurringFrequencyMonthly;

  /// Yearly recurrence cadence label.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurringFrequencyYearly;

  /// Label for frequency dropdown in recurring form.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get recurringFieldFrequency;

  /// Label for the optional account dropdown in recurring form.
  ///
  /// In en, this message translates to:
  /// **'Account (Optional)'**
  String get recurringFieldAccountOptional;

  /// Dropdown entry meaning the recurring transaction is not tied to an account.
  ///
  /// In en, this message translates to:
  /// **'No Account specified'**
  String get recurringAccountNone;

  /// Label for start date picker in recurring form.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get recurringFieldStartDate;

  /// Label for end date picker in recurring form.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get recurringFieldEndDate;

  /// Toggle to enable optional end date.
  ///
  /// In en, this message translates to:
  /// **'Set an end date'**
  String get recurringFieldHasEndDate;

  /// Label for auto-add switch in recurring form.
  ///
  /// In en, this message translates to:
  /// **'Automatically create transaction on due date'**
  String get recurringFieldAutoAdd;

  /// Description explaining the auto-add feature.
  ///
  /// In en, this message translates to:
  /// **'When enabled, the transaction is added automatically when you open the app on or after the due date.'**
  String get recurringFieldAutoAddDesc;

  /// Badge when a recurring item is due today.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get recurringDueToday;

  /// Badge when a recurring item is due tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get recurringDueTomorrow;

  /// Menu action to skip the next due date.
  ///
  /// In en, this message translates to:
  /// **'Skip occurrence'**
  String get recurringActionSkip;

  /// Menu action to pause a recurring rule.
  ///
  /// In en, this message translates to:
  /// **'Pause rule'**
  String get recurringActionPause;

  /// Menu action to unpause a recurring rule.
  ///
  /// In en, this message translates to:
  /// **'Resume rule'**
  String get recurringActionResume;

  /// Menu action to delete a recurring rule.
  ///
  /// In en, this message translates to:
  /// **'Delete rule'**
  String get recurringActionDelete;

  /// Snackbar confirming occurrence skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped next occurrence'**
  String get recurringSkippedSuccess;

  /// Snackbar confirming recurring rule saved.
  ///
  /// In en, this message translates to:
  /// **'Recurring transaction saved'**
  String get recurringSavedSuccess;

  /// Snackbar confirming recurring rule deleted.
  ///
  /// In en, this message translates to:
  /// **'Recurring transaction deleted'**
  String get recurringDeletedSuccess;

  /// Snackbar showing number of generated transactions.
  ///
  /// In en, this message translates to:
  /// **'Processed {count} recurring transaction(s)'**
  String recurringProcessedSuccess(int count);

  /// Title of delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete Recurring Rule?'**
  String get recurringConfirmDelete;

  /// Message of delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Past transactions generated by this rule will be kept.'**
  String get recurringConfirmDeleteMessage;

  /// Validation error for non-positive recurring amount.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get recurringErrorAmountPositive;

  /// Validation error when category is missing.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get recurringErrorCategoryRequired;

  /// Validation error when end date is before start date.
  ///
  /// In en, this message translates to:
  /// **'End date cannot be before start date'**
  String get recurringErrorEndDateBeforeStart;

  /// Title of banner showing recurring items awaiting user approval.
  ///
  /// In en, this message translates to:
  /// **'Pending recurring transactions'**
  String get recurringPendingBannerTitle;

  /// Action to confirm adding a pending recurring transaction.
  ///
  /// In en, this message translates to:
  /// **'Add Now'**
  String get recurringPendingActionConfirm;

  /// App bar title for the savings goals page.
  ///
  /// In en, this message translates to:
  /// **'Savings Goals'**
  String get savingsGoalsTitle;

  /// Label for active savings goals tab.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get savingsGoalsActiveTab;

  /// Label for completed savings goals tab.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get savingsGoalsCompletedTab;

  /// Label for archived savings goals tab.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get savingsGoalsArchivedTab;

  /// Title and button label for creating a new savings goal.
  ///
  /// In en, this message translates to:
  /// **'New Goal'**
  String get newGoal;

  /// Title for editing an existing savings goal.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get editGoal;

  /// Form label for the savings goal name.
  ///
  /// In en, this message translates to:
  /// **'Goal Name'**
  String get goalNameLabel;

  /// Form label for target amount.
  ///
  /// In en, this message translates to:
  /// **'Target Amount'**
  String get goalTargetAmountLabel;

  /// Form label for initial or current saved amount.
  ///
  /// In en, this message translates to:
  /// **'Current Saved Amount'**
  String get goalCurrentAmountLabel;

  /// Form label for optional goal deadline date.
  ///
  /// In en, this message translates to:
  /// **'Target Date (Optional)'**
  String get goalTargetDateLabel;

  /// Form label for linked account.
  ///
  /// In en, this message translates to:
  /// **'Linked Account (Optional)'**
  String get goalAccountLabel;

  /// Dropdown option for a goal with no linked account.
  ///
  /// In en, this message translates to:
  /// **'None (General Saved)'**
  String get goalNoAccountOption;

  /// Goal deadline placeholder when no date is chosen.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get goalNoDate;

  /// Form label for notes.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get goalNotesLabel;

  /// Label for icon picker.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get goalIconLabel;

  /// Label for color picker.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get goalColorLabel;

  /// Button to save a goal.
  ///
  /// In en, this message translates to:
  /// **'Save Goal'**
  String get saveGoal;

  /// Button to delete a goal.
  ///
  /// In en, this message translates to:
  /// **'Delete Goal'**
  String get deleteGoal;

  /// Confirmation message when deleting a goal.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this savings goal? This cannot be undone.'**
  String get deleteGoalConfirm;

  /// Action to archive a goal.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveGoal;

  /// Action to unarchive a goal.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchiveGoal;

  /// Title for the deposit dialog.
  ///
  /// In en, this message translates to:
  /// **'Add Contribution'**
  String get depositTitle;

  /// Title for the withdraw dialog.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Funds'**
  String get withdrawTitle;

  /// Action button to deposit money into a goal.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get depositAction;

  /// Action button to withdraw money from a goal.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawAction;

  /// Label for amount input field.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get goalAmountLabel;

  /// Label showing remaining amount to reach target.
  ///
  /// In en, this message translates to:
  /// **'{amount} remaining'**
  String goalRemaining(String amount);

  /// Days remaining until goal target date.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String goalDaysLeft(int days);

  /// Days overdue past goal target date.
  ///
  /// In en, this message translates to:
  /// **'{days} days overdue'**
  String goalDaysOverdue(int days);

  /// Celebration title when goal is achieved.
  ///
  /// In en, this message translates to:
  /// **'Goal Achieved! 🎉'**
  String get goalCompleted;

  /// Celebration subtitle when goal is achieved.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You reached your savings target.'**
  String get goalCompletedSub;

  /// Title shown when there are no savings goals.
  ///
  /// In en, this message translates to:
  /// **'No Savings Goals Yet'**
  String get emptyGoalsTitle;

  /// Message shown when there are no savings goals.
  ///
  /// In en, this message translates to:
  /// **'Set a goal to save for a vacation, emergency fund, or large purchase.'**
  String get emptyGoalsMessage;

  /// Message when no goals are completed.
  ///
  /// In en, this message translates to:
  /// **'No completed goals yet. Keep saving!'**
  String get emptyCompletedGoals;

  /// Message when no goals are archived.
  ///
  /// In en, this message translates to:
  /// **'No archived goals.'**
  String get emptyArchivedGoals;

  /// Validation error when goal name is missing.
  ///
  /// In en, this message translates to:
  /// **'Please enter a goal name'**
  String get goalNameRequired;

  /// Validation error when goal name is too long.
  ///
  /// In en, this message translates to:
  /// **'Goal name cannot exceed 100 characters'**
  String get goalNameTooLong;

  /// Validation error when target amount is not positive.
  ///
  /// In en, this message translates to:
  /// **'Target amount must be greater than zero'**
  String get goalTargetAmountInvalid;

  /// Validation error when saved amount is negative.
  ///
  /// In en, this message translates to:
  /// **'Saved amount cannot be negative'**
  String get goalCurrentAmountInvalid;

  /// Validation error when contribution amount is not positive.
  ///
  /// In en, this message translates to:
  /// **'Contribution amount must be greater than zero'**
  String get goalContributionAmountInvalid;

  /// Validation error when withdrawal amount is not positive.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal amount must be greater than zero'**
  String get goalWithdrawAmountInvalid;

  /// Validation error when withdrawal exceeds current amount.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal amount cannot exceed the saved balance'**
  String get goalWithdrawExceedsBalance;

  /// Validation error when notes are too long.
  ///
  /// In en, this message translates to:
  /// **'Notes cannot exceed 500 characters'**
  String get goalNotesTooLong;

  /// Snackbar confirming savings goal saved.
  ///
  /// In en, this message translates to:
  /// **'Savings goal saved'**
  String get goalSavedSuccess;

  /// Snackbar confirming savings goal deleted.
  ///
  /// In en, this message translates to:
  /// **'Savings goal deleted'**
  String get goalDeletedSuccess;

  /// Snackbar confirming contribution added.
  ///
  /// In en, this message translates to:
  /// **'Contribution added successfully'**
  String get goalContributedSuccess;

  /// Snackbar confirming funds withdrawn.
  ///
  /// In en, this message translates to:
  /// **'Funds withdrawn successfully'**
  String get goalWithdrawnSuccess;

  /// Title for savings goals in settings.
  ///
  /// In en, this message translates to:
  /// **'Savings Goals'**
  String get settingsSavingsGoals;

  /// Subtitle for savings goals in settings.
  ///
  /// In en, this message translates to:
  /// **'Track targets, emergency funds, and progress'**
  String get settingsSavingsGoalsSubtitle;
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
