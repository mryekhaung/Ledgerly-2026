// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Burmese (`my`).
class AppLocalizationsMy extends AppLocalizations {
  AppLocalizationsMy([String locale = 'my']) : super(locale);

  @override
  String get appTitle => 'Ledgerly';

  @override
  String get navigationCalendar => 'ပြက္ခဒိန်';

  @override
  String get navigationInsights => 'သုံးသပ်ချက်';

  @override
  String get navigationCategories => 'အမျိုးအစားများ';

  @override
  String get navigationSettings => 'ဆက်တင်';

  @override
  String get stateEmptyTitle => 'ဒီနေရာမှာ ဘာမှ မရှိသေးပါ';

  @override
  String get stateEmptyBody => 'ပထမဆုံး အသုံးစရိတ်ကို ထည့်ရန် + ကို နှိပ်ပါ။';

  @override
  String get stateErrorTitle => 'တစ်ခုခု မှားသွားပါတယ်';

  @override
  String get stateErrorBody => 'ဒါကို ဖွင့်မရပါဘူး။ ထပ်ကြိုးစားကြည့်ပါ။';

  @override
  String get stateErrorRetry => 'ထပ်ကြိုးစားပါ';

  @override
  String get stateComingSoon =>
      'ဒီအပိုင်းကို မဆောက်ရသေးပါဘူး။ လုပ်ဖို့ စီစဉ်ထားပါတယ်။';

  @override
  String get failureStorage =>
      'သိမ်းထားတဲ့ ဒေတာကို ဖတ်မရပါဘူး။ ထပ်ကြိုးစားကြည့်ပါ။';

  @override
  String get failureNetwork =>
      'အင်တာနက် မရပါဘူး။ ချိတ်ဆက်မှုကို စစ်ပြီး ထပ်ကြိုးစားပါ။';

  @override
  String get failureAuth =>
      'အကောင့်ဝင်ခြင်း မပြီးစီးပါဘူး။ ထပ်ကြိုးစားကြည့်ပါ။';

  @override
  String get failureValidation => 'အထူပြတဲ့ ကွက်လပ်တွေကို စစ်ကြည့်ပါ။';

  @override
  String get failureNotFound => 'ဒီအရာကို ရှာမတွေ့ပါဘူး။';

  @override
  String get failureConflict => 'သိမ်းထားပြီးသား အရာတစ်ခုနဲ့ ထပ်နေပါတယ်။';

  @override
  String get failureParse =>
      'ဒီဖိုင်ကို ဖတ်မရပါဘူး။ ဖော်မတ်ကို စစ်ပြီး ထပ်ကြိုးစားပါ။';

  @override
  String get failureUnexpected =>
      'မမျှော်လင့်တဲ့ အမှားတစ်ခု ဖြစ်သွားပါတယ်။ ထပ်ကြိုးစားကြည့်ပါ။';

  @override
  String get calendarSpentToday => 'ယနေ့ သုံးငွေ';

  @override
  String get calendarIncome => 'ဝင်ငွေ';

  @override
  String get calendarExpense => 'အသုံးစရိတ်';

  @override
  String get calendarNet => 'အသားတင်';

  @override
  String get calendarToday => 'ယနေ့';

  @override
  String get calendarEmptyDay => 'ဒီနေ့မှာ ဘာမှ မရှိပါ';

  @override
  String get calendarSelectDay => 'ရက်တစ်ရက် ရွေးပါ';

  @override
  String get calendarPreviousMonth => 'ယခင်လ';

  @override
  String get calendarNextMonth => 'နောက်လ';

  @override
  String get calendarPickMonth => 'လသို့ ခုန်ရန်';

  @override
  String get calendarPickMonthHint => 'တိုက်ရိုက်ခုန်ရန် လတစ်လကို ရွေးပါ။';

  @override
  String get calendarPreviousYear => 'ယခင်နှစ်';

  @override
  String get calendarNextYear => 'နောက်နှစ်';

  @override
  String get categoriesTitle => 'အမျိုးအစားများ';

  @override
  String get categoriesEmptyTitle => 'အမျိုးအစား မရှိသေးပါ';

  @override
  String get categoriesEmptyBody =>
      'သုံးငွေ စတင်မှတ်ရန် အမျိုးအစားတစ်ခု ဖန်တီးပါ။';

  @override
  String get categoriesSelectHint =>
      'တည်းဖြတ်ရန် အမျိုးအစားတစ်ခု ရွေးပါ၊ သို့မဟုတ် အသစ်တစ်ခု ဖန်တီးပါ။';

  @override
  String get categoriesArchived => 'သိမ်းထားသည်';

  @override
  String get categoriesNew => 'အမျိုးအစားအသစ်';

  @override
  String get categoriesEdit => 'အမျိုးအစား ပြင်ဆင်';

  @override
  String get categoriesArchive => 'သိမ်းထား';

  @override
  String get categoriesUnarchive => 'ပြန်ထုတ်';

  @override
  String get categoriesDelete => 'ဖျက်';

  @override
  String get categoriesDeleted => 'အမျိုးအစား ဖျက်ပြီးပါပြီ';

  @override
  String get categoriesDeleteConfirmTitle => 'ဒီအမျိုးအစားကို ဖျက်မလား?';

  @override
  String get categoriesDeleteConfirmBody =>
      'အောက်မှာ မှတ်ထားပြီးသား ငွေစာရင်းတွေ သမိုင်း ဆက်ရှိပါမယ်။';

  @override
  String get categoriesNameLabel => 'အမည်';

  @override
  String get categoriesNameHint => 'ဥပမာ - စားသောက်စရိတ်';

  @override
  String get categoriesIconLabel => 'အိုင်ကွန်';

  @override
  String get categoriesColorLabel => 'အရောင်';

  @override
  String get categoriesKindLabel => 'အမျိုးအစား';

  @override
  String get categoriesPreview => 'အစမ်းကြည့်';

  @override
  String get categoriesNameRequired => 'အမျိုးအစားအတွက် အမည် ထည့်ပါ။';

  @override
  String get categoriesNameTooLong => 'အမည်ကို စာလုံး ၆၀ အောက် ထားပါ။';

  @override
  String get categoriesNameTaken =>
      'ဒီအမည်ကို အခြားအမျိုးအစားတစ်ခု သုံးနေပြီးပါပြီ။';

  @override
  String get categoriesIconRequired => 'အိုင်ကွန်တစ်ခု ရွေးပါ။';

  @override
  String get categoriesColorInvalid => 'အရောင်တစ်ခု ရွေးပါ။';

  @override
  String get transactionNew => 'ငွေစာရင်း ထည့်';

  @override
  String get transactionEdit => 'ငွေစာရင်း ပြင်ဆင်';

  @override
  String get transactionAmountLabel => 'ပမာဏ';

  @override
  String get transactionCategoryLabel => 'အမျိုးအစား';

  @override
  String get transactionCategoryChoose => 'အမျိုးအစား ရွေးပါ';

  @override
  String get transactionDateLabel => 'ရက်စွဲ';

  @override
  String get transactionNoteLabel => 'မှတ်စု';

  @override
  String get transactionNoteHint => 'ထည့်လိုပါက';

  @override
  String get transactionDirectionExpense => 'အသုံးစရိတ်';

  @override
  String get transactionDirectionIncome => 'ဝင်ငွေ';

  @override
  String get transactionSave => 'သိမ်း';

  @override
  String get transactionSaved => 'ငွေစာရင်း သိမ်းပြီးပါပြီ';

  @override
  String get transactionDeleted => 'ငွေစာရင်း ဖျက်ပြီးပါပြီ';

  @override
  String get transactionUndo => 'ပြန်လုပ်';

  @override
  String get transactionAmountZero => 'ပမာဏ ထည့်ပါ။';

  @override
  String get transactionAmountTooLarge => 'ဒီပမာဏက ကြီးလွန်းပါတယ်။';

  @override
  String get transactionNoteTooLong => 'မှတ်စုကို စာလုံး ၅၀၀ အောက် ထားပါ။';

  @override
  String get transactionCategoryRequired => 'အမျိုးအစား ရွေးပါ။';

  @override
  String get transactionDirectionUnsupported =>
      'လွှဲပြောင်းမှုကို ဒီဗားရှင်းမှာ မရသေးပါ။';

  @override
  String get transactionFuture => 'ဒီရက်စွဲက အနာဂတ်ရက် ဖြစ်နေပါတယ်။';

  @override
  String get actionCancel => 'မလုပ်တော့ပါ';

  @override
  String get actionSave => 'သိမ်း';

  @override
  String get actionDelete => 'ဖျက်';

  @override
  String get actionDone => 'ပြီးပါပြီ';

  @override
  String get settingsTitle => 'ဆက်တင်';

  @override
  String get settingsPreferencesSection => 'ရွေးချယ်မှုများ';

  @override
  String get settingsCurrencyLabel => 'ငွေကြေး';

  @override
  String get settingsCurrencyBody => 'အက်ပ်တစ်ခုလုံးမှာ ပမာဏတွေ ဘယ်လိုပြမလဲ။';

  @override
  String get settingsLanguageLabel => 'ဘာသာစကား';

  @override
  String get settingsLanguageSystem => 'စက်ရဲ့ မူလသတ်မှတ်ချက်';

  @override
  String get settingsThemeLabel => 'အသွင်အပြင်';

  @override
  String get settingsThemeSystem => 'စက်ရဲ့ အတိုင်း';

  @override
  String get settingsThemeLight => 'အလင်း';

  @override
  String get settingsThemeDark => 'အမှောင်';

  @override
  String get settingsWeekStartLabel => 'အပတ်စတဲ့ ရက်';

  @override
  String get settingsWeekStartMonday => 'တနင်္လာ';

  @override
  String get settingsWeekStartSunday => 'တနင်္ဂနွေ';

  @override
  String get settingsSaved => 'ဆက်တင် သိမ်းပြီးပါပြီ။';

  @override
  String get settingsSaveFailed => 'သိမ်းလို့ မရပါဘူး၊ ထပ်ကြိုးစားကြည့်ပါ။';

  @override
  String get settingsAboutSection => 'အကြောင်း';

  @override
  String get settingsVersionLabel => 'ဗားရှင်း';

  @override
  String get profileTitle => 'ပရိုဖိုင်';

  @override
  String get profileGuestBadge => 'ဧည့်သည်';

  @override
  String get profileGuestBody =>
      'သင်က Ledgerly ကို ဧည့်သည်အနေနဲ့ သုံးနေပါတယ်။ သင့်အချက်အလက်တွေက ဒီစက်ပစ္စည်းထဲမှာပဲ ရှိပါတယ်။';

  @override
  String get profileSignedOutBody =>
      'စက်အများအပြားမှာ သုံးနိုင်ဖို့ အကောင့်ဝင်ပါ။';

  @override
  String get profileNameLabel => 'အမည်';

  @override
  String get profileNameHint => 'သင့်အမည် ထည့်ပါ';

  @override
  String get profileNamePlaceholder => 'သင့်အမည်';

  @override
  String get profileEditName => 'အမည် ပြင်ရန်';

  @override
  String get profileNameSaved => 'အမည် သိမ်းပြီးပါပြီ။';

  @override
  String get profileNameTooLong =>
      'အမည်က နည်းနည်း ရှည်နေပါတယ်။ စာလုံး ၄၀ အောက် သုံးကြည့်ပါ။';

  @override
  String get profileNameInvalid =>
      'ဒီအမည်မှာ သုံးလို့မရတဲ့ စာလုံးတွေ ပါနေပါတယ်။ စာသားသက်သက်ပဲ သုံးကြည့်ပါ။';

  @override
  String get profileAvatarLabel => 'အထောက်အထား ပုံ';

  @override
  String get profileEditAvatar => 'ပုံ ပြင်ရန်';

  @override
  String get profileAvatarSaved => 'ပုံ ပြောင်းပြီးပါပြီ။';

  @override
  String get profileAvatarSaveFailed => 'သိမ်းလို့မရပါဘူး။ ထပ်ကြိုးစားကြည့်ပါ။';

  @override
  String get avatarEditorTitle => 'အထောက်အထား ပုံ';

  @override
  String get avatarEditorBackground => 'နောက်ခံ';

  @override
  String get avatarEditorBackdrop => 'နောက်ခံအလှ';

  @override
  String get avatarEditorShape => 'ပုံသဏ္ဌာန်';

  @override
  String get avatarEditorEyes => 'မျက်လုံး';

  @override
  String get avatarEditorMouth => 'ပါးစပ်';

  @override
  String get avatarEditorRandom => 'ကျပန်း';

  @override
  String get avatarEditorPreview => 'ကြိုတင်ကြည့်ရန်';

  @override
  String get avatarEditorSave => 'သိမ်းရန်';

  @override
  String avatarEditorOptionLabel(String part, int number) {
    return '$part ရွေးချယ်စရာ $number';
  }

  @override
  String avatarEditorPartSelected(String part, String value) {
    return '$part: $value';
  }

  @override
  String get avatarEditorTabHead => 'ဆံပင်';

  @override
  String get avatarEditorTabFace => 'မျက်နှာ';

  @override
  String get avatarEditorTabGlasses => 'မျက်မှန်';

  @override
  String get avatarEditorTabItem => 'ပစ္စည်း';

  @override
  String get avatarEditorTabColors => 'အရောင်';

  @override
  String get avatarEditorBeard => 'မုတ်ဆိတ် / နှုတ်ခမ်းမွေး';

  @override
  String get avatarEditorColorOutline => 'မျဉ်းကြောင်း';

  @override
  String get avatarEditorColorHair => 'ဆံပင်အရောင်';

  @override
  String get avatarEditorColorSkin => 'အသားအရောင်';

  @override
  String get avatarEditorColorOutfit => 'အဝတ်အစား';

  @override
  String get avatarEditorNone => 'မရှိ';

  @override
  String get avatarEditorItemsComingSoon => 'ပစ္စည်းအသစ်များ မကြာမီလာမည်';

  @override
  String get avatarEditorDiscardTitle => 'အပြောင်းအလဲများကို ဖျက်မည်လား။';

  @override
  String get avatarEditorDiscardMessage =>
      'သိမ်းဆည်းမထားသော အပြောင်းအလဲများ ရှိနေပါသည်။ ဖျက်ပစ်လိုပါသလား။';

  @override
  String get avatarEditorDiscardConfirm => 'ဖျက်မည်';

  @override
  String get avatarEditorKeepEditing => 'ဆက်လက်ပြင်ဆင်မည်';
}
