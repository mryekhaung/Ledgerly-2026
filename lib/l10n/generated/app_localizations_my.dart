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

  @override
  String get settingsCreditsTitle => 'ဂုဏ်ပြုမှတ်တမ်း';

  @override
  String get settingsCreditsAvatar =>
      'Avatar art: Open Peeps by Pablo Stanley (CC0 1.0), via DiceBear';

  @override
  String get settingsMonthStartsOn => 'လစတင်ရက်';

  @override
  String get settingsMonthStartsOnDescription =>
      'ဘတ်ဂျက်စက်ဝန်းကို သင့်လစာရက်နှင့် ညှိပါ';

  @override
  String get monthStartsOnTitle => 'လစတင်ရက်';

  @override
  String get monthStartsOnDescription =>
      'သင့်ဘတ်ဂျက်စတင်မည့် ရက်ကို ရွေးချယ်ပါ (၁–၂၈)။ ဖေဖော်ဝါရီလအတွက် အဆင်ပြေစေရန် ၂၉–၃၁ ရက်များကို ချန်လှပ်ထားပါသည်။';

  @override
  String monthStartsOnCurrentPeriod(String range) {
    return 'လက်ရှိကာလ - $range';
  }

  @override
  String monthStartsOnPreviousPeriod(String range) {
    return 'ယခင်ကာလ - $range';
  }

  @override
  String get monthStartsOnTransactionsNotice =>
      'သင့်စာရင်းများကို ပြောင်းလဲမှုမရှိစေပါ။';

  @override
  String monthStartsOnDayFormat(int day) {
    return 'ရက် $day';
  }

  @override
  String get calendarPayCycle => 'လစာစက်ဝန်း';

  @override
  String get calendarThisPeriod => 'ယခုကာလ';

  @override
  String get calendarSpentThisPeriod => 'ယခုကာလအတွင်း သုံးစွဲငွေ';

  @override
  String get insightsTitle => 'သုံးသပ်ချက်';

  @override
  String get insightsTotalIncome => 'စုစုပေါင်း ဝင်ငွေ';

  @override
  String get insightsTotalExpense => 'စုစုပေါင်း အသုံးစရိတ်';

  @override
  String get insightsNetSavings => 'အသားတင် ကျန်ငွေ';

  @override
  String get insightsVsPreviousPeriod => 'ယခင်ကာလနှင့် နှိုင်းယှဉ်ချက်';

  @override
  String get insightsSpendingByCategory => 'အသုံးစရိတ် ခွဲခြမ်းစိတ်ဖြာချက်';

  @override
  String get insightsIncomeVsExpense =>
      'ဝင်ငွေနှင့် အသုံးစရိတ် နှိုင်းယှဉ်ချက်';

  @override
  String get insightsCashFlowTrend => 'ငွေစီးဆင်းမှု လားရာ';

  @override
  String get insightsTopCategories => 'အသုံးအများဆုံး ကဏ္ဍများ';

  @override
  String get insightsNoDataTitle => 'စာရင်းမှတ်တမ်း မရှိသေးပါ';

  @override
  String get insightsNoDataBody =>
      'ဤကာလအတွင်း ငွေစာရင်းများ ထည့်သွင်းပြီး သုံးသပ်ချက်များကို ကြည့်ရှုပါ။';

  @override
  String get insightsPreviousPeriod => 'ယခင် ကာလ';

  @override
  String get insightsNextPeriod => 'နောက် ကာလ';

  @override
  String get transactionsTitle => 'ငွေစာရင်းများ';

  @override
  String get transactionsSearchHint =>
      'မှတ်စု သို့မဟုတ် အမျိုးအစားဖြင့် ရှာရန်...';

  @override
  String get filterTitle => 'စစ်ထုတ်မှုများ';

  @override
  String get filterAll => 'အားလုံး';

  @override
  String get filterIncome => 'ဝင်ငွေ';

  @override
  String get filterExpense => 'ထွက်ငွေ';

  @override
  String get filterCategory => 'အမျိုးအစား';

  @override
  String get filterDateRange => 'ရက်စွဲအပိုင်းအခြား';

  @override
  String get filterStartDate => 'စတင်ရက်';

  @override
  String get filterEndDate => 'ပြီးဆုံးရက်';

  @override
  String get filterAmount => 'ပမာဏ';

  @override
  String get filterMinAmount => 'အနည်းဆုံးပမာဏ';

  @override
  String get filterMaxAmount => 'အများဆုံးပမာဏ';

  @override
  String get filterClearAll => 'အားလုံးရှင်းမည်';

  @override
  String get filterApply => 'အသုံးပြုမည်';

  @override
  String get transactionsNoResultsTitle => 'စာရင်းမတွေ့ရှိပါ';

  @override
  String get transactionsNoResultsBody =>
      'ရှာဖွေမှု သို့မဟုတ် filter များကို ပြောင်းလဲစမ်းသပ်ကြည့်ပါ။';

  @override
  String get welcomeTitle => 'Ledgerly မှ ကြိုဆိုပါသည်';

  @override
  String get welcomeSubtitle =>
      'သင့်ငွေကြေးစီမံခန့်ခွဲမှုကို လွယ်ကူထိရောက်စွာ ပြုလုပ်ပါ';

  @override
  String get welcomeMonthStartQuestion =>
      'သင့်လစာစက်ဝန်း မည်သည့်ရက်တွင် စတင်သနည်း။';

  @override
  String get welcomeMonthStartHelp =>
      'သင့်လစာ သို့မဟုတ် ဝင်ငွေရရှိသည့်ရက်ကို ရွေးချယ်ပါ။ နောက်မှလည်း အချိန်မရွေး ပြောင်းလဲနိုင်ပါသည်။';

  @override
  String get welcomeGetStarted => 'စတင်မည်';

  @override
  String get welcomeSkip => 'လောလောဆယ် ကျော်မည်';

  @override
  String get continueAsGuest => 'အကောင့်မသုံးဘဲ ဆက်သွားမည်';

  @override
  String get signInWithGoogle => 'Google ဖြင့် ဝင်မည်';

  @override
  String get signInOrDivider => 'သို့မဟုတ်';

  @override
  String get signInWithApple => 'Apple ဖြင့် ဝင်မည်';

  @override
  String get signInWithEmail => 'အီးမေးလ်ဖြင့် ဝင်မည်';

  @override
  String get signInTitle => 'အကောင့်ဝင်ရန်';

  @override
  String get signUpTitle => 'အကောင့်အသစ်ဖွင့်ရန်';

  @override
  String get emailLabel => 'အီးမေးလ်လိပ်စာ';

  @override
  String get passwordLabel => 'စကားဝှက်';

  @override
  String get displayNameLabel => 'အမည်';

  @override
  String get forgotPassword => 'စကားဝှက် မေ့နေပါသလား';

  @override
  String get noAccountPrompt => 'အကောင့်မရှိသေးဘူးလား။ အသစ်ဖွင့်ပါ';

  @override
  String get haveAccountPrompt => 'အကောင့်ရှိပြီးသားလား။ ဝင်ပါ';

  @override
  String get accountTitle => 'အကောင့်';

  @override
  String get accountGuestBadge => 'ဧည့်သည် အကောင့်';

  @override
  String get accountLinkedBadge => 'ချိတ်ဆက်ပြီး အကောင့်';

  @override
  String get accountLinkBannerTitle =>
      'သင့်စာရင်းများကို လုံခြုံစွာ သိမ်းဆည်းပါ';

  @override
  String get accountLinkBannerBody =>
      'ဖုန်းလဲသည့်အခါ စာရင်းများမပျောက်စေရန် အကောင့်ဖြင့် ချိတ်ဆက်ထားပါ။';

  @override
  String get accountLinkGoogle => 'Google အကောင့် ချိတ်ဆက်မည်';

  @override
  String get accountLinkApple => 'Apple ID ချိတ်ဆက်မည်';

  @override
  String get accountSignOut => 'အကောင့်မှ ထွက်မည်';

  @override
  String get accountSignOutConfirm => 'အကောင့်မှ ထွက်ရန် သေချာပါသလား။';

  @override
  String get accountDeleteTitle => 'အကောင့်ဖျက်သိမ်းရန်';

  @override
  String get accountDeleteBody =>
      'ဤလုပ်ဆောင်ချက်သည် သင့်အကောင့်နှင့် ငွေစာရင်းမှတ်တမ်းအားလုံးကို ထာဝရ ဖျက်ဆီးပါမည်။ ပြန်လည်ရယူနိုင်မည် မဟုတ်ပါ။';

  @override
  String get accountDeleteConfirm => 'အပြီးဖျက်မည်';

  @override
  String get accountDeletedSuccess => 'အကောင့်ကို ဖျက်ပြီးပါပြီ';

  @override
  String get authErrorInvalidCredentials =>
      'အီးမေးလ် သို့မဟုတ် စကားဝှက် မှားယွင်းနေပါသည်';

  @override
  String get authErrorEmailAlreadyInUse => 'ဤအီးမေးလ်ကို အသုံးပြုပြီးဖြစ်ပါသည်';

  @override
  String get settingsDataTransfer => 'ဒေတာနှင့် အရန်သိမ်းဆည်းမှု';

  @override
  String get settingsDataTransferSubtitle =>
      'စာရင်းများထုတ်ယူခြင်း၊ ထည့်သွင်းခြင်းနှင့် အရန်သိမ်းခြင်း';

  @override
  String get dataTransferTitle => 'ဒေတာ စီမံခန့်ခွဲမှု';

  @override
  String get dataTransferTabExport => 'ထုတ်ယူရန်';

  @override
  String get dataTransferTabImport => 'ထည့်သွင်းရန်';

  @override
  String get dataTransferTabBackup => 'အရန်သိမ်း/ပြန်ယူ';

  @override
  String get dataTransferPaste => 'ကူးထည့်';

  @override
  String get exportFormatLabel => 'ဖော်မတ်';

  @override
  String get exportRangeLabel => 'ကာလအပိုင်းအခြား';

  @override
  String get exportPresetThisPeriod => 'ယခုကာလ';

  @override
  String get exportPresetLastPeriod => 'ပြီးခဲ့သည့်ကာလ';

  @override
  String get exportPresetAllTime => 'အားလုံး';

  @override
  String get exportPresetCustom => 'စိတ်ကြိုက်';

  @override
  String get exportSummaryTitle => 'ထုတ်ယူမည့် အကျဉ်းချုပ်';

  @override
  String get exportActionExport => 'ထုတ်ယူပြီး ကူးယူမည်';

  @override
  String get exportSuccessCopied => 'ဒေတာများကို clipboard သို့ ကူးယူပြီးပါပြီ';

  @override
  String get exportTotalRecords => 'စာရင်း အရေအတွက်';

  @override
  String get exportTotalIncome => 'ဝင်ငွေ စုစုပေါင်း';

  @override
  String get exportTotalExpense => 'အသုံးစရိတ် စုစုပေါင်း';

  @override
  String get importSourceLabel => 'CSV / JSON စာရင်း အရင်းအမြစ်';

  @override
  String get importPasteHint =>
      'CSV သို့မဟုတ် JSON စာရင်းများကို ဤနေရာတွင် paste ချပါ...';

  @override
  String get importActionParse => 'ဒေတာ စစ်ဆေးမည်';

  @override
  String get importPreviewTitle => 'ထည့်သွင်းမည့် အကြိုကြည့်ရှုမှု';

  @override
  String get importTotalRows => 'စာရင်း စုစုပေါင်း';

  @override
  String get importValidRows => 'မှန်ကန်သော စာရင်းများ';

  @override
  String get importDuplicateRows => 'စာရင်းထပ်နေမှုများ';

  @override
  String get importNewCategories => 'ကဏ္ဍ အသစ်များ';

  @override
  String get importSkipDuplicates => 'ထပ်နေသော စာရင်းများကို ချန်လှပ်မည်';

  @override
  String get importAutoCreateCategories =>
      'ကဏ္ဍအသစ်များကို အလိုအလျောက် ဖန်တီးမည်';

  @override
  String get importActionExecute => 'စာရင်းများ ထည့်သွင်းမည်';

  @override
  String get importSuccess => 'စာရင်းများကို အောင်မြင်စွာ ထည့်သွင်းပြီးပါပြီ';

  @override
  String get backupTitle => 'အရန်သိမ်းဆည်းမှု အပြည့်အစုံ';

  @override
  String get backupDescription =>
      'သင့်ဆက်တင်များ၊ ကဏ္ဍများနှင့် ငွေစာရင်းမှတ်တမ်းအားလုံးပါဝင်သော အော့ဖ်လိုင်း JSON archive အပြည့်အစုံကို ထုတ်ယူသိမ်းဆည်းပါ။';

  @override
  String get backupActionCreate => 'အရန်သိမ်း ဖိုင်ထုတ်မည်';

  @override
  String get backupCreatedSuccess =>
      'အရန်သိမ်းဒေတာ ထုတ်ယူပြီး clipboard သို့ ကူးယူပြီးပါပြီ';

  @override
  String get restoreTitle => 'အရန်သိမ်းဒေတာ ပြန်လည်ရယူရန်';

  @override
  String backupMetadataSummary(int categories, int transactions) {
    return 'အရန်သိမ်းအချက်အလက်: အမျိုးအစား $categories ခု၊ စာရင်း $transactions ခု';
  }

  @override
  String get restorePasteHint =>
      'Ledgerly အရန်သိမ်း JSON archive ကို ဤနေရာတွင် ထည့်ပါ...';

  @override
  String get restoreActionParse => 'အရန်သိမ်းဒေတာ ဖွင့်မည်';

  @override
  String get restoreActionExecute => 'ဒေတာများ ပြန်လည်ရယူမည်';

  @override
  String get restoreModeMerge => 'ရှိပြီးသား စာရင်းများနှင့် ပေါင်းစပ်မည်';

  @override
  String get restoreModeOverwrite => 'ရှိပြီးသား စာရင်းအားလုံးကို အစားထိုးမည်';

  @override
  String get restoreOverwriteWarning =>
      'သတိပေးချက် - အစားထိုးပါက လက်ရှိကဏ္ဍများနှင့် ငွေစာရင်းမှတ်တမ်းအားလုံး ပျက်စီးသွားပါမည်။';

  @override
  String get restoreSuccess => 'ဒေတာများ အောင်မြင်စွာ ပြန်လည်ရယူပြီးပါပြီ';

  @override
  String get accountsTitle => 'အကောင့်များနှင့် ပိုက်ဆံအိတ်များ';

  @override
  String get accountsSubtitle =>
      'ဘဏ်အကောင့်များ၊ ပိုက်ဆံအိတ်များနှင့် အသားတင်ပိုင်ဆိုင်မှုကို စီမံမည်';

  @override
  String get accountsNetWorth => 'စုစုပေါင်း အသားတင်ပိုင်ဆိုင်မှု';

  @override
  String get accountsActiveTab => 'လက်ရှိသုံးစွဲနေသော';

  @override
  String get accountsArchivedTab => 'သိမ်းဆည်းထားသော';

  @override
  String get accountsEmptyTitle => 'အကောင့်များ မရှိသေးပါ';

  @override
  String get accountsEmptyBody =>
      'လက်ကျန်ငွေနှင့် ငွေလွှဲပြောင်းမှုများကို မှတ်တမ်းတင်ရန် သင့်ငွေသား၊ ဘဏ်အကောင့် သို့မဟုတ် ပိုက်ဆံအိတ်များကို ထည့်သွင်းပါ။';

  @override
  String get accountsAddButton => 'အကောင့်အသစ်ထည့်မည်';

  @override
  String get accountsEditTitle => 'အကောင့်ပြင်ဆင်မည်';

  @override
  String get accountsNewTitle => 'အကောင့်အသစ်';

  @override
  String get accountsTransferButton => 'ငွေလွှဲမည်';

  @override
  String get accountsTransferTitle => 'အကောင့်အချင်းချင်း ငွေလွှဲရန်';

  @override
  String get accountsTransferFrom => 'လွှဲပြောင်းမည့် အကောင့်';

  @override
  String get accountsTransferTo => 'လက်ခံမည့် အကောင့်';

  @override
  String get accountsTransferAmount => 'လွှဲပြောင်းငွေပမာဏ';

  @override
  String get accountsTransferDate => 'ရက်စွဲ';

  @override
  String get accountsTransferNote => 'မှတ်ချက် (ရွေးချယ်နိုင်သည်)';

  @override
  String get accountsTransferSubmit => 'ငွေလွှဲပြောင်းမှု ပြုလုပ်မည်';

  @override
  String get accountsTransferSuccess => 'ငွေလွှဲပြောင်းမှု အောင်မြင်ပါသည်';

  @override
  String get accountFieldName => 'အကောင့်အမည်';

  @override
  String get accountNameHint => 'ဥပမာ။ KBZ Bank၊ Wallet၊ Cash';

  @override
  String get accountFieldType => 'အကောင့်အမျိုးအစား';

  @override
  String get accountFieldCurrency => 'ငွေကြေး';

  @override
  String get accountFieldOpeningBalance => 'စတင်လက်ကျန်ငွေ';

  @override
  String get accountFieldIcon => 'အိုင်ကွန်';

  @override
  String get accountFieldColor => 'အရောင်';

  @override
  String get accountFieldIncludeInTotal =>
      'အသားတင်ပိုင်ဆိုင်မှုတွင် ထည့်သွင်းမည်';

  @override
  String get accountTypeCash => 'လက်ငင်းငွေသား';

  @override
  String get accountTypeBank => 'ဘဏ်အကောင့်';

  @override
  String get accountTypeCredit => 'Credit ကတ်';

  @override
  String get accountTypeSavings => 'စုဆောင်းငွေ';

  @override
  String get accountTypeEwallet => 'ဒီဂျစ်တယ် ပိုက်ဆံအိတ်';

  @override
  String get accountSavedSuccess =>
      'အကောင့်ကို အောင်မြင်စွာ သိမ်းဆည်းပြီးပါပြီ';

  @override
  String get accountArchiveSuccess =>
      'အကောင့်ကို သိမ်းဆည်းခန်းထဲ ထည့်ပြီးပါပြီ';

  @override
  String get accountUnarchiveSuccess =>
      'အကောင့်ကို ပြန်လည်အသုံးပြုနိုင်ရန် ပြင်ဆင်ပြီးပါပြီ';

  @override
  String get accountConfirmDelete => 'အကောင့်ကို ဖျက်မှာ သေချာပါသလား?';

  @override
  String get accountConfirmDeleteMessage =>
      'ဤအကောင့်ကို ဖျက်ရန် သေချာပါသလား? ယခင်ပြုလုပ်ထားသော ငွေစာရင်းမှတ်တမ်းများ ဆက်လက်တည်ရှိနေမည် ဖြစ်ပါသည်။';

  @override
  String get accountsNameRequired => 'အကောင့်အမည် ထည့်သွင်းရန် လိုအပ်ပါသည်';

  @override
  String get accountsNameTooLong => 'အကောင့်အမည်သည် စာလုံး ၆၀ ထက် မကျော်ရပါ';

  @override
  String get accountsNameTaken => 'ဤအမည်ဖြင့် အကောင့်ရှိပြီးသား ဖြစ်ပါသည်';

  @override
  String get accountsTransferSameAccount =>
      'လွှဲပြောင်းမည့် အကောင့်နှင့် လက်ခံမည့် အကောင့် မတူညီရပါ';

  @override
  String get accountsTransferAmountInvalid =>
      'လွှဲပြောင်းငွေပမာဏသည် သုညထက် ကြီးရပါမည်';

  @override
  String get budgetsTitle => 'ဘတ်ဂျက်များ';

  @override
  String get budgetsTotal => 'စုစုပေါင်း ဘတ်ဂျက်';

  @override
  String get budgetsCategory => 'အမျိုးအစားအလိုက် ဘတ်ဂျက်';

  @override
  String get budgetsNew => 'ဘတ်ဂျက်အသစ် သတ်မှတ်ရန်';

  @override
  String get budgetsEdit => 'ဘတ်ဂျက် ပြင်ဆင်ရန်';

  @override
  String get budgetsDelete => 'ဘတ်ဂျက် ဖျက်မည်';

  @override
  String get budgetsEmptyTitle => 'ဘတ်ဂျက် သတ်မှတ်ထားခြင်း မရှိသေးပါ';

  @override
  String get budgetsEmptyBody =>
      'သုံးစွဲငွေ ပမာဏကို ထိန်းညှိနိုင်ရန် အမျိုးအစားအလိုက် သို့မဟုတ် လစဥ် စုစုပေါင်း သုံးစွဲနိုင်သော ကန့်သတ်ငွေပမာဏကို သတ်မှတ်ပါ။';

  @override
  String get budgetFieldCategory => 'အမျိုးအစား';

  @override
  String get budgetFieldAmount => 'ကန့်သတ်ငွေပမာဏ';

  @override
  String get budgetFieldPeriod => 'ကာလ';

  @override
  String get budgetFieldThreshold => 'သတိပေးချက် ထုတ်ပြန်မည့် ရာခိုင်နှုန်း';

  @override
  String budgetThresholdHint(int percent) {
    return 'သင့်ဘတ်ဂျက်၏ $percent% အသုံးပြုပြီးပါက သတိပေးချက် ထုတ်ပြန်ပါမည်။';
  }

  @override
  String budgetThresholdLive(int percent) {
    return 'သတိပေးချက်သည် $percent% တွင် အလုပ်လုပ်ပါမည်';
  }

  @override
  String get budgetTotalOption => 'စုစုပေါင်း သုံးစွဲငွေ (အားလုံးအတွက်)';

  @override
  String get budgetSpent => 'သုံးစွဲပြီးငွေ';

  @override
  String get budgetRemaining => 'ကျန်ရှိငွေ';

  @override
  String get budgetDailyRemaining => 'နေ့စဥ် သုံးစွဲရန် ကျန်ငွေ';

  @override
  String get budgetStatusSafe => 'ပုံမှန် အခြေအနေ';

  @override
  String get budgetStatusWarning => 'ကန့်သတ်ငွေ နီးကပ်နေပြီ';

  @override
  String get budgetStatusExceeded => 'ဘတ်ဂျက် ကျော်လွန်သွားပါပြီ';

  @override
  String get budgetSavedSuccess => 'ဘတ်ဂျက်ကို အောင်မြင်စွာ သိမ်းဆည်းပြီးပါပြီ';

  @override
  String get budgetDeletedSuccess => 'ဘတ်ဂျက်ကို ဖျက်ပြီးပါပြီ';

  @override
  String get budgetArchiveSuccess => 'ဘတ်ဂျက်ကို သိမ်းဆည်းခန်းထဲ ထည့်ပြီးပါပြီ';

  @override
  String get budgetUnarchiveSuccess =>
      'ဘတ်ဂျက်ကို ပြန်လည်အသုံးပြုနိုင်ရန် ပြင်ဆင်ပြီးပါပြီ';

  @override
  String get budgetConfirmDelete => 'ဘတ်ဂျက်ကို ဖျက်မှာ သေချာပါသလား?';

  @override
  String get budgetConfirmDeleteMessage =>
      'ဤဘတ်ဂျက် ကန့်သတ်ချက်ကို ဖျက်ရန် သေချာပါသလား?';

  @override
  String get budgetAmountInvalid => 'ဘတ်ဂျက်ပမာဏသည် သုညထက် ကြီးရပါမည်';

  @override
  String get budgetThresholdInvalid =>
      'သတိပေးချက် ရာခိုင်နှုန်းသည် ၁၀% မှ ၁၀၀% အတွင်း ဖြစ်ရပါမည်';

  @override
  String get budgetDuplicateCategory =>
      'ဤအမျိုးအစားအတွက် ဤကာလတွင် ဘတ်ဂျက် သတ်မှတ်ပြီးသား ဖြစ်ပါသည်';

  @override
  String get budgetDuplicateTotal =>
      'ဤကာလအတွက် စုစုပေါင်းဘတ်ဂျက် ရှိပြီးဖြစ်ပါသည်';

  @override
  String get budgetOverallSummary => 'လစဥ် စုစုပေါင်း ဘတ်ဂျက်';

  @override
  String get recurringTitle => 'ပုံမှန် ထပ်တလဲလဲ ငွေစာရင်းများ';

  @override
  String get recurringSubtitle =>
      'ပုံမှန် ပေးချေရသော စာရင်းများ၊ ဘေလ်များနှင့် ပုံမှန်ဝင်ငွေများ';

  @override
  String get recurringNew => 'ထပ်တလဲလဲ စာရင်းအသစ်';

  @override
  String recurringActiveTab(int count) {
    return 'လုပ်ဆောင်ဆဲ ($count)';
  }

  @override
  String recurringPausedTab(int count) {
    return 'ခေတ္တရပ်ဆိုင်းထားသော ($count)';
  }

  @override
  String get recurringEdit => 'ထပ်တလဲလဲ စာရင်း ပြင်ဆင်ရန်';

  @override
  String get recurringEmptyTitle => 'ပုံမှန် ထပ်တလဲလဲ စာရင်း မရှိသေးပါ';

  @override
  String get recurringEmptyBody =>
      'လစာ၊ အိမ်လခ၊ အင်တာနက်ဖိုး စသည့် ပုံမှန်စာရင်းများကို ထည့်သွင်းထားပါက စာရင်းများကို အလိုအလျောက် မှတ်သားပေးမည် ဖြစ်ပါသည်။';

  @override
  String get recurringProcessNow => 'ကျသင့်ငွေစာရင်းများ ထည့်သွင်းမည်';

  @override
  String get recurringFrequencyDaily => 'နေ့စဥ်';

  @override
  String get recurringFrequencyWeekly => 'အပတ်စဥ်';

  @override
  String get recurringFrequencyMonthly => 'လစဥ်';

  @override
  String get recurringFrequencyYearly => 'နှစ်စဥ်';

  @override
  String get recurringFieldFrequency => 'ဖြစ်ပေါ်မည့် အကြိမ်ရေ';

  @override
  String get recurringFieldAccountOptional => 'အကောင့် (မလိုအပ်)';

  @override
  String get recurringAccountNone => 'အကောင့် မသတ်မှတ်ထား';

  @override
  String get recurringFieldStartDate => 'စတင်မည့်ရက်';

  @override
  String get recurringFieldEndDate => 'ပြီးဆုံးမည့်ရက်';

  @override
  String get recurringFieldHasEndDate => 'ပြီးဆုံးမည့်ရက် သတ်မှတ်မည်';

  @override
  String get recurringFieldAutoAdd =>
      'ကျသင့်သည့်ရက်တွင် စာရင်းကို အလိုအလျောက် ထည့်သွင်းမည်';

  @override
  String get recurringFieldAutoAddDesc =>
      'ဖွင့်ထားပါက ကျသင့်ရက်ရောက်သည့်အခါ အက်ပ်ဖွင့်သည်နှင့် စာရင်းကို အလိုအလျောက် ထည့်သွင်းပေးမည် ဖြစ်ပါသည်။';

  @override
  String get recurringDueToday => 'ယနေ့ ကျသင့်ငွေ';

  @override
  String get recurringDueTomorrow => 'မနက်ဖြန် ကျသင့်ငွေ';

  @override
  String recurringNextDue(String date) {
    return 'နောက်တစ်ကြိမ်: $date';
  }

  @override
  String get recurringActionSkip => 'ဤတစ်ကြိမ် ကျော်မည်';

  @override
  String get recurringActionPause => 'ခေတ္တ ရပ်ဆိုင်းမည်';

  @override
  String get recurringActionResume => 'ပြန်လည် စတင်မည်';

  @override
  String get recurringActionDelete => 'ဖျက်မည်';

  @override
  String get recurringSkippedSuccess =>
      'နောက်တစ်ကြိမ် ကျသင့်စာရင်းကို ကျော်လိုက်ပါပြီ';

  @override
  String get recurringSavedSuccess =>
      'ပုံမှန် ထပ်တလဲလဲ စာရင်းကို သိမ်းဆည်းပြီးပါပြီ';

  @override
  String get recurringDeletedSuccess =>
      'ပုံမှန် ထပ်တလဲလဲ စာရင်းကို ဖျက်ပြီးပါပြီ';

  @override
  String recurringProcessedSuccess(int count) {
    return 'ထပ်တလဲလဲ စာရင်း $count ခုကို စာရင်းသွင်းပြီးပါပြီ';
  }

  @override
  String get recurringConfirmDelete => 'ဤပုံမှန်စာရင်းကို ဖျက်မှာ သေချာပါသလား?';

  @override
  String get recurringConfirmDeleteMessage =>
      'ယခင် ထည့်သွင်းပြီးသား စာရင်းများ ပျက်ပြယ်မည် မဟုတ်ပါ။';

  @override
  String get recurringErrorAmountPositive => 'ငွေပမာဏသည် သုညထက် ကြီးရပါမည်';

  @override
  String get recurringErrorCategoryRequired => 'အမျိုးအစား ရွေးချယ်ပေးပါ';

  @override
  String get recurringErrorEndDateBeforeStart =>
      'ပြီးဆုံးမည့်ရက်သည် စတင်မည့်ရက်ထက် မစောရပါ';

  @override
  String get recurringPendingBannerTitle =>
      'ထည့်သွင်းရန် စောင့်ဆိုင်းနေသော ထပ်တလဲလဲ စာရင်းများ';

  @override
  String get recurringPendingActionConfirm => 'ယခု ထည့်မည်';

  @override
  String get savingsGoalsTitle => 'စုငွေ ရည်မှန်းချက်များ';

  @override
  String get savingsGoalsActiveTab => 'လုပ်ဆောင်ဆဲ';

  @override
  String get savingsGoalsCompletedTab => 'အောင်မြင်ပြီး';

  @override
  String get savingsGoalsArchivedTab => 'သိမ်းဆည်းထားသော';

  @override
  String get newGoal => 'ရည်မှန်းချက်အသစ်';

  @override
  String get editGoal => 'ရည်မှန်းချက် ပြင်ဆင်ရန်';

  @override
  String get goalNameLabel => 'ရည်မှန်းချက် အမည်';

  @override
  String get goalTargetAmountLabel => 'သတ်မှတ် ရည်မှန်းငွေ';

  @override
  String get goalCurrentAmountLabel => 'လက်ရှိ စုဆောင်းငွေ';

  @override
  String get goalTargetDateLabel => 'ပြီးမြောက်ရမည့်ရက် (ရွေးချယ်ရန်)';

  @override
  String get goalAccountLabel => 'ချိတ်ဆက်မည့် အကောင့် (ရွေးချယ်ရန်)';

  @override
  String get goalNoAccountOption => 'မရှိ (အထွေထွေစုဆောင်းငွေ)';

  @override
  String get goalNoDate => 'မသတ်မှတ်ရသေးပါ';

  @override
  String get goalNotesLabel => 'မှတ်ချက် (ရွေးချယ်ရန်)';

  @override
  String get goalIconLabel => 'အိုင်ကွန်';

  @override
  String get goalColorLabel => 'အရောင်';

  @override
  String get saveGoal => 'ရည်မှန်းချက် သိမ်းဆည်းမည်';

  @override
  String get deleteGoal => 'ရည်မှန်းချက် ဖျက်မည်';

  @override
  String get deleteGoalConfirm =>
      'ဤစုငွေရည်မှန်းချက်ကို ဖျက်ရန် သေချာပါသလား? ဤလုပ်ဆောင်ချက်ကို ပြန်ပြင်၍ မရပါ။';

  @override
  String get archiveGoal => 'သိမ်းဆည်းထားမည်';

  @override
  String get unarchiveGoal => 'ပြန်လည်ဖော်ပြမည်';

  @override
  String get depositTitle => 'စုငွေ ထည့်ဝင်မည်';

  @override
  String get withdrawTitle => 'စုငွေ ထုတ်ယူမည်';

  @override
  String get depositAction => 'ငွေထည့်မည်';

  @override
  String get withdrawAction => 'ငွေထုတ်မည်';

  @override
  String get goalAmountLabel => 'ငွေပမာဏ';

  @override
  String goalRemaining(String amount) {
    return '$amount လိုအပ်သေးသည်';
  }

  @override
  String goalDaysLeft(int days) {
    return '$days ရက် လိုသေးသည်';
  }

  @override
  String goalDaysOverdue(int days) {
    return '$days ရက် ကျော်လွန်နေပါပြီ';
  }

  @override
  String get goalCompleted => 'ရည်မှန်းချက် အောင်မြင်ပါပြီ! 🎉';

  @override
  String get goalCompletedSub =>
      'ဂုဏ်ယူပါသည်! သင်၏ စုငွေရည်မှန်းချက် ပြည့်မီသွားပါပြီ။';

  @override
  String get emptyGoalsTitle => 'စုငွေ ရည်မှန်းချက် မရှိသေးပါ';

  @override
  String get emptyGoalsMessage =>
      'ခရီးသွားရန်၊ အရေးပေါ်ရန်ပုံငွေ သို့မဟုတ် လိုချင်သောအရာများအတွက် စုငွေပန်းတိုင် သတ်မှတ်လိုက်ပါ။';

  @override
  String get emptyCompletedGoals =>
      'ပြီးမြောက်သော ရည်မှန်းချက် မရှိသေးပါ။ ဆက်လက်စုဆောင်းပါ!';

  @override
  String get emptyArchivedGoals => 'သိမ်းဆည်းထားသော ရည်မှန်းချက် မရှိပါ။';

  @override
  String get goalNameRequired => 'ရည်မှန်းချက် အမည် ထည့်သွင်းပေးပါ';

  @override
  String get goalNameTooLong =>
      'ရည်မှန်းချက် အမည်သည် စာလုံးရေ ၁၀၀ ထက် မကျော်ရပါ';

  @override
  String get goalTargetAmountInvalid => 'ရည်မှန်းငွေပမာဏသည် သုညထက် ကြီးရပါမည်';

  @override
  String get goalCurrentAmountInvalid => 'စုဆောင်းငွေသည် အနှုတ် မဖြစ်ရပါ';

  @override
  String get goalContributionAmountInvalid =>
      'ထည့်ဝင်ငွေပမာဏသည် သုညထက် ကြီးရပါမည်';

  @override
  String get goalWithdrawAmountInvalid => 'ထုတ်ယူငွေပမာဏသည် သုညထက် ကြီးရပါမည်';

  @override
  String get goalWithdrawExceedsBalance =>
      'ထုတ်ယူငွေသည် လက်ရှိစုငွေထက် မကျော်လွန်ရပါ';

  @override
  String get goalNotesTooLong => 'မှတ်ချက်သည် စာလုံးရေ ၅၀၀ ထက် မကျော်ရပါ';

  @override
  String get goalSavedSuccess => 'စုငွေရည်မှန်းချက်ကို သိမ်းဆည်းပြီးပါပြီ';

  @override
  String get goalDeletedSuccess => 'စုငွေရည်မှန်းချက်ကို ဖျက်ပြီးပါပြီ';

  @override
  String get goalContributedSuccess => 'စုငွေ ထည့်ဝင်မှု အောင်မြင်ပါသည်';

  @override
  String get goalWithdrawnSuccess => 'စုငွေ ထုတ်ယူမှု အောင်မြင်ပါသည်';

  @override
  String get settingsSavingsGoals => 'စုငွေ ရည်မှန်းချက်များ';

  @override
  String get settingsSavingsGoalsSubtitle =>
      'ပန်းတိုင်များ၊ အရေးပေါ်ရန်ပုံငွေနှင့် တိုးတက်မှုများကို စောင့်ကြည့်ပါ';
}
