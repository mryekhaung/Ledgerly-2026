import 'package:material_ui/material_ui.dart';

/// The app's icon vocabulary (docs/Design.md §5).
///
/// WHY THIS EXISTS
/// ---------------
/// Icons were previously picked ad hoc at each call site, so the same concept
/// drifted into two or three different glyphs:
///
///     delete   Icons.delete / Icons.delete_outline / Icons.delete_forever_rounded
///     edit     Icons.edit / Icons.edit_outlined
///     calendar Icons.calendar_today / _outlined / _rounded
///     close    Icons.close / Icons.close_rounded
///     person   Icons.person_outline / Icons.person_outline_rounded
///
/// None of those is *wrong* on its own; together they read as a sketch rather
/// than a system. This registry names each icon by the **role it plays**, so a
/// call site asks for `AppIcons.destructive` instead of choosing a glyph, and a
/// single change here re-skins the whole app.
///
/// CONVENTIONS
/// -----------
/// * **Outline is the default weight.** `Icons.x_outlined` reads lighter and
///   pairs correctly with the filled variant used for a nav destination's
///   selected state. There is no second "rounded" family — mixing Material
///   symbol families is the specific drift this file exists to stop.
/// * **Roles, not nouns, where the meaning is contextual.** [destructive] is
///   used for the delete action in menus and cards alike; if a future screen
///   needs a distinct trash glyph it gets a new *role*, not a new variant.
/// * **Domain glyphs live in their own catalogues** — [CategoryIcons] and
///   [AccountIcons] — because those are user-visible, DB-backed choices stored
///   as stable string keys (`docs/DataModel.md`). This file is for *chrome*.
///
/// A call site that genuinely needs a one-off glyph (a provider's brand mark,
/// a bespoke empty-state illustration) may still use `Icons.` directly; the
/// design-rules test's Rule 8 keeps a small, named exemption list for those
/// rather than allowing the drift to resume silently.
abstract final class AppIcons {
  const AppIcons._();

  // --- Actions ---------------------------------------------------------

  /// Create something new. Toolbars and FABs.
  static const IconData add = Icons.add_outlined;

  /// Edit an existing record.
  static const IconData edit = Icons.edit_outlined;

  /// Delete, remove, or discard. Requires confirmation (docs/Design.md §5.7).
  static const IconData destructive = Icons.delete_outline;

  /// Close, dismiss, or clear a field.
  static const IconData close = Icons.close_outlined;

  /// Confirm or select.
  static const IconData check = Icons.check_outlined;

  /// Search.
  static const IconData search = Icons.search_outlined;

  /// A filter or display-options control.
  static const IconData tune = Icons.tune_outlined;

  /// Open a row's overflow menu.
  static const IconData more = Icons.more_vert_outlined;

  /// Open a row's overflow menu where the row is a wide card and the vertical
  /// dots would crowd the trailing amount.
  static const IconData moreHorizontal = Icons.more_horiz_outlined;

  /// A dropdown affordance.
  static const IconData dropdown = Icons.arrow_drop_down_outlined;

  /// Create something inline, inside a card rather than a toolbar.
  static const IconData addCircle = Icons.add_circle_outline;

  /// Delete one character from a keypad.
  static const IconData backspace = Icons.backspace_outlined;

  // --- Navigation ------------------------------------------------------

  /// Drill into a row. Directional; never mirror without an RTL decision.
  static const IconData chevronRight = Icons.chevron_right_outlined;

  /// Previous / next.
  static const IconData chevronLeft = Icons.chevron_left_outlined;

  /// The tighter chevron used inside a compact trailing slot.
  static const IconData chevronForward = Icons.arrow_forward_ios_outlined;

  /// A date or period. The calendar destination uses this.
  static const IconData calendar = Icons.calendar_today_outlined;

  /// The calendar destination's selected state.
  static const IconData calendarSelected = Icons.calendar_today;

  /// A recurring schedule.
  static const IconData recurring = Icons.event_repeat_outlined;

  /// One occurrence of a schedule.
  static const IconData event = Icons.event_outlined;

  /// The home / overview destination.
  static const IconData home = Icons.grid_view_outlined;

  /// The home destination's selected state.
  static const IconData homeSelected = Icons.grid_view_rounded;

  /// General settings.
  static const IconData settings = Icons.settings_outlined;

  /// Settings, selected.
  static const IconData settingsSelected = Icons.settings;

  /// Sort or reorder.
  static const IconData sort = Icons.swap_vert_outlined;

  /// A pending or background process.
  static const IconData pending = Icons.update_outlined;

  /// Pause a recurring rule or a goal contribution.
  static const IconData pauseCircle = Icons.pause_circle_outline;

  /// Reminders and notifications.
  static const IconData notification = Icons.notifications_outlined;

  /// An empty inbox.
  static const IconData inbox = Icons.inbox_outlined;

  /// A blocked or unavailable state.
  static const IconData blocked = Icons.block;

  /// A sparkle / AI-assisted action.
  static const IconData sparkle = Icons.auto_awesome;

  /// Shuffle or regenerate.
  static const IconData shuffle = Icons.shuffle;

  /// An identity badge or membership.
  static const IconData badge = Icons.badge_outlined;

  // --- Players ---------------------------------------------------------

  /// Start playback.
  static const IconData play = Icons.play_arrow_outlined;

  /// Pause playback.
  static const IconData pause = Icons.pause_outlined;

  /// Skip to the next item.
  static const IconData skipNext = Icons.skip_next_outlined;

  // --- Money / domain chrome -------------------------------------------

  /// The account / wallet destination.
  static const IconData wallet = Icons.account_balance_wallet_outlined;

  /// A monetary value or balance.
  static const IconData money = Icons.attach_money_outlined;

  /// Spending over time — insights and stats.
  static const IconData insights = Icons.pie_chart_outline;

  /// Insights, selected.
  static const IconData insightsSelected = Icons.pie_chart;

  /// Categories.
  static const IconData category = Icons.category_outlined;

  /// Savings goals.
  static const IconData goal = Icons.savings_outlined;

  /// A budget.
  static const IconData budget = Icons.account_balance_outlined;

  /// Move money between accounts.
  static const IconData transfer = Icons.swap_horiz_outlined;

  /// Import, export, or paste.
  static const IconData paste = Icons.paste_outlined;

  /// Archive / unarchive.
  static const IconData archive = Icons.archive_outlined;

  /// Unarchive.
  static const IconData unarchive = Icons.unarchive_outlined;

  // --- Feedback / status -----------------------------------------------

  /// An error or problem needing attention.
  static const IconData error = Icons.error_outline;

  /// A warning.
  static const IconData warning = Icons.warning_amber_rounded;

  /// Supplementary information.
  static const IconData info = Icons.info_outline;

  /// Success confirmation.
  static const IconData success = Icons.check_circle_outline;

  /// Sync in progress or available.
  static const IconData sync = Icons.sync_outlined;

  /// A two-way sync relationship.
  static const IconData syncAlt = Icons.sync_alt;

  /// Cloud sync state.
  static const IconData cloudSync = Icons.cloud_sync_outlined;

  /// Empty search results.
  static const IconData searchOff = Icons.search_off_outlined;

  // --- Account ---------------------------------------------------------

  /// The user's identity.
  static const IconData person = Icons.person_outline;

  /// Manage the signed-in account.
  static const IconData manageAccount = Icons.manage_accounts_outlined;

  /// Sign in or out.
  static const IconData signOut = Icons.logout_rounded;

  /// Email.
  static const IconData email = Icons.email_outlined;

  /// A passkey or credential.
  static const IconData credential = Icons.key_outlined;

  /// A locked or secure field.
  static const IconData lock = Icons.lock_outline;

  /// Reveal a hidden value.
  static const IconData reveal = Icons.visibility_outlined;

  /// Conceal a value.
  static const IconData conceal = Icons.visibility_off_outlined;

  // --- Trends ----------------------------------------------------------

  /// An upward trend. **Not a money sign** — see [AmountText] for those.
  static const IconData trendUp = Icons.trending_up_outlined;

  /// An increase.
  static const IconData increase = Icons.arrow_upward_outlined;

  /// A decrease.
  static const IconData decrease = Icons.arrow_downward_outlined;
}
