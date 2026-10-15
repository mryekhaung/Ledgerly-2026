// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Ledgerly';

  @override
  String get navigationCalendar => 'カレンダー';

  @override
  String get navigationInsights => '分析';

  @override
  String get navigationCategories => 'カテゴリ';

  @override
  String get navigationSettings => '設定';

  @override
  String get stateEmptyTitle => 'まだ何もありません';

  @override
  String get stateEmptyBody => '＋をタップして最初の取引を追加しましょう。';

  @override
  String get stateErrorTitle => '問題が発生しました';

  @override
  String get stateErrorBody => '読み込めませんでした。もう一度お試しください。';

  @override
  String get stateErrorRetry => '再試行';

  @override
  String get stateComingSoon => 'この機能はまだ作っていません。今後追加する予定です。';

  @override
  String get failureStorage => '保存データを読み込めませんでした。もう一度お試しください。';

  @override
  String get failureNetwork => '接続がありません。ネットワークを確認してください。';

  @override
  String get failureAuth => 'サインインが完了しませんでした。もう一度お試しください。';

  @override
  String get failureValidation => '入力内容をご確認ください。';

  @override
  String get failureNotFound => '該当する項目が見つかりませんでした。';

  @override
  String get failureConflict => '既に保存されている内容と競合しています。';

  @override
  String get failureParse => 'このファイルを読み込めませんでした。形式をご確認ください。';

  @override
  String get failureUnexpected => '予期しないエラーが発生しました。もう一度お試しください。';

  @override
  String get calendarSpentToday => '本日の支出';

  @override
  String get calendarIncome => '収入';

  @override
  String get calendarExpense => '支出';

  @override
  String get calendarNet => '収支';

  @override
  String get calendarToday => '今日';

  @override
  String get calendarEmptyDay => 'この日の記録はありません';

  @override
  String get calendarSelectDay => '日付を選択してください';

  @override
  String get calendarPreviousMonth => '前の月';

  @override
  String get calendarNextMonth => '次の月';

  @override
  String get calendarPickMonth => '月へ移動';

  @override
  String get calendarPickMonthHint => '月を選ぶとすぐに移動します。';

  @override
  String get calendarPreviousYear => '前の年';

  @override
  String get calendarNextYear => '次の年';

  @override
  String get categoriesTitle => 'カテゴリー';

  @override
  String get categoriesEmptyTitle => 'カテゴリーがありません';

  @override
  String get categoriesEmptyBody => '支出を記録するには、まずカテゴリーを作成しましょう。';

  @override
  String get categoriesSelectHint => '編集するカテゴリーを選ぶか、新しく作成してください。';

  @override
  String get categoriesArchived => 'アーカイブ済み';

  @override
  String get categoriesNew => '新しいカテゴリー';

  @override
  String get categoriesEdit => 'カテゴリーを編集';

  @override
  String get categoriesArchive => 'アーカイブ';

  @override
  String get categoriesUnarchive => 'アーカイブ解除';

  @override
  String get categoriesDelete => '削除';

  @override
  String get categoriesDeleted => 'カテゴリーを削除しました';

  @override
  String get categoriesDeleteConfirmTitle => 'このカテゴリーを削除しますか？';

  @override
  String get categoriesDeleteConfirmBody => '登録済みの取引の履歴はそのまま残ります。';

  @override
  String get categoriesNameLabel => '名前';

  @override
  String get categoriesNameHint => '例：食費';

  @override
  String get categoriesIconLabel => 'アイコン';

  @override
  String get categoriesColorLabel => '色';

  @override
  String get categoriesKindLabel => '種類';

  @override
  String get categoriesPreview => 'プレビュー';

  @override
  String get categoriesNameRequired => 'カテゴリー名を入力してください。';

  @override
  String get categoriesNameTooLong => '名前は60文字以内にしてください。';

  @override
  String get categoriesNameTaken => 'その名前は別のカテゴリーで使用されています。';

  @override
  String get categoriesIconRequired => 'アイコンを選択してください。';

  @override
  String get categoriesColorInvalid => '色を選択してください。';

  @override
  String get transactionNew => '取引を追加';

  @override
  String get transactionEdit => '取引を編集';

  @override
  String get transactionAmountLabel => '金額';

  @override
  String get transactionCategoryLabel => 'カテゴリー';

  @override
  String get transactionCategoryChoose => 'カテゴリーを選択';

  @override
  String get transactionDateLabel => '日付';

  @override
  String get transactionNoteLabel => 'メモ';

  @override
  String get transactionNoteHint => '任意';

  @override
  String get transactionDirectionExpense => '支出';

  @override
  String get transactionDirectionIncome => '収入';

  @override
  String get transactionSave => '保存';

  @override
  String get transactionSaved => '取引を保存しました';

  @override
  String get transactionDeleted => '取引を削除しました';

  @override
  String get transactionUndo => '元に戻す';

  @override
  String get transactionAmountZero => '金額を入力してください。';

  @override
  String get transactionAmountTooLarge => '金額が大きすぎます。';

  @override
  String get transactionNoteTooLong => 'メモは500文字以内にしてください。';

  @override
  String get transactionCategoryRequired => 'カテゴリーを選択してください。';

  @override
  String get transactionDirectionUnsupported => '振替はまだ利用できません。';

  @override
  String get transactionFuture => 'その日付は未来の日付です。';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionSave => '保存';

  @override
  String get actionDelete => '削除';

  @override
  String get actionDone => '完了';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsPreferencesSection => '環境設定';

  @override
  String get settingsCurrencyLabel => '通貨';

  @override
  String get settingsCurrencyBody => 'アプリ全体で金額を表示する方法です。';

  @override
  String get settingsLanguageLabel => '言語';

  @override
  String get settingsLanguageSystem => 'システムの既定値';

  @override
  String get settingsThemeLabel => '外観';

  @override
  String get settingsThemeSystem => 'システムに合わせる';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsWeekStartLabel => '週の開始日';

  @override
  String get settingsWeekStartMonday => '月曜日';

  @override
  String get settingsWeekStartSunday => '日曜日';

  @override
  String get settingsSaved => '設定を保存しました。';

  @override
  String get settingsSaveFailed => '保存できませんでした。もう一度お試しください。';

  @override
  String get settingsAboutSection => 'このアプリについて';

  @override
  String get settingsVersionLabel => 'バージョン';

  @override
  String get profileTitle => 'プロフィール';

  @override
  String get profileGuestBadge => 'ゲスト';

  @override
  String get profileGuestBody => 'Ledgerly をゲストとして使用中です。データはこの端末にのみ保存されます。';

  @override
  String get profileSignedOutBody => '複数の端末で使うにはサインインしてください。';

  @override
  String get profileNameLabel => '名前';

  @override
  String get profileNameHint => '名前を追加';

  @override
  String get profileNamePlaceholder => 'あなたの名前';

  @override
  String get profileEditName => '名前を編集';

  @override
  String get profileNameSaved => '名前を保存しました。';

  @override
  String get profileNameTooLong => '名前が少し長いようです。40文字以内でお試しください。';

  @override
  String get profileNameInvalid => 'この名前には使用できない文字が含まれています。文字のみでお試しください。';

  @override
  String get profileAvatarLabel => 'アバター';

  @override
  String get profileEditAvatar => 'アバターを編集';

  @override
  String get profileAvatarSaved => 'アバターを更新しました。';

  @override
  String get profileAvatarSaveFailed => '保存できませんでした。もう一度お試しください。';

  @override
  String get avatarEditorTitle => 'アバター';

  @override
  String get avatarEditorBackground => '背景';

  @override
  String get avatarEditorBackdrop => '背景の飾り';

  @override
  String get avatarEditorShape => '形';

  @override
  String get avatarEditorEyes => '目';

  @override
  String get avatarEditorMouth => '口';

  @override
  String get avatarEditorRandom => 'シャッフル';

  @override
  String get avatarEditorPreview => 'プレビュー';

  @override
  String get avatarEditorSave => '保存';

  @override
  String avatarEditorOptionLabel(String part, int number) {
    return '$part の選択肢 $number';
  }

  @override
  String avatarEditorPartSelected(String part, String value) {
    return '$part: $value';
  }

  @override
  String get avatarEditorTabHead => '髪型';

  @override
  String get avatarEditorTabFace => '顔';

  @override
  String get avatarEditorTabGlasses => 'メガネ';

  @override
  String get avatarEditorTabItem => 'アイテム';

  @override
  String get avatarEditorTabColors => 'カラー';

  @override
  String get avatarEditorBeard => 'ヒゲ';

  @override
  String get avatarEditorColorOutline => '輪郭';

  @override
  String get avatarEditorColorHair => '髪色';

  @override
  String get avatarEditorColorSkin => '肌の色';

  @override
  String get avatarEditorColorOutfit => '服装';

  @override
  String get avatarEditorNone => 'なし';

  @override
  String get avatarEditorItemsComingSoon => 'アイテムは近日追加予定';

  @override
  String get avatarEditorDiscardTitle => '変更を破棄しますか？';

  @override
  String get avatarEditorDiscardMessage => '保存されていない変更があります。破棄してもよろしいですか？';

  @override
  String get avatarEditorDiscardConfirm => '破棄';

  @override
  String get avatarEditorKeepEditing => '編集を続ける';

  @override
  String get settingsCreditsTitle => 'クレジット';

  @override
  String get settingsCreditsAvatar =>
      'Avatar art: Open Peeps by Pablo Stanley (CC0 1.0), via DiceBear';

  @override
  String get settingsMonthStartsOn => '月の開始日';

  @override
  String get settingsMonthStartsOnDescription => '家計簿の集計サイクルを給料日に合わせる';

  @override
  String get monthStartsOnTitle => '月の開始日';

  @override
  String get monthStartsOnDescription =>
      '家計簿の集計を開始する日を選択してください (1〜28日)。2月にも対応できるよう29〜31日は除外されています。';

  @override
  String monthStartsOnCurrentPeriod(String range) {
    return '現在の期間: $range';
  }

  @override
  String monthStartsOnPreviousPeriod(String range) {
    return '前の期間: $range';
  }

  @override
  String get monthStartsOnTransactionsNotice => '記録された取引は変更されません。';

  @override
  String monthStartsOnDayFormat(int day) {
    return '$day日';
  }

  @override
  String get calendarPayCycle => '給与サイクル';

  @override
  String get calendarThisPeriod => '今期';

  @override
  String get calendarSpentThisPeriod => '今期の支出';

  @override
  String get insightsTitle => '分析';

  @override
  String get insightsTotalIncome => '総収入';

  @override
  String get insightsTotalExpense => '総支出';

  @override
  String get insightsNetSavings => '純収支';

  @override
  String get insightsVsPreviousPeriod => '前期比';

  @override
  String get insightsSpendingByCategory => '支出の内訳';

  @override
  String get insightsIncomeVsExpense => '収支の比較';

  @override
  String get insightsCashFlowTrend => 'キャッシュフロートレンド';

  @override
  String get insightsTopCategories => '支出上位カテゴリ';

  @override
  String get insightsNoDataTitle => '取引データがありません';

  @override
  String get insightsNoDataBody => 'この期間の取引を登録すると、支出分析が表示されます。';

  @override
  String get insightsPreviousPeriod => '前の期間';

  @override
  String get insightsNextPeriod => '次の期間';

  @override
  String get transactionsTitle => '取引一覧';

  @override
  String get transactionsSearchHint => 'メモやカテゴリーで検索...';

  @override
  String get filterTitle => 'フィルター';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterIncome => '収入';

  @override
  String get filterExpense => '支出';

  @override
  String get filterCategory => 'カテゴリー';

  @override
  String get filterDateRange => '期間';

  @override
  String get filterStartDate => '開始日';

  @override
  String get filterEndDate => '終了日';

  @override
  String get filterAmount => '金額';

  @override
  String get filterMinAmount => '最小金額';

  @override
  String get filterMaxAmount => '最大金額';

  @override
  String get filterClearAll => 'すべてクリア';

  @override
  String get filterApply => '適用';

  @override
  String get transactionsNoResultsTitle => '取引が見つかりません';

  @override
  String get transactionsNoResultsBody => '検索キーワードやフィルターを変更してみてください。';

  @override
  String get welcomeTitle => 'Ledgerlyへようこそ';

  @override
  String get welcomeSubtitle => '簡単でスマートなお金の管理';

  @override
  String get welcomeMonthStartQuestion => '月の開始日はいつですか？';

  @override
  String get welcomeMonthStartHelp => '給与日や収入のサイクルに合わせて設定できます。後からいつでも変更可能です。';

  @override
  String get welcomeGetStarted => '使ってみる';

  @override
  String welcomeDayChipLabel(int day) {
    return '$day日';
  }

  @override
  String get welcomeSkip => '今はスキップ';

  @override
  String get continueAsGuest => 'ゲストとして続ける';

  @override
  String get signInWithGoogle => 'Googleでログイン';

  @override
  String get signInOrDivider => 'または';

  @override
  String get signInWithApple => 'Appleでサインイン';

  @override
  String get signInWithEmail => 'メールアドレスでログイン';

  @override
  String get signInTitle => 'ログイン';

  @override
  String get signUpTitle => 'アカウント作成';

  @override
  String get emailLabel => 'メールアドレス';

  @override
  String get passwordLabel => 'パスワード';

  @override
  String get displayNameLabel => 'お名前';

  @override
  String get forgotPassword => 'パスワードをお忘れですか？';

  @override
  String get noAccountPrompt => 'アカウントをお持ちでないですか？ 登録';

  @override
  String get haveAccountPrompt => 'すでにアカウントをお持ちですか？ ログイン';

  @override
  String get accountTitle => 'アカウント';

  @override
  String get accountGuestBadge => 'ゲストアカウント';

  @override
  String get accountLinkedBadge => '連携済みアカウント';

  @override
  String get accountLinkBannerTitle => 'データを安全に保護';

  @override
  String get accountLinkBannerBody => 'アカウントを連携すると、機種変更時でもデータを引き継げます。';

  @override
  String get accountLinkGoogle => 'Googleアカウントを連携';

  @override
  String get accountLinkApple => 'Appleで連携';

  @override
  String get accountSignOut => 'ログアウト';

  @override
  String get accountSignOutConfirm => 'ログアウトしてもよろしいですか？';

  @override
  String get accountDeleteTitle => 'アカウント削除';

  @override
  String get accountDeleteBody => 'アカウントとすべての関連データが完全に削除されます。この操作は取り消せません。';

  @override
  String get accountDeleteConfirm => '完全に削除';

  @override
  String get accountDeletedSuccess => '口座を削除しました';

  @override
  String get authErrorInvalidCredentials => 'メールアドレスまたはパスワードが正しくありません';

  @override
  String get authErrorEmailAlreadyInUse => 'このメールアドレスは既に使用されています';

  @override
  String get authErrorSignInFailed => 'ログインに失敗しました。もう一度お試しください。';

  @override
  String get settingsDataTransfer => 'データとバックアップ';

  @override
  String get settingsDataTransferSubtitle => 'データのエクスポート・インポート・バックアップ';

  @override
  String get dataTransferTitle => 'データ管理';

  @override
  String get dataTransferTabExport => 'エクスポート';

  @override
  String get dataTransferTabImport => 'インポート';

  @override
  String get dataTransferTabBackup => 'バックアップ';

  @override
  String get dataTransferPaste => '貼り付け';

  @override
  String get exportFormatLabel => '形式';

  @override
  String get exportRangeLabel => '期間';

  @override
  String get exportPresetThisPeriod => '今期';

  @override
  String get exportPresetLastPeriod => '前期';

  @override
  String get exportPresetAllTime => 'すべて';

  @override
  String get exportPresetCustom => 'カスタム';

  @override
  String get exportSummaryTitle => 'エクスポート概要';

  @override
  String get exportActionExport => 'エクスポートしてコピー';

  @override
  String get exportSuccessCopied => 'データをクリップボードにコピーしました';

  @override
  String get exportTotalRecords => '取引件数';

  @override
  String get exportTotalIncome => '収入合計';

  @override
  String get exportTotalExpense => '支出合計';

  @override
  String get importSourceLabel => 'CSV / JSON データ元';

  @override
  String get importPasteHint => 'CSVまたはJSON取引データをここに貼り付けてください...';

  @override
  String get importActionParse => 'データを解析';

  @override
  String get importPreviewTitle => 'インポートプレビュー';

  @override
  String get importTotalRows => '全行数';

  @override
  String get importValidRows => '有効な取引';

  @override
  String get importDuplicateRows => '重複件数';

  @override
  String get importNewCategories => '新規カテゴリー';

  @override
  String get importSkipDuplicates => '重複レコードをスキップ';

  @override
  String get importAutoCreateCategories => '新規カテゴリーを自動作成';

  @override
  String get importActionExecute => '取引をインポート';

  @override
  String get importSuccess => '取引が正常にインポートされました';

  @override
  String get backupTitle => 'アプリの完全バックアップ';

  @override
  String get backupDescription => '設定、カテゴリー、取引履歴を含むオフラインJSONアーカイブを作成します。';

  @override
  String get backupActionCreate => '完全バックアップを作成';

  @override
  String get backupCreatedSuccess => 'バックアップを作成しコピーしました';

  @override
  String get restoreTitle => 'バックアップから復元';

  @override
  String backupMetadataSummary(int categories, int transactions) {
    return 'バックアップ内容：カテゴリ$categories件、取引$transactions件';
  }

  @override
  String get restorePasteHint => 'LedgerlyバックアップJSONをここに貼り付けてください...';

  @override
  String get restoreActionParse => 'バックアップを読み込み';

  @override
  String get restoreActionExecute => 'データを復元';

  @override
  String get restoreModeMerge => '既存のデータに統合';

  @override
  String get restoreModeOverwrite => 'すべてのデータを置き換え';

  @override
  String get restoreOverwriteWarning => '注意：置き換えると、既存のカテゴリーと取引データはすべて削除されます。';

  @override
  String get restoreSuccess => 'バックアップが正常に復元されました';

  @override
  String get accountsTitle => '口座・ウォレット';

  @override
  String get accountsSubtitle => '銀行口座やウォレットの管理・純資産確認';

  @override
  String get accountsNetWorth => '純資産合計';

  @override
  String get accountsActiveTab => '有効';

  @override
  String get accountsArchivedTab => 'アーカイブ済み';

  @override
  String get accountsEmptyTitle => '口座がありません';

  @override
  String get accountsEmptyBody => '現金、銀行口座、電子マネーを追加して、残高や振替を管理しましょう。';

  @override
  String get accountsAddButton => '口座を追加';

  @override
  String get accountsEditTitle => '口座を編集';

  @override
  String get accountsNewTitle => '新規口座';

  @override
  String get accountsTransferButton => '振替';

  @override
  String get accountsTransferTitle => '口座間振替';

  @override
  String get accountsTransferFrom => '振替元口座';

  @override
  String get accountsTransferTo => '振替先口座';

  @override
  String get accountsTransferAmount => '振替金額';

  @override
  String get accountsTransferDate => '日付';

  @override
  String get accountsTransferNote => 'メモ（任意）';

  @override
  String get accountsTransferSubmit => '振替を実行';

  @override
  String get accountsTransferSuccess => '振替が完了しました';

  @override
  String get accountFieldName => '口座名';

  @override
  String get accountNameHint => '例：KBZ Bank、Wallet、Cash';

  @override
  String get accountFieldType => '口座タイプ';

  @override
  String get accountFieldCurrency => '通貨';

  @override
  String get accountFieldOpeningBalance => '開始残高';

  @override
  String get accountFieldIcon => 'アイコン';

  @override
  String get accountFieldColor => 'カラー';

  @override
  String get accountFieldIncludeInTotal => '純資産に含める';

  @override
  String get accountTypeCash => '現金';

  @override
  String get accountTypeBank => '銀行口座';

  @override
  String get accountTypeCredit => 'クレジットカード';

  @override
  String get accountTypeSavings => '貯蓄';

  @override
  String get accountTypeEwallet => '電子マネー';

  @override
  String get accountSavedSuccess => '口座を保存しました';

  @override
  String get accountArchiveSuccess => '口座をアーカイブしました';

  @override
  String get accountUnarchiveSuccess => '口座のアーカイブを解除しました';

  @override
  String get accountConfirmDelete => '口座を削除しますか？';

  @override
  String get accountConfirmDeleteMessage =>
      'この口座を削除してもよろしいですか？関連する取引履歴は保持されます。';

  @override
  String get accountsNameRequired => '口座名は必須です';

  @override
  String get accountsNameTooLong => '口座名は60文字以内で入力してください';

  @override
  String get accountsNameTaken => 'この名前の口座は既に存在します';

  @override
  String get accountsTransferSameAccount => '振替元と振替先は異なる口座を指定してください';

  @override
  String get accountsTransferAmountInvalid => '振替金額は0より大きい必要があります';

  @override
  String get budgetsTitle => '予算管理';

  @override
  String get budgetsTotal => '全体予算';

  @override
  String get budgetsCategory => 'カテゴリー別予算';

  @override
  String get budgetsNew => '予算を追加';

  @override
  String get budgetsEdit => '予算を編集';

  @override
  String get budgetsDelete => '予算を削除';

  @override
  String get budgetsEmptyTitle => '予算が設定されていません';

  @override
  String get budgetsEmptyBody => '支出を管理するために、カテゴリー別や月全体の支出限度額を設定しましょう。';

  @override
  String get budgetFieldCategory => 'カテゴリー';

  @override
  String get budgetFieldAmount => '予算限度額';

  @override
  String get budgetFieldPeriod => '期間';

  @override
  String get budgetFieldThreshold => '警告アラートのしきい値';

  @override
  String budgetThresholdHint(int percent) {
    return '予算の $percent% に達したら警告アラートを通知します。';
  }

  @override
  String budgetThresholdLive(int percent) {
    return '警告アラートは $percent% で作動します';
  }

  @override
  String get budgetTotalOption => '全体（すべての支出）';

  @override
  String get budgetSpent => '支出額';

  @override
  String get budgetRemaining => '残額';

  @override
  String get budgetDailyRemaining => '1日あたりの使用可能額';

  @override
  String get budgetStatusSafe => '順調';

  @override
  String get budgetStatusWarning => '限度額目前';

  @override
  String get budgetStatusExceeded => '予算超過';

  @override
  String get budgetSavedSuccess => '予算を保存しました';

  @override
  String get budgetDeletedSuccess => '予算を削除しました';

  @override
  String get budgetArchiveSuccess => '予算をアーカイブしました';

  @override
  String get budgetUnarchiveSuccess => '予算のアーカイブを解除しました';

  @override
  String get budgetConfirmDelete => '予算を削除しますか？';

  @override
  String get budgetConfirmDeleteMessage => 'この予算を削除してもよろしいですか？';

  @override
  String get budgetAmountInvalid => '予算額は0より大きい必要があります';

  @override
  String get budgetThresholdInvalid => 'しきい値は10%から100%の間で指定してください';

  @override
  String get budgetDuplicateCategory => 'このカテゴリーには既にこの期間の予算が存在します';

  @override
  String get budgetDuplicateTotal => 'この期間の全体予算は既に存在します';

  @override
  String get budgetOverallSummary => '今月の全体予算';

  @override
  String get recurringTitle => '定期取引';

  @override
  String get recurringSubtitle => 'サブスクリプション、定期請求、定期収入';

  @override
  String get recurringNew => '定期取引を追加';

  @override
  String recurringActiveTab(int count) {
    return '有効 ($count)';
  }

  @override
  String recurringPausedTab(int count) {
    return '一時停止中 ($count)';
  }

  @override
  String get recurringEdit => '定期取引を編集';

  @override
  String get recurringEmptyTitle => '定期取引がありません';

  @override
  String get recurringEmptyBody => '給与、家賃、公共料金などの定期取引を追加して自動で記録しましょう。';

  @override
  String get recurringProcessNow => '期限到来分を処理';

  @override
  String get recurringFrequencyDaily => '毎日';

  @override
  String get recurringFrequencyWeekly => '毎週';

  @override
  String get recurringFrequencyMonthly => '毎月';

  @override
  String get recurringFrequencyYearly => '毎年';

  @override
  String get recurringFieldFrequency => '頻度';

  @override
  String get recurringFieldAccountOptional => '口座（任意）';

  @override
  String get recurringAccountNone => '口座を指定しない';

  @override
  String get recurringFieldStartDate => '開始日';

  @override
  String get recurringFieldEndDate => '終了日';

  @override
  String get recurringFieldHasEndDate => '終了日を設定する';

  @override
  String get recurringFieldAutoAdd => '期日に自動で取引を作成する';

  @override
  String get recurringFieldAutoAddDesc => '有効にすると、期日以降にアプリを開いた際に自動で取引が記録されます。';

  @override
  String get recurringDueToday => '今日が期日';

  @override
  String get recurringDueTomorrow => '明日が期日';

  @override
  String recurringNextDue(String date) {
    return '次回: $date';
  }

  @override
  String get recurringActionSkip => '今回をスキップ';

  @override
  String get recurringActionPause => '一時停止';

  @override
  String get recurringActionResume => '再開';

  @override
  String get recurringActionDelete => '削除';

  @override
  String get recurringSkippedSuccess => '次回の取引をスキップしました';

  @override
  String get recurringSavedSuccess => '定期取引を保存しました';

  @override
  String get recurringDeletedSuccess => '定期取引を削除しました';

  @override
  String recurringProcessedSuccess(int count) {
    return '$count件の定期取引を処理しました';
  }

  @override
  String get recurringConfirmDelete => '定期取引ルールを削除しますか？';

  @override
  String get recurringConfirmDeleteMessage => '過去に作成された取引は削除されません。';

  @override
  String get recurringErrorAmountPositive => '金額は0より大きい必要があります';

  @override
  String get recurringErrorCategoryRequired => 'カテゴリーを選択してください';

  @override
  String get recurringErrorEndDateBeforeStart => '終了日は開始日より前の日付にできません';

  @override
  String get recurringPendingBannerTitle => '保留中の定期取引';

  @override
  String get recurringPendingActionConfirm => '今すぐ追加';

  @override
  String get savingsGoalsTitle => '貯金目標';

  @override
  String get savingsGoalsActiveTab => '進行中';

  @override
  String get savingsGoalsCompletedTab => '達成済み';

  @override
  String get savingsGoalsArchivedTab => 'アーカイブ';

  @override
  String get newGoal => '目標を追加';

  @override
  String get editGoal => '目標を編集';

  @override
  String get goalNameLabel => '目標名';

  @override
  String get goalTargetAmountLabel => '目標金額';

  @override
  String get goalCurrentAmountLabel => '現在の貯蓄額';

  @override
  String get goalTargetDateLabel => '目標日（任意）';

  @override
  String get goalAccountLabel => '連携口座（任意）';

  @override
  String get goalNoAccountOption => 'なし（一般貯蓄）';

  @override
  String get goalNoDate => '未設定';

  @override
  String get goalNotesLabel => 'メモ（任意）';

  @override
  String get goalIconLabel => 'アイコン';

  @override
  String get goalColorLabel => 'カラー';

  @override
  String get saveGoal => '目標を保存';

  @override
  String get deleteGoal => '目標を削除';

  @override
  String get deleteGoalConfirm => 'この貯金目標を削除してもよろしいですか？この操作は取り消せません。';

  @override
  String get archiveGoal => 'アーカイブ';

  @override
  String get unarchiveGoal => 'アーカイブ解除';

  @override
  String get depositTitle => '貯金を入金';

  @override
  String get withdrawTitle => '貯金を引き出し';

  @override
  String get depositAction => '入金';

  @override
  String get withdrawAction => '引き出し';

  @override
  String get goalAmountLabel => '金額';

  @override
  String goalRemaining(String amount) {
    return 'あと $amount';
  }

  @override
  String goalDaysLeft(int days) {
    return '残り $days 日';
  }

  @override
  String goalDaysOverdue(int days) {
    return '$days 日経過';
  }

  @override
  String get goalCompleted => '目標達成！ 🎉';

  @override
  String get goalCompletedSub => 'おめでとうございます！貯金目標を達成しました。';

  @override
  String get emptyGoalsTitle => '貯金目標がありません';

  @override
  String get emptyGoalsMessage => '旅行や緊急資金、大きな買い物のための目標を設定しましょう。';

  @override
  String get emptyCompletedGoals => '達成済みの目標はまだありません。貯金を続けましょう！';

  @override
  String get emptyArchivedGoals => 'アーカイブされた目標はありません。';

  @override
  String get goalNameRequired => '目標名を入力してください';

  @override
  String get goalNameTooLong => '目標名は100文字以内で入力してください';

  @override
  String get goalTargetAmountInvalid => '目標金額は0より大きい必要があります';

  @override
  String get goalCurrentAmountInvalid => '貯蓄額は負の値にできません';

  @override
  String get goalContributionAmountInvalid => '入金額は0より大きい必要があります';

  @override
  String get goalWithdrawAmountInvalid => '引き出し額は0より大きい必要があります';

  @override
  String get goalWithdrawExceedsBalance => '引き出し額が現在の貯蓄残高を超えています';

  @override
  String get goalNotesTooLong => 'メモは500文字以内で入力してください';

  @override
  String get goalSavedSuccess => '貯金目標を保存しました';

  @override
  String get goalDeletedSuccess => '貯金目標を削除しました';

  @override
  String get goalContributedSuccess => '貯金を入金しました';

  @override
  String get goalWithdrawnSuccess => '貯金を引き出しました';

  @override
  String get settingsSavingsGoals => '貯金目標';

  @override
  String get settingsSavingsGoalsSubtitle => '目標金額、緊急資金、進捗状況を管理';
}
