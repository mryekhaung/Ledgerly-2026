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
  String get welcomeSkip => '今はスキップ';

  @override
  String get continueAsGuest => 'ゲストとして続ける';

  @override
  String get signInWithGoogle => 'Googleでログイン';

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
  String get accountDeletedSuccess => 'アカウントが削除されました';

  @override
  String get authErrorInvalidCredentials => 'メールアドレスまたはパスワードが正しくありません';

  @override
  String get authErrorEmailAlreadyInUse => 'このメールアドレスは既に使用されています';

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
}
