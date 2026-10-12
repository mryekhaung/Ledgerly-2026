/// Injectable source of "now" for the data layer.
///
/// Every timestamp the DAOs write goes through this, so tests can pin time
/// instead of asserting on `DateTime.now()` — a test that reads the real clock
/// flakes at midnight and cannot assert an exact `updatedAt`.
///
/// Deliberately not `package:clock`: that package is not a declared dependency and
/// the project rule is to add a dependency only in the PR that first needs it
/// (`docs/Versions.md` §3). Two lines of our own beats a transitive dep here.
class Clock {
  const Clock();

  /// Current UTC time in epoch milliseconds — the storage format for every
  /// instant column (`docs/DataModel.md` §1).
  int nowUtcMillis() => DateTime.now().toUtc().millisecondsSinceEpoch;
}

/// A [Clock] frozen at a fixed instant.
///
/// Time only moves when [advance] is called, so a test can assert the exact
/// millisecond a write recorded and can prove `updatedAt` is bumped by a second
/// write.
class FixedClock implements Clock {
  FixedClock(this._millis);

  int _millis;

  /// Moves the clock forward, e.g. `clock.advance(const Duration(minutes: 1))`.
  void advance(Duration by) => _millis += by.inMilliseconds;

  @override
  int nowUtcMillis() => _millis;
}
